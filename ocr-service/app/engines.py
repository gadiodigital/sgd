from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from app.tesseract_engine import TesseractResult, run_tesseract


class OcrEngineError(RuntimeError):
    pass


@dataclass(frozen=True)
class EngineSelection:
    requested_engine: str
    resolved_engine: str


def resolve_engine(requested_engine: str, default_engine: str = "tesseract") -> EngineSelection:
    if requested_engine == "auto":
        resolved_default = resolve_engine(default_engine, default_engine)
        return EngineSelection("auto", resolved_default.resolved_engine)
    if requested_engine == "tesseract":
        return EngineSelection(requested_engine, "tesseract")
    if requested_engine == "paddleocr":
        raise OcrEngineError("PaddleOCR esta planificado pero todavia no esta implementado.")
    raise OcrEngineError(f"Motor OCR no soportado: {requested_engine}")


def run_ocr_engine(
    engine: str,
    image_path: Path,
    languages: str,
    tesseract_path: str | None,
) -> TesseractResult:
    if engine == "tesseract":
        return run_tesseract(image_path, languages, tesseract_path)
    raise OcrEngineError(f"Motor OCR no implementado: {engine}")
