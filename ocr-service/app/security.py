from __future__ import annotations

from pathlib import Path

from app.config import OcrSettings
from app.document_loader import SUPPORTED_DOCUMENT_EXTENSIONS


class OcrSecurityError(ValueError):
    pass


def validate_upload_extension(filename: str | None) -> str:
    suffix = Path(filename or "upload.bin").suffix.lower()
    if suffix not in SUPPORTED_DOCUMENT_EXTENSIONS:
        raise OcrSecurityError(f"Formato de upload no soportado para OCR: {suffix or '<sin extension>'}")
    return suffix


def validate_source_path(source_path: str | None, settings: OcrSettings) -> Path:
    if not source_path:
        raise OcrSecurityError("sourcePath es requerido para crear el job OCR.")

    path = Path(source_path).expanduser().resolve()
    if not settings.allowed_source_roots:
        return path

    if any(_is_relative_to(path, root) for root in settings.allowed_source_roots):
        return path

    allowed = ", ".join(str(root) for root in settings.allowed_source_roots)
    raise OcrSecurityError(f"sourcePath esta fuera de las rutas permitidas: {allowed}")


def validate_output_path(path: str | Path, root: Path, label: str = "archivo") -> Path:
    resolved_path = Path(path).resolve()
    resolved_root = root.resolve()
    if not _is_relative_to(resolved_path, resolved_root):
        raise OcrSecurityError(f"{label} esta fuera del directorio permitido.")
    return resolved_path


def _is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
    except ValueError:
        return False
    return True
