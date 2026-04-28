from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from app.config import load_settings
from app.document_loader import LoadedPage
from app.job_store import JobStore
from app.pipeline import process_job


class PipelineCancelTests(unittest.TestCase):
    def test_process_job_does_not_start_when_already_cancelled(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            store = JobStore(Path(directory))
            job = store.create({"sourceType": "file", "sourcePath": "page.png"}, "tesseract", "auto")
            store.update(job, status="cancelled", message="Job cancelado.")

            process_job(job, store, load_settings())

            updated = store.read_job(job.job_id)
            self.assertEqual("cancelled", updated.status)
            self.assertIsNone(updated.started_at_utc)

    def test_process_job_stops_when_cancelled_after_loading_pages(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            store = JobStore(root)
            source = root / "page.png"
            source.write_bytes(b"fake")
            job = store.create(
                {"sourceType": "file", "sourcePath": str(source), "options": {"targetDpi": 300}},
                "tesseract",
                "auto",
            )

            def fake_load_pages(*args, **kwargs):
                store.update(store.read_job(job.job_id), status="cancelled")
                return [LoadedPage(1, source, 100, 100, 300)]

            with patch("app.pipeline.load_pages", fake_load_pages), patch(
                "app.pipeline.preprocess_image",
            ) as preprocess:
                process_job(job, store, load_settings())

            updated = store.read_job(job.job_id)
            self.assertEqual("cancelled", updated.status)
            self.assertEqual("cancelled", updated.progress["stage"])
            preprocess.assert_not_called()


if __name__ == "__main__":
    unittest.main()
