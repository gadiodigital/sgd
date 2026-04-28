from __future__ import annotations

import json
from pathlib import Path
from time import perf_counter

from app.config import OcrSettings
from app.document_loader import load_pages
from app.engines import resolve_engine, run_ocr_engine
from app.job_store import JobStore, OcrJob, utc_now
from app.pdf_exporter import export_searchable_pdf
from app.preprocessing import preprocess_image


class JobCancelled(RuntimeError):
    pass


def process_job(job: OcrJob, store: JobStore, settings: OcrSettings) -> None:
    started = perf_counter()
    if _is_cancelled(job, store):
        _write_pipeline_metrics(job, store, started)
        return

    store.update(
        job,
        status="running",
        started_at_utc=utc_now(),
        message="Procesando OCR.",
        progress={
            "stage": "starting",
            "processedPages": 0,
            "totalPages": None,
            "percent": 0,
        },
    )

    try:
        result = _process_job_core(job, store, settings)
        _raise_if_cancelled(job, store)
        store.update(
            job,
            status="completed",
            completed_at_utc=utc_now(),
            page_count=len(result["pages"]),
            message="OCR completado.",
            artifacts=result["artifacts"],
            source=result["source"],
            progress={
                "stage": "completed",
                "processedPages": len(result["pages"]),
                "totalPages": len(result["pages"]),
                "percent": 100,
            },
        )
    except JobCancelled:
        store.update(
            job,
            status="cancelled",
            completed_at_utc=utc_now(),
            message="Job cancelado.",
            progress={
                **(job.progress or {}),
                "stage": "cancelled",
            },
        )
    except Exception as exc:
        error_artifact = _write_error_artifact(job, store, exc)
        store.update(
            job,
            status="failed",
            completed_at_utc=utc_now(),
            message="OCR fallido.",
            error=str(exc),
            artifacts=[error_artifact],
            source=_build_source_metadata(job.request, Path(job.request.get("sourcePath") or "")),
            progress={
                **(job.progress or {}),
                "stage": "failed",
            },
        )
    finally:
        _write_pipeline_metrics(job, store, started)


