from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from app.pipeline import _build_source_metadata


class PipelineSourceTests(unittest.TestCase):
    def test_build_source_metadata_for_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source.png"
            source.write_bytes(b"abc")

            metadata = _build_source_metadata(
                {
                    "sourceType": "upload",
                    "scanSessionId": None,
                    "pageNumbers": [1],
                },
                source,
            )

            self.assertEqual("upload", metadata["sourceType"])
            self.assertEqual(".png", metadata["extension"])
            self.assertEqual(3, metadata["length"])
            self.assertEqual([1], metadata["requestedPageNumbers"])

    def test_build_source_metadata_for_mobile_capture(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "capture.jpg"
            source.write_bytes(b"abc")

            metadata = _build_source_metadata(
                {
                    "sourceType": "mobile-capture",
                    "mobileDeviceId": "android-01",
                    "mobileCaptureId": "capture-01",
                    "clientCapturedAtUtc": "2026-04-24T20:00:00Z",
                },
                source,
            )

            self.assertEqual("mobile-capture", metadata["sourceType"])
            self.assertEqual("android-01", metadata["mobileDeviceId"])
            self.assertEqual("capture-01", metadata["mobileCaptureId"])
            self.assertEqual("2026-04-24T20:00:00Z", metadata["clientCapturedAtUtc"])


if __name__ == "__main__":
    unittest.main()
