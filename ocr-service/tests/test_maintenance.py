from __future__ import annotations

import os
import tempfile
import time
import unittest
from pathlib import Path

from app.maintenance import cleanup_artifacts, get_storage_status


class MaintenanceTests(unittest.TestCase):
    def test_storage_status_counts_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "jobs" / "ocr_1").mkdir(parents=True)
            (root / "uploads").mkdir()
            (root / "uploads" / "file.png").write_text("abc", encoding="utf-8")
            (root / "preprocess" / "preprocess_1").mkdir(parents=True)

            status = get_storage_status(root)

            self.assertEqual(1, status.job_count)
            self.assertEqual(1, status.upload_count)
            self.assertEqual(1, status.preprocess_count)
            self.assertEqual(3, status.total_bytes)

    def test_cleanup_removes_only_old_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old_job = root / "jobs" / "ocr_old"
            new_job = root / "jobs" / "ocr_new"
            old_job.mkdir(parents=True)
            new_job.mkdir()
            (old_job / "result.txt").write_text("old", encoding="utf-8")
            (new_job / "result.txt").write_text("new", encoding="utf-8")

            old_timestamp = time.time() - 48 * 60 * 60
            os.utime(old_job / "result.txt", (old_timestamp, old_timestamp))
            os.utime(old_job, (old_timestamp, old_timestamp))

            result = cleanup_artifacts(root, retention_hours=24)

            self.assertEqual(1, result.deleted_count)
            self.assertFalse(old_job.exists())
            self.assertTrue(new_job.exists())


if __name__ == "__main__":
    unittest.main()
