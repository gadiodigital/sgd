from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from app.job_store import JobStore


class MainRetriesTests(unittest.TestCase):
    def test_get_job_retries_returns_retry_chain(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as directory:
            store = JobStore(Path(directory))
            root = store.create({"sourceType": "file"}, "tesseract", "auto")
            retry = store.create(
                {
                    "sourceType": "file",
                    "parentJobId": root.job_id,
                    "retryOfJobId": root.job_id,
                },
                "tesseract",
                "auto",
            )

            with patch.object(main, "store", store):
                response = main.get_job_retries(retry.job_id)

            self.assertEqual(root.job_id, response["rootJobId"])
            self.assertEqual(2, response["total"])
            self.assertEqual([root.job_id, retry.job_id], [item["jobId"] for item in response["items"]])


if __name__ == "__main__":
    unittest.main()
