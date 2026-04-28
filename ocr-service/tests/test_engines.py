from __future__ import annotations

import unittest

from app.engines import OcrEngineError, resolve_engine


class EngineTests(unittest.TestCase):
    def test_auto_resolves_to_tesseract(self) -> None:
        selection = resolve_engine("auto")

        self.assertEqual("auto", selection.requested_engine)
        self.assertEqual("tesseract", selection.resolved_engine)

    def test_auto_preserves_requested_engine_when_default_is_tesseract(self) -> None:
        selection = resolve_engine("auto", "tesseract")

        self.assertEqual("auto", selection.requested_engine)
        self.assertEqual("tesseract", selection.resolved_engine)

    def test_paddleocr_is_explicitly_not_implemented(self) -> None:
        with self.assertRaises(OcrEngineError):
            resolve_engine("paddleocr")


if __name__ == "__main__":
    unittest.main()
