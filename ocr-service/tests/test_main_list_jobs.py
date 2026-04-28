from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from fastapi import HTTPException

from app.job_store import JobStore


class MainListJobsTests(unittest.TestCase):
    def test_list_jobs_returns_filters_echo(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as directory:
            store = JobStore(Path(directory))
            job = store.create({"sourceType": "upload"}, "tesseract", "auto")
            store.update(job, status="completed")

            with patch.object(main, "store", store):
                response = main.list_jobs(status="completed", source_type="upload")

            self.assertEqual(1, response["total"])
            self.assertEqual("completed", response["filters"]["status"])
            self.assertEqual("upload", response["filters"]["sourceType"])

    def test_list_jobs_rejects_invalid_order(self) -> None:
        import app.main as main

        with self.assertRaises(HTTPException) as raised:
            main.list_jobs(order="sideways")

        self.assertEqual(400, raised.exception.status_code)


if __name__ == "__main__":
    unittest.main()
