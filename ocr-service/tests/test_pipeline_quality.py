from __future__ import annotations

import unittest

from app.pipeline import _build_quality, _build_warnings, _progress_percent


class PipelineQualityTests(unittest.TestCase):
    def test_build_warnings_for_low_confidence_and_empty_text(self) -> None:
        warnings = _build_warnings(
            [
                {
                    "pageNumber": 1,
                    "confidenceAverage": 0.2,
                    "text": "",
                }
            ],
            0.2,
        )

        codes = {warning["code"] for warning in warnings}
        self.assertIn("low-document-confidence", codes)
        self.assertIn("low-page-confidence", codes)
        self.assertIn("empty-page-text", codes)

    def test_progress_percent_caps_running_progress_below_complete(self) -> None:
        self.assertEqual(0, _progress_percent(0, 4))
        self.assertEqual(50, _progress_percent(2, 4))
        self.assertEqual(99, _progress_percent(4, 4))

    def test_build_quality_classifies_good_review_and_poor(self) -> None:
        self.assertEqual("good", _build_quality(0.9, [])["level"])
        self.assertEqual(
            "review",
            _build_quality(
                0.75,
                [{"code": "low-document-confidence"}],
            )["level"],
        )
        self.assertEqual(
            "poor",
            _build_quality(
                0.8,
                [{"code": "empty-page-text"}],
            )["level"],
        )


if __name__ == "__main__":
    unittest.main()
