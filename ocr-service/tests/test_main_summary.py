from __future__ import annotations

import unittest


class MainSummaryTests(unittest.TestCase):
    def test_build_result_summary_limits_text_and_counts_pages(self) -> None:
        import app.main as main

        summary = main._build_result_summary(
            {
                "jobId": "ocr_1",
                "status": "completed",
                "source": {"sourceType": "upload"},
                "language": "spa+eng",
                "engine": {"requested": "auto", "resolved": "tesseract"},
                "text": "abcdef",
                "confidenceAverage": 0.9,
                "quality": {"level": "good"},
                "warnings": [],
                "artifacts": [
                    {
                        "artifactId": "txt",
                        "type": "text/plain",
                        "path": "/hidden/path/result.txt",
                    }
                ],
                "pages": [
                    {
                        "pageNumber": 1,
                        "confidenceAverage": 0.9,
                        "text": "abcdef",
                        "blocks": [{"type": "word"}],
                    }
                ],
            },
            3,
        )

        self.assertEqual("ocr_1", summary["jobId"])
        self.assertEqual(1, summary["pageCount"])
        self.assertEqual("abc", summary["textPreview"])
        self.assertEqual("good", summary["quality"]["level"])
        self.assertEqual(6, summary["textLength"])
        self.assertEqual(1, summary["pages"][0]["blockCount"])
        self.assertNotIn("path", summary["artifacts"][0])

    def test_build_result_quality_returns_only_quality_fields(self) -> None:
        import app.main as main

        quality = main._build_result_quality(
            {
                "jobId": "ocr_1",
                "status": "completed",
                "confidenceAverage": 0.55,
                "quality": {
                    "level": "poor",
                    "warningCount": 1,
                    "warningCodes": ["low-confidence"],
                },
                "warnings": [
                    {
                        "code": "low-confidence",
                        "message": "La confianza promedio OCR es baja.",
                    }
                ],
                "text": "hidden from response",
                "pages": [{"blocks": [{"text": "hidden"}]}],
            }
        )

        self.assertEqual("ocr_1", quality["jobId"])
        self.assertEqual("completed", quality["status"])
        self.assertEqual(0.55, quality["confidenceAverage"])
        self.assertEqual("poor", quality["quality"]["level"])
        self.assertEqual("low-confidence", quality["warnings"][0]["code"])
        self.assertNotIn("text", quality)
        self.assertNotIn("pages", quality)


if __name__ == "__main__":
    unittest.main()
