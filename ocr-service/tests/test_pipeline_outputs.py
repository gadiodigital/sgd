from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from app.pipeline import _build_markdown, _write_outputs


class PipelineOutputTests(unittest.TestCase):
    def test_build_markdown_groups_text_by_page(self) -> None:
        markdown = _build_markdown(
            "ocr_1",
            [
                {
                    "pageNumber": 1,
                    "confidenceAverage": 0.875,
                    "text": "Hola mundo",
                }
            ],
        )

        self.assertIn("# OCR ocr_1", markdown)
        self.assertIn("## Pagina 1", markdown)
        self.assertIn("- Confianza promedio: 87.50%", markdown)
        self.assertIn("Hola mundo", markdown)

    def test_write_outputs_includes_markdown_when_requested(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output_dir = Path(directory)
            artifacts = _write_outputs(
                "ocr_1",
                output_dir,
                "Hola mundo",
                [
                    {
                        "pageNumber": 1,
                        "confidenceAverage": 0.9,
                        "text": "Hola mundo",
                    }
                ],
                True,
                False,
                [],
                "spa+eng",
                None,
            )

            markdown = next(
                artifact for artifact in artifacts if artifact["artifactId"] == "markdown"
            )
            self.assertEqual("text/markdown", markdown["type"])
            self.assertTrue(Path(markdown["path"]).exists())


if __name__ == "__main__":
    unittest.main()
