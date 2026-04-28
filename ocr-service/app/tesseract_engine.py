from __future__ import annotations

import csv
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path


class OcrDependencyError(RuntimeError):
    pass


@dataclass
class TesseractWord:
    text: str
    confidence: float
    bbox: dict[str, int]
    block_number: int
    paragraph_number: int
    line_number: int


@dataclass
class TesseractLine:
    text: str
    confidence: float
    bbox: dict[str, int]
    block_number: int
    paragraph_number: int
    line_number: int


@dataclass
class TesseractResult:
    text: str
    confidence_average: float
    words: list[TesseractWord]
    lines: list[TesseractLine]


def run_tesseract(
    image_path: Path,
    languages: str,
    tesseract_path: str | None,
) -> TesseractResult:
    executable = tesseract_path or shutil.which("tesseract")
    if not executable:
        raise OcrDependencyError(
            "No se encontro Tesseract. Instalarlo o definir OCR_TESSERACT_PATH."
        )

    command = [executable, str(image_path), "stdout", "-l", languages, "--psm", "3", "tsv"]
    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )

    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "Tesseract finalizo con error.")

    return parse_tesseract_tsv(completed.stdout)


def run_tesseract_pdf(
    image_path: Path,
    output_pdf_path: Path,
    languages: str,
    tesseract_path: str | None,
) -> None:
    executable = tesseract_path or shutil.which("tesseract")
    if not executable:
        raise OcrDependencyError(
            "No se encontro Tesseract. Instalarlo o definir OCR_TESSERACT_PATH."
        )

    output_base = output_pdf_path.with_suffix("")
    command = [executable, str(image_path), str(output_base), "-l", languages, "--psm", "3", "pdf"]
    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )

    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "Tesseract PDF finalizo con error.")


def parse_tesseract_tsv(tsv: str) -> TesseractResult:
    rows = csv.DictReader(tsv.splitlines(), delimiter="\t")
    words: list[TesseractWord] = []
    text_parts: list[str] = []
    confidences: list[float] = []

    for row in rows:
        raw_text = (row.get("text") or "").strip()
        if not raw_text:
            continue

        confidence = _parse_confidence(row.get("conf"))
        if confidence < 0:
            continue

        word = TesseractWord(
            text=raw_text,
            confidence=confidence / 100,
            bbox={
                "x": _parse_int(row.get("left")),
                "y": _parse_int(row.get("top")),
                "w": _parse_int(row.get("width")),
                "h": _parse_int(row.get("height")),
            },
            block_number=_parse_int(row.get("block_num")),
            paragraph_number=_parse_int(row.get("par_num")),
            line_number=_parse_int(row.get("line_num")),
        )
        words.append(word)
        text_parts.append(raw_text)
        confidences.append(word.confidence)

    confidence_average = sum(confidences) / len(confidences) if confidences else 0
    return TesseractResult(
        text=" ".join(text_parts),
        confidence_average=round(confidence_average, 4),
        words=words,
        lines=_build_lines(words),
    )


def _build_lines(words: list[TesseractWord]) -> list[TesseractLine]:
    grouped: dict[tuple[int, int, int], list[TesseractWord]] = {}
    for word in words:
        key = (word.block_number, word.paragraph_number, word.line_number)
        grouped.setdefault(key, []).append(word)

    lines: list[TesseractLine] = []
    for key, line_words in grouped.items():
        block_number, paragraph_number, line_number = key
        confidences = [word.confidence for word in line_words]
        lines.append(
            TesseractLine(
                text=" ".join(word.text for word in line_words),
                confidence=round(sum(confidences) / len(confidences), 4),
                bbox=_merge_bboxes([word.bbox for word in line_words]),
                block_number=block_number,
                paragraph_number=paragraph_number,
                line_number=line_number,
            )
        )

    return lines


def _merge_bboxes(bboxes: list[dict[str, int]]) -> dict[str, int]:
    left = min(bbox["x"] for bbox in bboxes)
    top = min(bbox["y"] for bbox in bboxes)
    right = max(bbox["x"] + bbox["w"] for bbox in bboxes)
    bottom = max(bbox["y"] + bbox["h"] for bbox in bboxes)
    return {
        "x": left,
        "y": top,
        "w": right - left,
        "h": bottom - top,
    }


def _parse_confidence(value: str | None) -> float:
    try:
        return float(value or "-1")
    except ValueError:
        return -1


def _parse_int(value: str | None) -> int:
    try:
        return int(float(value or "0"))
    except ValueError:
        return 0