def _process_job_core(job: OcrJob, store: JobStore, settings: OcrSettings) -> dict:
    request = job.request
    source_path = Path(request.get("sourcePath") or "")
    source = _build_source_metadata(request, source_path)
    job_dir = store.job_dir(job.job_id)
    input_dir = job_dir / "input"
    pages_dir = job_dir / "pages"
    output_dir = job_dir / "output"
    output_dir.mkdir(parents=True, exist_ok=True)

    timings: dict[str, int] = {}
    engine_selection = resolve_engine(job.engine, settings.default_engine)
    _raise_if_cancelled(job, store)
    loaded_pages = _timed(
        timings,
        "load",
        lambda: load_pages(
            source_path,
            input_dir,
            request.get("pageNumbers"),
            request.get("options", {}).get("targetDpi", 300),
            settings.max_pages,
        ),
    )
    _raise_if_cancelled(job, store)
    store.update(
        job,
        progress={
            "stage": "loaded",
            "processedPages": 0,
            "totalPages": len(loaded_pages),
            "percent": 0,
        },
    )
    languages = _resolve_languages(request.get("languageHints"), settings.default_languages)

    pages: list[dict] = []
    preprocessed_image_paths: list[Path] = []
    for index, loaded_page in enumerate(loaded_pages, start=1):
        _raise_if_cancelled(job, store)
        store.update(
            job,
            message=f"Procesando pagina {index} de {len(loaded_pages)}.",
            progress={
                "stage": "processing",
                "processedPages": index - 1,
                "totalPages": len(loaded_pages),
                "currentPage": loaded_page.page_number,
                "percent": _progress_percent(index - 1, len(loaded_pages)),
            },
        )
        page_dir = pages_dir / f"page-{loaded_page.page_number:03}"
        preprocess = _timed(
            timings,
            "preprocess",
            lambda: preprocess_image(
                loaded_page.image_path,
                page_dir,
                request.get("preprocessMode", "auto"),
            ),
        )
        _raise_if_cancelled(job, store)
        ocr = _timed(
            timings,
            "ocr",
            lambda: run_ocr_engine(
                engine_selection.resolved_engine,
                preprocess.image_path,
                languages,
                settings.tesseract_path,
            ),
        )
        _raise_if_cancelled(job, store)
        preprocessed_image_paths.append(preprocess.image_path)
        pages.append(
            {
                "pageNumber": loaded_page.page_number,
                "width": loaded_page.width,
                "height": loaded_page.height,
                "dpi": loaded_page.dpi,
                "rotationApplied": 0,
                "confidenceAverage": ocr.confidence_average,
                "text": ocr.text,
                "blocks": [
                    {
                        "type": "line",
                        "text": line.text,
                        "confidence": line.confidence,
                        "bbox": line.bbox,
                        "metadata": {
                            "blockNumber": line.block_number,
                            "paragraphNumber": line.paragraph_number,
                            "lineNumber": line.line_number,
                        },
                    }
                    for line in ocr.lines
                ]
                + [
                    {
                        "type": "word",
                        "text": word.text,
                        "confidence": word.confidence,
                        "bbox": word.bbox,
                        "metadata": {
                            "blockNumber": word.block_number,
                            "paragraphNumber": word.paragraph_number,
                            "lineNumber": word.line_number,
                        },
                    }
                    for word in ocr.words
                ],
                "diagnostics": {
                    **preprocess.diagnostics,
                    "originalImagePath": str(loaded_page.image_path),
                    "preprocessedImagePath": str(preprocess.image_path),
                },
            }
        )
        store.update(
            job,
            page_count=index,
            progress={
                "stage": "processing",
                "processedPages": index,
                "totalPages": len(loaded_pages),
                "currentPage": loaded_page.page_number,
                "percent": _progress_percent(index, len(loaded_pages)),
            },
        )

    text = "\n\n".join(page["text"] for page in pages if page["text"])
    confidence_average = _average_confidence(pages)
    warnings = _build_warnings(pages, confidence_average)
    quality = _build_quality(confidence_average, warnings)
    outputs = request.get("outputs") or ["json", "txt"]
    _raise_if_cancelled(job, store)
    artifacts = _timed(
        timings,
        "export",
        lambda: _write_outputs(
            job.job_id,
            output_dir,
            text,
            pages,
            "markdown" in outputs,
            "searchable-pdf" in outputs,
            preprocessed_image_paths,
            languages,
            settings.tesseract_path,
        ),
    )
    result_path = output_dir / "result.json"
    artifacts.append(
        {"artifactId": "result", "type": "application/json", "path": str(result_path)}
    )
    result = {
        "jobId": job.job_id,
        "status": "completed",
        "source": source,
        "language": languages,
        "engine": {
            "requested": engine_selection.requested_engine,
            "resolved": engine_selection.resolved_engine,
        },
        "text": text,
        "confidenceAverage": confidence_average,
        "quality": quality,
        "warnings": warnings,
        "pages": pages,
        "artifacts": artifacts,
        "timingsMs": timings,
    }
    result_path.write_text(
        json.dumps(result, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return result


def _build_source_metadata(request: dict, source_path: Path) -> dict:
    exists = source_path.exists()
    stat = source_path.stat() if exists and source_path.is_file() else None
    return {
        "sourceType": request.get("sourceType"),
        "sourcePath": str(source_path),
        "scanSessionId": request.get("scanSessionId"),
        "mobileDeviceId": request.get("mobileDeviceId"),
        "mobileCaptureId": request.get("mobileCaptureId"),
        "clientCapturedAtUtc": request.get("clientCapturedAtUtc"),
        "exists": exists,
        "isDirectory": source_path.is_dir() if exists else False,
        "extension": source_path.suffix.lower() if source_path.suffix else None,
        "length": stat.st_size if stat else None,
        "requestedPageNumbers": request.get("pageNumbers"),
    }


def _resolve_languages(language_hints: list[str] | None, default_languages: str) -> str:
    languages = [language.strip() for language in language_hints or [] if language.strip()]
    if languages:
        return "+".join(languages)
    return default_languages or "spa+eng"


def _progress_percent(processed_pages: int, total_pages: int) -> int:
    if total_pages <= 0:
        return 0
    return min(99, int((processed_pages / total_pages) * 100))


def _is_cancelled(job: OcrJob, store: JobStore) -> bool:
    try:
        persisted = store.read_job(job.job_id)
    except (KeyError, ValueError):
        return False
    return persisted.status == "cancelled"


def _raise_if_cancelled(job: OcrJob, store: JobStore) -> None:
    if _is_cancelled(job, store):
        raise JobCancelled("Job cancelado.")


def _write_pipeline_metrics(job: OcrJob, store: JobStore, started: float) -> None:
    elapsed_ms = int((perf_counter() - started) * 1000)
    latest_job = store.read_job(job.job_id)
    job_dir = store.job_dir(job.job_id)
    metrics_path = job_dir / "logs" / "pipeline.json"
    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    metrics_path.write_text(
        json.dumps(
            {
                "jobId": latest_job.job_id,
                "status": latest_job.status,
                "elapsedMs": elapsed_ms,
                "pageCount": latest_job.page_count,
                "progress": latest_job.progress,
                "completedAtUtc": latest_job.completed_at_utc,
            },
            indent=2,
        ),
        encoding="utf-8",
    )


def _write_error_artifact(job: OcrJob, store: JobStore, exc: Exception) -> dict:
    output_dir = store.job_dir(job.job_id) / "output"
    output_dir.mkdir(parents=True, exist_ok=True)
    error_path = output_dir / "error.json"
    payload = {
        "jobId": job.job_id,
        "status": "failed",
        "errorType": exc.__class__.__name__,
        "message": str(exc),
        "failedAtUtc": utc_now(),
    }
    error_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return {
        "artifactId": "error",
        "type": "application/json",
        "path": str(error_path),
    }


def _timed(timings: dict[str, int], key: str, action):
    started = perf_counter()
    result = action()
    timings[key] = timings.get(key, 0) + int((perf_counter() - started) * 1000)
    return result


def _average_confidence(pages: list[dict]) -> float:
    confidences = [page["confidenceAverage"] for page in pages]
    if not confidences:
        return 0
    return round(sum(confidences) / len(confidences), 4)


def _build_warnings(pages: list[dict], confidence_average: float) -> list[dict]:
    warnings: list[dict] = []
    if confidence_average < 0.70:
        warnings.append(
            {
                "code": "low-document-confidence",
                "message": "La confianza promedio del documento es baja.",
                "confidenceAverage": confidence_average,
            }
        )

    for page in pages:
        if page["confidenceAverage"] < 0.70:
            warnings.append(
                {
                    "code": "low-page-confidence",
                    "message": "La confianza promedio de la pagina es baja.",
                    "pageNumber": page["pageNumber"],
                    "confidenceAverage": page["confidenceAverage"],
                }
            )
        if not page["text"].strip():
            warnings.append(
                {
                    "code": "empty-page-text",
                    "message": "No se detecto texto en la pagina.",
                    "pageNumber": page["pageNumber"],
                }
            )

    return warnings


def _build_quality(confidence_average: float, warnings: list[dict]) -> dict:
    warning_codes = {warning.get("code") for warning in warnings}
    if confidence_average >= 0.85 and not warning_codes:
        level = "good"
    elif confidence_average >= 0.60 and "empty-page-text" not in warning_codes:
        level = "review"
    else:
        level = "poor"

    return {
        "level": level,
        "confidenceAverage": confidence_average,
        "warningCount": len(warnings),
        "warningCodes": sorted(code for code in warning_codes if code),
    }


def _write_outputs(
    job_id: str,
    output_dir: Path,
    text: str,
    pages: list[dict],
    include_markdown: bool,
    include_searchable_pdf: bool,
    page_image_paths: list[Path],
    languages: str,
    tesseract_path: str | None,
) -> list[dict]:
    txt_path = output_dir / "result.txt"
    txt_path.write_text(text, encoding="utf-8")
    diagnostics_path = output_dir / "pages.json"
    diagnostics_path.write_text(
        json.dumps({"jobId": job_id, "pages": pages}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    artifacts = [
        {"artifactId": "txt", "type": "text/plain", "path": str(txt_path)},
        {
            "artifactId": "pages",
            "type": "application/json",
            "path": str(diagnostics_path),
        },
    ]

    pages_output_dir = output_dir / "pages"
    pages_output_dir.mkdir(parents=True, exist_ok=True)
    for page in pages:
        page_text_path = pages_output_dir / f"page-{page['pageNumber']:03}.txt"
        page_text_path.write_text(page["text"], encoding="utf-8")
        artifacts.append(
            {
                "artifactId": f"page-{page['pageNumber']:03}-txt",
                "type": "text/plain",
                "path": str(page_text_path),
            }
        )

    if include_markdown:
        markdown_path = output_dir / "result.md"
        markdown_path.write_text(_build_markdown(job_id, pages), encoding="utf-8")
        artifacts.append(
            {
                "artifactId": "markdown",
                "type": "text/markdown",
                "path": str(markdown_path),
            }
        )

    if include_searchable_pdf:
        pdf_path = output_dir / "searchable.pdf"
        export_searchable_pdf(page_image_paths, pdf_path, languages, tesseract_path)
        artifacts.append(
            {
                "artifactId": "searchable-pdf",
                "type": "application/pdf",
                "path": str(pdf_path),
            }
        )

    return artifacts


def _build_markdown(job_id: str, pages: list[dict]) -> str:
    lines = [f"# OCR {job_id}", ""]
    for page in pages:
        page_number = page["pageNumber"]
        confidence = page["confidenceAverage"]
        text = page["text"].strip()
        lines.extend(
            [
                f"## Pagina {page_number}",
                "",
                f"- Confianza promedio: {confidence:.2%}",
                "",
                text or "_Sin texto detectado._",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"
