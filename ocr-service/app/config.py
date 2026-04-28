from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class OcrSettings:
    app_name: str
    version: str
    host: str
    port: int
    artifacts_root: Path
    default_engine: str
    default_languages: str
    tesseract_path: str | None
    allowed_source_roots: tuple[Path, ...]
    max_pages: int
    max_file_mb: int
    retention_hours: int


def load_settings() -> OcrSettings:
    base_dir = Path(__file__).resolve().parents[1]
    artifacts_root = Path(
        os.getenv("OCR_ARTIFACTS_ROOT", str(base_dir / "artifacts"))
    ).resolve()

    return OcrSettings(
        app_name=os.getenv("OCR_APP_NAME", "gdms-ocr-service"),
        version=os.getenv("OCR_VERSION", "0.1.0"),
        host=os.getenv("OCR_HOST", "127.0.0.1"),
        port=int(os.getenv("OCR_PORT", "8091")),
        artifacts_root=artifacts_root,
        default_engine=os.getenv("OCR_DEFAULT_ENGINE", "tesseract"),
        default_languages=os.getenv("OCR_DEFAULT_LANGUAGES", "spa+eng"),
        tesseract_path=os.getenv("OCR_TESSERACT_PATH") or None,
        allowed_source_roots=_parse_allowed_source_roots(os.getenv("OCR_ALLOWED_SOURCE_ROOTS", "")),
        max_pages=int(os.getenv("OCR_MAX_PAGES", "100")),
        max_file_mb=int(os.getenv("OCR_MAX_FILE_MB", "200")),
        retention_hours=int(os.getenv("OCR_RETENTION_HOURS", "72")),
    )


def _parse_allowed_source_roots(value: str) -> tuple[Path, ...]:
    roots = []
    for raw_root in value.split(os.pathsep):
        root = raw_root.strip()
        if root:
            roots.append(Path(root).resolve())
    return tuple(roots)
