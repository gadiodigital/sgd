from __future__ import annotations

import asyncio
import io
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from unittest.mock import patch

from fastapi import BackgroundTasks, UploadFile

from app.job_store import JobStore


class MainWaitTests(unittest.TestCase):
    def test_schedule_or_process_job_wait_true_returns_final_state(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as directory:
            test_store = JobStore(Path(directory))
            job = test_store.create({"sourceType": "file"}, "tesseract", "auto")

            def fake_process(job, store, settings) -> None:
                store.update(job, status="completed", message="ok")

            with patch.object(main, "store", test_store), patch.object(
                main,
                "process_job",
                fake_process,
            ):
                response = main._schedule_or_process_job(job, BackgroundTasks(), wait=True)

            self.assertEqual("completed", response["status"])
            self.assertEqual("ok", response["message"])

    def test_upload_job_wait_true_returns_final_state(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as directory:
            test_root = Path(directory)
            test_store = JobStore(test_root)
            test_settings = replace(main.settings, artifacts_root=test_root)

            def fake_process(job, store, settings) -> None:
                store.update(
                    job,
                    status="completed",
                    message="upload ok",
                    page_count=1,
                    source={"sourceType": job.request["sourceType"]},
                )

            with patch.object(main, "store", test_store), patch.object(
                main,
                "settings",
                test_settings,
            ), patch.object(main, "process_job", fake_process):
                payload = asyncio.run(
                    main.create_upload_job(
                        background_tasks=BackgroundTasks(),
                        file=UploadFile(io.BytesIO(b"fake image bytes"), filename="page.png"),
                        language_hints="spa,eng",
                        outputs="json,txt",
                        engine="tesseract",
                        preprocess_mode="none",
                        wait=True,
                    )
                )

            self.assertEqual("completed", payload["status"])
            self.assertEqual("upload ok", payload["message"])
            self.assertEqual(1, payload["pageCount"])
            self.assertEqual("upload", payload["source"]["sourceType"])

    def test_mobile_capture_job_preserves_mobile_metadata(self) -> None:
        import app.main as main

        with tempfile.TemporaryDirectory() as directory:
            test_root = Path(directory)
            test_store = JobStore(test_root)
            test_settings = replace(main.settings, artifacts_root=test_root)

            def fake_process(job, store, settings) -> None:
                store.update(
                    job,
                    status="completed",
                    message="mobile ok",
                    page_count=1,
                    source={
                        "sourceType": job.request["sourceType"],
                        "mobileDeviceId": job.request["mobileDeviceId"],
                        "mobileCaptureId": job.request["mobileCaptureId"],
                    },
                )

            with patch.object(main, "store", test_store), patch.object(
                main,
                "settings",
                test_settings,
            ), patch.object(main, "process_job", fake_process):
                payload = asyncio.run(
                    main.create_mobile_capture_job(
                        background_tasks=BackgroundTasks(),
                        file=UploadFile(io.BytesIO(b"fake image bytes"), filename="capture.jpg"),
                        language_hints="",
                        outputs="json,txt",
                        engine="tesseract",
                        preprocess_mode="auto",
                        wait=True,
                        mobile_device_id="android-01",
                        mobile_capture_id="capture-01",
                        client_captured_at_utc="2026-04-24T20:00:00Z",
                    )
                )

            self.assertEqual("completed", payload["status"])
            self.assertEqual("mobile-capture", payload["source"]["sourceType"])
            self.assertEqual("android-01", payload["source"]["mobileDeviceId"])
            self.assertEqual("capture-01", payload["source"]["mobileCaptureId"])


if __name__ == "__main__":
    unittest.main()
