from __future__ import annotations

import unittest

from app.tesseract_engine import parse_tesseract_tsv


class TesseractParserTests(unittest.TestCase):
    def test_parse_tsv_filters_empty_and_invalid_confidence(self) -> None:
        tsv = "\n".join(
            [
                "level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext",
                "5\t1\t1\t1\t1\t1\t10\t20\t30\t40\t95\tHola",
                "5\t1\t1\t1\t1\t2\t50\t20\t60\t40\t80\tmundo",
                "5\t1\t1\t1\t2\t1\t10\t80\t30\t40\t90\tLinea",
                "5\t1\t1\t1\t2\t2\t50\t80\t60\t40\t70\tdos",
                "5\t1\t1\t1\t1\t3\t0\t0\t0\t0\t-1\t",
            ]
        )

        result = parse_tesseract_tsv(tsv)

        self.assertEqual("Hola mundo Linea dos", result.text)
        self.assertEqual(0.8375, result.confidence_average)
        self.assertEqual(4, len(result.words))
        self.assertEqual(2, len(result.lines))
        self.assertEqual("Hola mundo", result.lines[0].text)
        self.assertEqual({"x": 10, "y": 20, "w": 100, "h": 40}, result.lines[0].bbox)
        self.assertEqual({"x": 10, "y": 20, "w": 30, "h": 40}, result.words[0].bbox)


if __name__ == "__main__":
    unittest.main()
