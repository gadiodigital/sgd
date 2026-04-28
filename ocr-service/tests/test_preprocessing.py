from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from app.preprocessing import preprocess_image


class PreprocessingTests(unittest.TestCase):
    def test_auto_preprocessing_records_candidate_diagnostics(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.png"
            image = Image.new("RGB", (400, 160), "white")
            draw = ImageDraw.Draw(image)
            draw.text((30, 60), "OCR 123", fill="black")
            image.save(source)

            result = preprocess_image(source, root / "output", "auto")

            self.assertTrue(result.image_path.exists())
            self.assertEqual("auto", result.diagnostics["mode"])
            self.assertIn("selectedCandidate", result.diagnostics)
            self.assertGreaterEqual(len(result.diagnostics["candidates"]), 3)

    def test_none_preprocessing_copies_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.png"
            Image.new("RGB", (100, 80), "white").save(source)

            result = preprocess_image(source, root / "output", "none")

            self.assertTrue(result.image_path.exists())
            self.assertEqual(["copy"], result.diagnostics["applied"])


if __name__ == "__main__":
    unittest.main()
