from __future__ import annotations

import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from unittest.mock import patch

from app.config import load_settings
from app.dependencies import get_readiness_status


class DependencyTests(unittest.TestCase):
    def test_readiness_ready_when_dependencies_and_artifacts_are_available(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            settings = replace(load_settings(), artifacts_root=Path(directory))
            dependency_status = {
                "tesseract": {"available": True},
                "opencv": {"available": True},
                "pdf2image": {"available": True},
            }

            with patch("app.dependencies.get_dependency_status", return_value=dependency_status):
                status = get_readiness_status(settings)

            self.assertEqual("ready", status["status"])
            self.assertTrue(status["artifacts"]["writable"])

    def test_readiness_not_ready_when_dependency_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            settings = replace(load_settings(), artifacts_root=Path(directory))
            dependency_status = {
                "tesseract": {"available": False},
                "opencv": {"available": True},
                "pdf2image": {"available": True},
            }

            with patch("app.dependencies.get_dependency_status", return_value=dependency_status):
                status = get_readiness_status(settings)

            self.assertEqual("not-ready", status["status"])


if __name__ == "__main__":
    unittest.main()
