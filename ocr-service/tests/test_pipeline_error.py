from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from app.job_store import JobStore
from app.pipeline import _write_error_artifact


class PipelineErrorTests(unittest.TestCase):
    def test_write_error_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            store = JobStore(Path(directory))
            job = store.create({"sourceType": "file"}, "tesseract", "auto")

            artifact = _write_error_artifact(job, store, ValueError("bad input"))
            payload = json.loads(Path(artifact["path"]).read_text(encoding="utf-8"))

            self.assertEqual("error", artifact["artifactId"])
            self.assertEqual("failed", payload["status"])
            self.assertEqual("ValueError", payload["errorType"])
            self.assertEqual("bad input", payload["message"])


if __name__ == "__main__":
    unittest.main()
