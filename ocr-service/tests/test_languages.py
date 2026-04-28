from __future__ import annotations

import unittest

from app.pipeline import _resolve_languages


class LanguageTests(unittest.TestCase):
    def test_resolve_languages_uses_hints_when_present(self) -> None:
        self.assertEqual("spa+eng", _resolve_languages(["spa", "eng"], "eng"))

    def test_resolve_languages_uses_configured_default_when_hints_are_empty(self) -> None:
        self.assertEqual("eng", _resolve_languages(None, "eng"))


if __name__ == "__main__":
    unittest.main()
