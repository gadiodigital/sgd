from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from PIL import Image

from app.document_loader import load_pages


class DocumentLoaderTests(unittest.TestCase):
    def test_load_single_image(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.png"
            Image.new("RGB", (120, 80), "white").save(source, dpi=(300, 300))

            pages = load_pages(source, root / "input", None, 300, 10)

            self.assertEqual(1, len(pages))
            self.assertEqual(1, pages[0].page_number)
            self.assertEqual(120, pages[0].width)
            self.assertEqual(80, pages[0].height)
            self.assertTrue(pages[0].image_path.exists())

    def test_load_tiff_selected_pages(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.tiff"
            frames = [
                Image.new("RGB", (100, 80), "white"),
                Image.new("RGB", (110, 90), "white"),
                Image.new("RGB", (120, 100), "white"),
            ]
            frames[0].save(source, save_all=True, append_images=frames[1:])

            pages = load_pages(source, root / "input", [2], 300, 10)

            self.assertEqual(1, len(pages))
            self.assertEqual(2, pages[0].page_number)
            self.assertEqual(110, pages[0].width)
            self.assertEqual(90, pages[0].height)

    def test_load_directory_selected_pages(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_dir = root / "scan-session"
            source_dir.mkdir()
            Image.new("RGB", (100, 80), "white").save(source_dir / "page-001.bmp")
            Image.new("RGB", (110, 90), "white").save(source_dir / "page-002.bmp")
            Image.new("RGB", (120, 100), "white").save(source_dir / "page-003.bmp")

            pages = load_pages(source_dir, root / "input", [1, 3], 300, 10)

            self.assertEqual(2, len(pages))
            self.assertEqual([1, 3], [page.page_number for page in pages])
            self.assertEqual(120, pages[1].width)


if __name__ == "__main__":
    unittest.main()
