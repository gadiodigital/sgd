from __future__ import annotations

import json
from pathlib import Path
from uuid import uuid4

from fastapi import BackgroundTasks, FastAPI, File, Form, HTTPException, UploadFile
from pydantic import ValidationError
from fastapi.responses import FileResponse, JSONResponse

from app.config import load_settings
from app.contracts import CreateOcrJobRequest
from app.dependencies import get_dependency_status, get_readiness_status
from app.job_store import JobStore, OcrJob
from app.maintenance import cleanup_artifacts, get_storage_status
from app.operations import get_operations
from app.pipeline import process_job
from app.preprocessing import preprocess_image
from app.security import (
    OcrSecurityError,
    validate_output_path,
    validate_source_path,
    validate_upload_extension,
)


settings = load_settings()
store = JobStore(settings.artifacts_root)
app = FastAPI(title=settings.app_name, version=settings.version)


@app.get("/health")
def health() -> dict:
    return {
        "application": settings.app_name,
        "version": settings.version,
        "status": "ok",
    }


@app.get("/ready", response_model=None)
def ready():
    readiness = get_readiness_status(settings)
    if readiness["status"] != "ready":
        return JSONResponse(status_code=503, content=readiness)
    return readiness


@app.get("/api/ocr/status")
def status() -> dict:
    return {
        "application": settings.app_name,
        "version": settings.version,
        "artifactsRoot": str(settings.artifacts_root),
        "defaultEngine": settings.default_engine,
        "retentionHours": settings.retention_hours,
        "allowedSourceRoots": [str(root) for root in settings.allowed_source_roots],
        "dependencies": get_dependency_status(settings),
        "operations": get_operations(),
    }


@app.get("/api/ocr/operations")
def operations() -> list[dict[str, str]]:
    return get_operations()


@app.get("/api/ocr/storage")
def storage_status() -> dict:
    status = get_storage_status(settings.artifacts_root)
    return {
        "artifactsRoot": status.artifacts_root,
        "totalBytes": status.total_bytes,
        "jobCount": status.job_count,
        "uploadCount": status.upload_count,
        "preprocessCount": status.preprocess_count,
    }


@app.post("/api/ocr/maintenance/cleanup")
def cleanup(retention_hours: int | None = None) -> dict:
    hours = retention_hours or settings.retention_hours
    if hours < 1:
        raise HTTPException(status_code=400, detail="retention_hours debe ser positivo.")
    result = cleanup_artifacts(settings.artifacts_root, hours)
    return {
        "deletedCount": result.deleted_count,
        "deletedBytes": result.deleted_bytes,
        "retentionHours": result.retention_hours,
        "cutoffUtc": result.cutoff_utc,
    }


@app.get("/api/ocr/jobs")
def list_jobs(
    status: str | None = None,
    source_type: str | None = None,
    created_from: str | None = None,
    created_to: str | None = None,
    order: str = "desc",
    limit: int = 50,
    offset: int = 0,
) -> dict:
    if limit < 1 or limit > 200:
        raise HTTPException(status_code=400, detail="limit debe estar entre 1 y 200.")
    if offset < 0:
        raise HTTPException(status_code=400, detail="offset no puede ser negativo.")
    if order not in {"asc", "desc"}:
        raise HTTPException(status_code=400, detail="order debe ser asc o desc.")
    if created_from and created_to and created_from > created_to:
        raise HTTPException(status_code=400, detail="created_from no puede ser mayor que created_to.")

    jobs, total = store.list(
        status=status,
        source_type=source_type,
        created_from=created_from,
        created_to=created_to,
        order=order,
        limit=limit,
        offset=offset,
    )
    return {
        "items": [_job_to_response(job) for job in jobs],
        "total": total,
        "limit": limit,
        "offset": offset,
        "filters": {
            "status": status,
            "sourceType": source_type,
            "createdFrom": created_from,
            "createdTo": created_to,
            "order": order,
        },
    }


