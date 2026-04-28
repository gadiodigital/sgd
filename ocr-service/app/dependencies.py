from __future__ import annotations

import shutil
from uuid import uuid4

from app.config import OcrSettings


def get_dependency_status(settings: OcrSettings) -> dict:
    return {
        "tesseract": _check_tesseract(settings),
        "opencv": _check_import("cv2"),
        "pdf2image": _check_import("pdf2image"),
    }


def get_readiness_status(settings: OcrSettings) -> dict:
    dependencies = get_dependency_status(settings)
    artifacts = _check_artifacts_root(settings)
    ready = artifacts["writable"] and all(
        dependencies[name]["available"] for name in ("tesseract", "opencv", "pdf2image")
    )

    return {
        "status": "ready" if ready else "not-ready",
        "dependencies": dependencies,
        "artifacts": artifacts,
    }


def _check_tesseract(settings: OcrSettings) -> dict:
    executable = settings.tesseract_path or shutil.which("tesseract")
    return {
        "available": executable is not None,
        "path": executable,
    }


def _check_import(module_name: str) -> dict:
    try:
        module = __import__(module_name)
    except ImportError as exc:
        return {
            "available": False,
            "version": None,
            "error": str(exc),
        }

    return {
        "available": True,
        "version": getattr(module, "__version__", None),
        "error": None,
    }


def _check_artifacts_root(settings: OcrSettings) -> dict:
    path = settings.artifacts_root
    probe_path = path / f".readiness-{uuid4().hex}.tmp"
    try:
        path.mkdir(parents=True, exist_ok=True)
        probe_path.write_text("ok", encoding="utf-8")
        probe_path.unlink(missing_ok=True)
    except OSError as exc:
        return {
            "path": str(path),
            "writable": False,
            "error": str(exc),
        }

    return {
        "path": str(path),
        "writable": True,
        "error": None,
    }
