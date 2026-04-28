from __future__ import annotations

from pathlib import Path

from app.tesseract_engine import run_tesseract_pdf


def export_searchable_pdf(
    page_image_paths: list[Path],
    output_pdf_path: Path,
    languages: str,
    tesseract_path: str | None,
) -> None:
    output_pdf_path.parent.mkdir(parents=True, exist_ok=True)
    page_pdf_paths = []

    for index, image_path in enumerate(page_image_paths, start=1):
        page_pdf_path = output_pdf_path.parent / f"searchable-page-{index:03}.pdf"
        run_tesseract_pdf(image_path, page_pdf_path, languages, tesseract_path)
        page_pdf_paths.append(page_pdf_path)

    if len(page_pdf_paths) == 1:
        page_pdf_paths[0].replace(output_pdf_path)
        return

    try:
        from pypdf import PdfWriter
    except ImportError as exc:
        raise RuntimeError("pypdf no esta instalado; no se puede unir PDF searchable.") from exc

    writer = PdfWriter()
    for page_pdf_path in page_pdf_paths:
        writer.append(str(page_pdf_path))

    with output_pdf_path.open("wb") as output:
        writer.write(output)
