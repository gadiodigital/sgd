from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageSequence


SUPPORTED_IMAGE_EXTENSIONS = {".bmp", ".jpg", ".jpeg", ".png", ".tif", ".tiff"}
SUPPORTED_DOCUMENT_EXTENSIONS = SUPPORTED_IMAGE_EXTENSIONS | {".pdf"}


@dataclass(frozen=True)
class LoadedPage:
    page_number: int
    image_path: Path
    width: int
    height: int
    dpi: int


def load_pages(
    source_path: Path,
    input_dir: Path,
    page_numbers: list[int] | None,
    target_dpi: int,
    max_pages: int,
) -> list[LoadedPage]:
    if not source_path.exists():
        raise FileNotFoundError(f"No existe el archivo de entrada: {source_path}")

    input_dir.mkdir(parents=True, exist_ok=True)
    requested_pages = _normalize_page_numbers(page_numbers)

    if source_path.is_dir():
        pages = _load_directory(source_path, input_dir, requested_pages, target_dpi)
        if len(pages) > max_pages:
            raise ValueError(f"El documento excede el maximo de paginas permitido: {max_pages}")
        return pages

    extension = source_path.suffix.lower()
    if extension not in SUPPORTED_DOCUMENT_EXTENSIONS:
        raise ValueError(f"Formato no soportado para OCR: {extension}")

    if extension == ".pdf":
        pages = _load_pdf(source_path, input_dir, requested_pages, target_dpi)
    elif extension in {".tif", ".tiff"}:
        pages = _load_tiff(source_path, input_dir, requested_pages, target_dpi)
    else:
        pages = [_load_single_image(source_path, input_dir, target_dpi)]

    if len(pages) > max_pages:
        raise ValueError(f"El documento excede el maximo de paginas permitido: {max_pages}")
    return pages


def _load_directory(
    source_dir: Path,
    input_dir: Path,
    requested_pages: set[int] | None,
    target_dpi: int,
) -> list[LoadedPage]:
    candidates = [
        path
        for path in sorted(source_dir.iterdir(), key=lambda candidate: candidate.name.lower())
        if path.is_file() and path.suffix.lower() in SUPPORTED_IMAGE_EXTENSIONS
    ]
    if not candidates:
        raise ValueError(f"No se encontraron imagenes soportadas en el directorio: {source_dir}")

    pages: list[LoadedPage] = []
    for index, source_path in enumerate(candidates, start=1):
        if requested_pages is not None and index not in requested_pages:
            continue

        target_path = input_dir / f"page-{index:03}{source_path.suffix.lower()}"
        shutil.copy2(source_path, target_path)
        with Image.open(target_path) as image:
            pages.append(
                LoadedPage(
                    index,
                    target_path,
                    image.width,
                    image.height,
                    _read_dpi(image, target_dpi),
                )
            )

    return _ensure_pages_found(pages, requested_pages)


def _load_single_image(source_path: Path, input_dir: Path, target_dpi: int) -> LoadedPage:
    target_path = input_dir / f"page-001{source_path.suffix.lower()}"
    shutil.copy2(source_path, target_path)
    with Image.open(target_path) as image:
        dpi = _read_dpi(image, target_dpi)
        return LoadedPage(1, target_path, image.width, image.height, dpi)


def _load_tiff(
    source_path: Path,
    input_dir: Path,
    requested_pages: set[int] | None,
    target_dpi: int,
) -> list[LoadedPage]:
    pages: list[LoadedPage] = []
    with Image.open(source_path) as image:
        for index, frame in enumerate(ImageSequence.Iterator(image), start=1):
            if requested_pages is not None and index not in requested_pages:
                continue

            target_path = input_dir / f"page-{index:03}.png"
            page_image = frame.convert("RGB")
            page_image.save(target_path, dpi=(target_dpi, target_dpi))
            pages.append(
                LoadedPage(index, target_path, page_image.width, page_image.height, target_dpi)
            )

    return _ensure_pages_found(pages, requested_pages)


def _load_pdf(
    source_path: Path,
    input_dir: Path,
    requested_pages: set[int] | None,
    target_dpi: int,
) -> list[LoadedPage]:
    try:
        from pdf2image import convert_from_path
    except ImportError as exc:
        raise RuntimeError("pdf2image no esta instalado; no se puede procesar PDF.") from exc

    first_page = min(requested_pages) if requested_pages else None
    last_page = max(requested_pages) if requested_pages else None
    images = convert_from_path(
        str(source_path),
        dpi=target_dpi,
        first_page=first_page,
        last_page=last_page,
    )

    pages: list[LoadedPage] = []
    base_page_number = first_page or 1
    for offset, image in enumerate(images):
        page_number = base_page_number + offset
        if requested_pages is not None and page_number not in requested_pages:
            continue

        target_path = input_dir / f"page-{page_number:03}.png"
        image.save(target_path, dpi=(target_dpi, target_dpi))
        pages.append(LoadedPage(page_number, target_path, image.width, image.height, target_dpi))

    return _ensure_pages_found(pages, requested_pages)


def _normalize_page_numbers(page_numbers: list[int] | None) -> set[int] | None:
    if not page_numbers:
        return None
    normalized = {page for page in page_numbers if page > 0}
    if len(normalized) != len(page_numbers):
        raise ValueError("pageNumbers solo puede contener numeros positivos.")
    return normalized


def _ensure_pages_found(
    pages: list[LoadedPage],
    requested_pages: set[int] | None,
) -> list[LoadedPage]:
    if not pages:
        raise ValueError("No se encontraron paginas para procesar.")
    if requested_pages is not None:
        found = {page.page_number for page in pages}
        missing = sorted(requested_pages - found)
        if missing:
            raise ValueError(f"No se encontraron las paginas solicitadas: {missing}")
    return pages


def _read_dpi(image: Image.Image, fallback: int) -> int:
    dpi = image.info.get("dpi")
    if isinstance(dpi, tuple) and dpi:
        return max(1, int(round(dpi[0])))
    return fallback
