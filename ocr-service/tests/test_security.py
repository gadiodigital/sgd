from __future__ import annotations

import tempfile
import unittest
from dataclasses import replace
from pathlib import Path

from app.config import load_settings
from app.security import (
    OcrSecurityError,
    validate_output_path,
    validate_source_path,
    validate_upload_extension,
)


class SecurityTests(unittest.TestCase):
    def test_validate_upload_extension_accepts_supported_document(self) -> None:
        self.assertEqual(".pdf", validate_upload_extension("document.pdf"))
        self.assertEqual(".png", validate_upload_extension("page.PNG"))

    def test_validate_upload_extension_rejects_unsupported_document(self) -> None:
        with self.assertRaises(OcrSecurityError):
            validate_upload_extension("payload.exe")

    def test_validate_source_path_allows_path_inside_configured_root(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "scan" / "page.png"
            settings = replace(load_settings(), allowed_source_roots=(root.resolve(),))

            self.assertEqual(source.resolve(), validate_source_path(str(source), settings))

    def test_validate_source_path_rejects_path_outside_configured_root(self) -> None:
        with tempfile.TemporaryDirectory() as allowed, tempfile.TemporaryDirectory() as other:
            settings = replace(
                load_settings(),
                allowed_source_roots=(Path(allowed).resolve(),),
            )

            with self.assertRaises(OcrSecurityError):
                validate_source_path(str(Path(other) / "page.png"), settings)

    def test_validate_output_path_allows_path_inside_root(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / "jobs" / "ocr_1" / "output.txt"

            self.assertEqual(output.resolve(), validate_output_path(output, root, "Artefacto OCR"))

    def test_validate_output_path_rejects_path_outside_root(self) -> None:
        with tempfile.TemporaryDirectory() as allowed, tempfile.TemporaryDirectory() as other:
            with self.assertRaises(OcrSecurityError):
                validate_output_path(Path(other) / "secret.txt", Path(allowed), "Artefacto OCR")


if __name__ == "__main__":
    unittest.main()