@app.get("/api/ocr/jobs/{job_id}")
def get_job(job_id: str) -> dict:
    try:
        return _job_to_response(store.read_job(job_id))
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=404, detail="Job OCR no encontrado.") from exc


@app.get("/api/ocr/jobs/{job_id}/retries")
def get_job_retries(job_id: str) -> dict:
    try:
        jobs = store.list_retry_chain(job_id)
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=404, detail="Job OCR no encontrado.") from exc

    root_id = jobs[0].job_id if jobs else job_id
    return {
        "rootJobId": root_id,
        "total": len(jobs),
        "items": [_job_to_response(job) for job in jobs],
    }


@app.delete("/api/ocr/jobs/{job_id}", status_code=204)
def delete_job(job_id: str) -> None:
    try:
        store.delete(job_id)
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=404, detail="Job OCR no encontrado.") from exc


@app.post("/api/ocr/jobs/{job_id}/retry")
def retry_job(job_id: str, background_tasks: BackgroundTasks, wait: bool = False) -> dict:
    try:
        original = store.read_job(job_id)
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=404, detail="Job OCR no encontrado.") from exc

    if original.status not in {"failed", "cancelled"}:
        raise HTTPException(
            status_code=409,
            detail="Solo se pueden reintentar jobs fallidos o cancelados.",
        )

    retry_request = {
        **original.request,
        "parentJobId": original.parent_job_id or original.job_id,
        "retryOfJobId": original.job_id,
    }
    job = store.create(retry_request, original.engine, original.preprocess_mode)
    return _schedule_or_process_job(job, background_tasks, wait)


@app.post("/api/ocr/jobs")
def create_job(
    request: CreateOcrJobRequest,
    background_tasks: BackgroundTasks,
    wait: bool = False,
) -> dict:
    payload = request.model_dump(by_alias=True)
    try:
        payload["sourcePath"] = str(validate_source_path(payload.get("sourcePath"), settings))
    except OcrSecurityError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    job = store.create(payload, request.engine, request.preprocess_mode)
    return _schedule_or_process_job(job, background_tasks, wait)


@app.post("/api/ocr/jobs/upload")
async def create_upload_job(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    language_hints: str = Form(default="", alias="languageHints"),
    outputs: str = Form(default="json,txt"),
    engine: str = Form(default="auto"),
    preprocess_mode: str = Form(default="auto", alias="preprocessMode"),
    wait: bool = Form(default=False),
) -> dict:
    return await _create_file_upload_job(
        background_tasks=background_tasks,
        file=file,
        source_type="upload",
        language_hints=language_hints,
        outputs=outputs,
        engine=engine,
        preprocess_mode=preprocess_mode,
        wait=wait,
    )


@app.post("/api/ocr/jobs/mobile-capture")
async def create_mobile_capture_job(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    language_hints: str = Form(default="", alias="languageHints"),
    outputs: str = Form(default="json,txt"),
    engine: str = Form(default="auto"),
    preprocess_mode: str = Form(default="auto", alias="preprocessMode"),
    wait: bool = Form(default=False),
    mobile_device_id: str | None = Form(default=None, alias="mobileDeviceId"),
    mobile_capture_id: str | None = Form(default=None, alias="mobileCaptureId"),
    client_captured_at_utc: str | None = Form(default=None, alias="clientCapturedAtUtc"),
) -> dict:
    return await _create_file_upload_job(
        background_tasks=background_tasks,
        file=file,
        source_type="mobile-capture",
        language_hints=language_hints,
        outputs=outputs,
        engine=engine,
        preprocess_mode=preprocess_mode,
        wait=wait,
        mobile_device_id=mobile_device_id,
        mobile_capture_id=mobile_capture_id,
        client_captured_at_utc=client_captured_at_utc,
    )


