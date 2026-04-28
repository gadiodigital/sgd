from __future__ import annotations

import tempfile
import json
import unittest
from pathlib import Path

from app.job_store import JobStore


class JobStoreTests(unittest.TestCase):
    def test_create_read_update_and_delete_job(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            store = JobStore(Path(directory))

            job = store.create(
                {
                    "sourceType": "file",
                    "sourcePath": "sample.png",
                    "parentJobId": "ocr_parent",
                    "retryOfJobId": "ocr_failed",
                },
                "tesseract",
                "auto",
            )

            self.assertEqual("queued", job.status)
            self.assertTrue(job.job_id.startswith("ocr_"))
            self.assertEqual("queued", job.progress["stage"])
            self.assertEqual("ocr_parent", job.parent_job_id)
            self.assertEqual("ocr_failed", job.retry_of_job_id)

            loaded = store.read_job(job.job_id)
            self.assertEqual(job.job_id, loaded.job_id)

            store.update(loaded, status="completed", page_count=1)
            updated = store.read_job(job.job_id)
            self.assertEqual("completed", updated.status)
            self.assertEqual(1, updated.page_count)

            store.delete(job.job_id)
            with self.assertRaises(KeyError):
                store.read_job(job.job_id)

    def test_list_filters_and_paginates_jobs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            store = JobStore(Path(directory))
            completed = store.create({"sourceType": "file"}, "tesseract", "auto")
            failed = store.create({"sourceType": "file"}, "tesseract", "auto")
            store.update(completed, status="completed")
            store.update(failed, status="failed")

            jobs, total = store.list(status="completed", limit=10, offset=0)

            self.assertEqual(1, total)
            self.assertEqual("completed", jobs[0].status)

            empty_page, total = store.list(limit=1, offset=10)
            self.assertEqual(2, total)
            self.assertEqual([], empty_page)

    def test_list_filters_by_source_type_and_created_range(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            store = JobStore(Path(directory))
            upload = store.create({"sourceType": "upload"}, "tesseract", "auto")
            mobile = store.create({"sourceType": "mobile-capture"}, "tesseract", "auto")
            store.update(upload, created_at_utc="2026-04-24T10:00:00Z")
            store.update(mobile, created_at_utc="2026-04-25T10:00:00Z")

            jobs, total = store.list(
                source_type="mobile-capture",
                created_from="2026-04-25T00:00:00Z",
                created_to="2026-04-25T23:59:59Z",
                order="asc",
            )

            self.assertEqual(1, total)
            self.assertEqual(mobile.job_id, jobs[0].job_id)

    def test_list_retry_chain_returns_root_and_retries(self) -> None:
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

            chain = store.list_retry_chain(retry.job_id)

            self.assertEqual([root.job_id, retry.job_id], [job.job_id for job in chain])

    def test_read_legacy_job_without_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            store = JobStore(root)
            job_dir = root / "jobs" / "ocr_legacy"
            job_dir.mkdir(parents=True)
            (job_dir / "job.json").write_text(
                json.dumps(
                    {
                        "job_id": "ocr_legacy",
                        "status": "completed",
                        "created_at_utc": "2026-04-24T00:00:00Z",
                        "started_at_utc": None,
                        "completed_at_utc": None,
                        "engine": "tesseract",
                        "preprocess_mode": "auto",
                        "page_count": 0,
                        "message": "ok",
                        "request": {},
                        "error": None,
                        "artifacts": [],
                    }
                ),
                encoding="utf-8",
            )

            job = store.read_job("ocr_legacy")

            self.assertIsNone(job.source)
            self.assertEqual({}, job.progress)
            self.assertIsNone(job.parent_job_id)
            self.assertIsNone(job.retry_of_job_id)


if __name__ == "__main__":
    unittest.main()
