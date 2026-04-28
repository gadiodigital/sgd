from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from fastapi import HTTPException
from fastapi.responses import FileResponse

from app.job_store import JobStore


class MainArtifactSecurityTests(unittest.TestCase):
    def test_get_artifact_rejects_path_outside_job_directory(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as job_root, tempfile.TemporaryDirectory() as other_root:
            store = JobStore(Path(job_root))
            external = Path(other_root) / "external.txt"
            external.write_text("secret", encoding="utf-8")
            job = store.create({"sourceType": "file", "sourcePath": "page.png"}, "tesseract", "auto")
            store.update(
                job,
                artifacts=[
                    {
                        "artifactId": "external",
                        "type": "text/plain",
                        "path": str(external),
                    }
                ],
            )

            with patch.object(main, "store", store):
                with self.assertRaises(HTTPException) as raised:
                    main.get_artifact(job.job_id, "external")

            self.assertEqual(404, raised.exception.status_code)

    def test_get_job_text_uses_txt_artifact(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as job_root:
            store = JobStore(Path(job_root))
            job = store.create({"sourceType": "file", "sourcePath": "page.png"}, "tesseract", "auto")
            txt_path = store.job_dir(job.job_id) / "output" / "result.txt"
            txt_path.parent.mkdir(parents=True, exist_ok=True)
            txt_path.write_text("texto OCR", encoding="utf-8")
            store.update(
                job,
                artifacts=[
                    {
                        "artifactId": "txt",
                        "type": "text/plain",
                        "path": str(txt_path),
                    }
                ],
            )

            with patch.object(main, "store", store):
                response = main.get_job_text(job.job_id)

            self.assertIsInstance(response, FileResponse)
            self.assertEqual(txt_path, Path(response.path))
            self.assertEqual("text/plain", response.media_type)

    def test_get_job_markdown_uses_markdown_artifact(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as job_root:
            store = JobStore(Path(job_root))
            job = store.create({"sourceType": "file", "sourcePath": "page.png"}, "tesseract", "auto")
            markdown_path = store.job_dir(job.job_id) / "output" / "result.md"
            markdown_path.parent.mkdir(parents=True, exist_ok=True)
            markdown_path.write_text("# OCR\n", encoding="utf-8")
            store.update(
                job,
                artifacts=[
                    {
                        "artifactId": "markdown",
                        "type": "text/markdown",
                        "path": str(markdown_path),
                    }
                ],
            )

            with patch.object(main, "store", store):
                response = main.get_job_markdown(job.job_id)

            self.assertIsInstance(response, FileResponse)
            self.assertEqual(markdown_path, Path(response.path))
            self.assertEqual("text/markdown", response.media_type)


if __name__ == "__main__":
    unittest.main()