async def _create_file_upload_job(
    background_tasks: BackgroundTasks,
    file: UploadFile,
    source_type: str,
    language_hints: str,
    outputs: str,
    engine: str,
    preprocess_mode: str,
    wait: bool,
    mobile_device_id: str | None = None,
    mobile_capture_id: str | None = None,
    client_captured_at_utc: str | None = None,
) -> dict:
    upload_path = await _save_upload(file)
    try:
        request = CreateOcrJobRequest.model_validate(
            {
                "sourceType": source_type,
                "sourcePath": str(upload_path),
                "languageHints": _split_csv(language_hints) or None,
                "engine": engine,
                "preprocessMode": preprocess_mode,
                "outputs": _split_csv(outputs, ["json", "txt"]),
                "mobileDeviceId": mobile_device_id,
                "mobileCaptureId": mobile_capture_id,
                "clientCapturedAtUtc": client_captured_at_utc,
                "options": {
                    "targetDpi": 300,
                    "detectLayout": False,
                    "detectTables": False,
                    "keepIntermediateArtifacts": True,
                },
            }
        )
    except ValidationError as exc:
        upload_path.unlink(missing_ok=True)
        raise HTTPException(status_code=400, detail=exc.errors()) from exc

    return create_job(request, background_tasks, wait=wait)


@app.post("/api/ocr/jobs/from-scan-session")
def create_from_scan_session(
    request: CreateOcrJobRequest,
    background_tasks: BackgroundTasks,
    wait: bool = False,
) -> dict:
    return create_job(request, background_tasks, wait=wait)


@app.post("/api/ocr/preprocess")
async def preprocess_upload(
    file: UploadFile = File(...),
    preprocess_mode: str = Form(default="auto", alias="preprocessMode"),
) -> dict:
    upload_path = await _save_upload(file)
    preprocess_id = f"preprocess_{uuid4().hex}"
    output_dir = settings.artifacts_root / "preprocess" / preprocess_id
    try:
        result = preprocess_image(upload_path, output_dir, preprocess_mode)
    except Exception as exc:
        upload_path.unlink(missing_ok=True)
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return {
        "result": "ok",
        "preprocessId": preprocess_id,
        "imagePath": str(result.image_path),
        "imageUrl": f"/api/ocr/preprocess/{preprocess_id}/image",
        "contentType": _image_media_type(result.image_path),
        "diagnostics": result.diagnostics,
    }


@app.get("/api/ocr/preprocess/{preprocess_id}/image")
def get_preprocess_image(preprocess_id: str) -> FileResponse:
    if not preprocess_id.startswith("preprocess_") or any(
        part in preprocess_id for part in ("..", "/", "\\")
    ):
        raise HTTPException(status_code=404, detail="Preprocesamiento no encontrado.")

    preprocess_dir = settings.artifacts_root / "preprocess" / preprocess_id
    image_path = next(preprocess_dir.glob("*.preprocessed.*"), None)
    if image_path is None or not image_path.exists():
        raise HTTPException(status_code=404, detail="Imagen preprocesada no encontrada.")
    try:
        image_path = validate_output_path(image_path, preprocess_dir, "Imagen preprocesada")
    except OcrSecurityError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    return FileResponse(path=image_path, media_type=_image_media_type(image_path))


@app.post("/api/ocr/jobs/{job_id}/cancel")
def cancel_job(job_id: str) -> dict:
    try:
        job = store.read_job(job_id)
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=404, detail="Job OCR no encontrado.") from exc

    if job.status in {"completed", "failed", "cancelled"}:
        return _job_to_response(job)

    store.update(
        job,
        status="cancelled",
        message="Job cancelado.",
        progress={
            **(job.progress or {}),
            "stage": "cancelled",
        },
    )
    return _job_to_response(job)


@app.get("/api/ocr/jobs/{job_id}/result")
def get_result(job_id: str) -> dict:
    return _read_result(job_id)


@app.get("/api/ocr/jobs/{job_id}/summary")
def get_result_summary(job_id: str, text_limit: int = 500) -> dict:
    if text_limit < 0 or text_limit > 5000:
        raise HTTPException(status_code=400, detail="text_limit debe estar entre 0 y 5000.")
    return _build_result_summary(_read_result(job_id), text_limit)


