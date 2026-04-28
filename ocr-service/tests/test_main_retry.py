from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from fastapi import BackgroundTasks, HTTPException

from app.job_store import JobStore


class MainRetryTests(unittest.TestCase):
    def test_retry_job_creates_new_job_from_failed_request(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as directory:
            store = JobStore(Path(directory))
            original = store.create(
                {"sourceType": "file", "sourcePath": "page.png"},
                "tesseract",
                "none",
            )
            store.update(original, status="failed", error="bad input")

            def fake_process(job, store, settings) -> None:
                store.update(job, status="completed", message="retry ok")

            with patch.object(main, "store", store), patch.object(
                main,
                "process_job",
                fake_process,
            ):
                response = main.retry_job(original.job_id, BackgroundTasks(), wait=True)

            self.assertNotEqual(original.job_id, response["jobId"])
            self.assertEqual("completed", response["status"])
            self.assertEqual("retry ok", response["message"])
            self.assertEqual(original.job_id, response["parentJobId"])
            self.assertEqual(original.job_id, response["retryOfJobId"])

    def test_retry_job_rejects_completed_job(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as directory:
            store = JobStore(Path(directory))
            original = store.create({"sourceType": "file"}, "tesseract", "auto")
            store.update(original, status="completed")

            with patch.object(main, "store", store):
                with self.assertRaises(HTTPException) as raised:
                    main.retry_job(original.job_id, BackgroundTasks())

            self.assertEqual(409, raised.exception.status_code)


if __name__ == "__main__":
    unittest.main()