@app.get("/api/ocr/jobs/{job_id}/quality")
def get_result_quality(job_id: str) -> dict:
    return _build_result_quality(_read_result(job_id))


@app.get("/api/ocr/jobs/{job_id}/text")
def get_job_text(job_id: str) -> FileResponse:
    return get_artifact(job_id, "txt")


@app.get("/api/ocr/jobs/{job_id}/markdown")
def get_job_markdown(job_id: str) -> FileResponse:
    return get_artifact(job_id, "markdown")


@app.get("/api/ocr/jobs/{job_id}/metrics")
def get_job_metrics(job_id: str) -> dict:
    try:
        job = store.read_job(job_id)
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=404, detail="Job OCR no encontrado.") from exc

    metrics_path = store.job_dir(job_id) / "logs" / "pipeline.json"
    if not metrics_path.exists():
        raise HTTPException(status_code=404, detail="Metricas OCR no disponibles.")

    metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
    result_path = store.job_dir(job_id) / "output" / "result.json"
    if result_path.exists():
        result = json.loads(result_path.read_text(encoding="utf-8"))
        metrics["timingsMs"] = result.get("timingsMs", {})

    metrics["status"] = job.status
    metrics["pageCount"] = job.page_count
    return metrics


@app.get("/api/ocr/jobs/{job_id}/error")
def get_job_error(job_id: str) -> dict:
    error_path = store.job_dir(job_id) / "output" / "error.json"
    if not error_path.exists():
        raise HTTPException(status_code=404, detail="Error OCR no disponible.")
    return json.loads(error_path.read_text(encoding="utf-8"))


@app.get("/api/ocr/jobs/{job_id}/pages/{page_number}")
def get_page_result(job_id: str, page_number: int) -> dict:
    return _get_result_page(job_id, page_number)


@app.get("/api/ocr/jobs/{job_id}/pages/{page_number}/text")
def get_page_text(job_id: str, page_number: int) -> FileResponse:
    artifact_id = f"page-{page_number:03}-txt"
    return get_artifact(job_id, artifact_id)


@app.get("/api/ocr/jobs/{job_id}/pages/{page_number}/diagnostics")
def get_page_diagnostics(job_id: str, page_number: int) -> dict:
    page = _get_result_page(job_id, page_number)
    return {
        "jobId": job_id,
        "pageNumber": page_number,
        "diagnostics": page.get("diagnostics", {}),
    }


@app.get("/api/ocr/jobs/{job_id}/pages/{page_number}/preview")
def get_page_preview(job_id: str, page_number: int) -> FileResponse:
    page = _get_result_page(job_id, page_number)
    diagnostics = page.get("diagnostics", {})
    image_path = diagnostics.get("preprocessedImagePath") or diagnostics.get("originalImagePath")
    if not image_path:
        raise HTTPException(status_code=404, detail="Preview OCR no disponible.")

    try:
        path = validate_output_path(image_path, store.job_dir(job_id), "Preview OCR")
    except OcrSecurityError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    if not path.exists():
        raise HTTPException(status_code=404, detail="Archivo de preview no encontrado.")

    return FileResponse(path=path, media_type=_image_media_type(path))


@app.get("/api/ocr/jobs/{job_id}/artifacts/{artifact_id}")
def get_artifact(job_id: str, artifact_id: str) -> FileResponse:
    try:
        job = store.read_job(job_id)
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=404, detail="Job OCR no encontrado.") from exc

    artifact = next(
        (candidate for candidate in job.artifacts if candidate["artifactId"] == artifact_id),
        None,
    )
    if artifact is None:
        raise HTTPException(status_code=404, detail="Artefacto OCR no encontrado.")

    try:
        path = validate_output_path(artifact["path"], store.job_dir(job_id), "Artefacto OCR")
    except OcrSecurityError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    if not path.exists():
        raise HTTPException(status_code=404, detail="Archivo de artefacto no encontrado.")

    return FileResponse(path=path, media_type=artifact["type"])


async def _save_upload(file: UploadFile) -> Path:
    upload_dir = settings.artifacts_root / "uploads"
    upload_dir.mkdir(parents=True, exist_ok=True)
    try:
        suffix = validate_upload_extension(file.filename)
    except OcrSecurityError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    target_path = upload_dir / f"upload_{uuid4().hex}{suffix}"
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="El archivo subido esta vacio.")
    max_bytes = settings.max_file_mb * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(status_code=413, detail="El archivo excede el tamano maximo.")

    target_path.write_bytes(content)
    return target_path


def _split_csv(value: str, fallback: list[str] | None = None) -> list[str]:
    parts = [part.strip() for part in value.split(",")]
    return [part for part in parts if part] or (fallback or [])


def _schedule_or_process_job(
    job: OcrJob,
    background_tasks: BackgroundTasks,
    wait: bool,
) -> dict:
    if wait:
        process_job(job, store, settings)
        return _job_to_response(store.read_job(job.job_id))

    background_tasks.add_task(process_job, job, store, settings)
    return _job_to_response(job)


def _read_result(job_id: str) -> dict:
    path = store.job_dir(job_id) / "output" / "result.json"
    if not path.exists():
        raise HTTPException(status_code=404, detail="Resultado OCR no disponible.")
    return json.loads(path.read_text(encoding="utf-8"))


def _get_result_page(job_id: str, page_number: int) -> dict:
    result = _read_result(job_id)
    page = next(
        (candidate for candidate in result["pages"] if candidate["pageNumber"] == page_number),
        None,
    )
    if page is None:
        raise HTTPException(status_code=404, detail="Pagina OCR no encontrada.")
    return page


def _build_result_summary(result: dict, text_limit: int) -> dict:
    text = result.get("text") or ""
    pages = result.get("pages") or []
    artifacts = result.get("artifacts") or []
    return {
        "jobId": result.get("jobId"),
        "status": result.get("status"),
        "source": result.get("source"),
        "language": result.get("language"),
        "engine": result.get("engine"),
        "pageCount": len(pages),
        "confidenceAverage": result.get("confidenceAverage"),
        "quality": result.get("quality"),
        "warnings": result.get("warnings", []),
        "textPreview": text[:text_limit],
        "textLength": len(text),
        "artifacts": [
            {
                "artifactId": artifact.get("artifactId"),
                "type": artifact.get("type"),
            }
            for artifact in artifacts
        ],
        "pages": [
            {
                "pageNumber": page.get("pageNumber"),
                "confidenceAverage": page.get("confidenceAverage"),
                "textLength": len(page.get("text") or ""),
                "blockCount": len(page.get("blocks") or []),
            }
            for page in pages
        ],
    }


def _build_result_quality(result: dict) -> dict:
    return {
        "jobId": result.get("jobId"),
        "status": result.get("status"),
        "confidenceAverage": result.get("confidenceAverage"),
        "quality": result.get("quality"),
        "warnings": result.get("warnings", []),
    }


def _image_media_type(path: Path) -> str:
    return {
        ".bmp": "image/bmp",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".tif": "image/tiff",
        ".tiff": "image/tiff",
    }.get(path.suffix.lower(), "application/octet-stream")


def _job_to_response(job: OcrJob) -> dict:
    return {
        "result": "error" if job.status == "failed" else "ok",
        "jobId": job.job_id,
        "status": job.status,
        "createdAtUtc": job.created_at_utc,
        "startedAtUtc": job.started_at_utc,
        "completedAtUtc": job.completed_at_utc,
        "engine": job.engine,
        "preprocessMode": job.preprocess_mode,
        "pageCount": job.page_count,
        "message": job.message,
        "error": job.error,
        "parentJobId": job.parent_job_id,
        "retryOfJobId": job.retry_of_job_id,
        "source": job.source,
        "artifacts": job.artifacts,
        "progress": job.progress,
    }
