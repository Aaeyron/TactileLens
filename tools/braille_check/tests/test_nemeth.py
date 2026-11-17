"""The Nemeth reference file and checker."""

import json
import re
import unittest

from tools.braille_check import check_nemeth, lou

_CELLS = re.compile(r"^[⠀-⣿]+$")


class NemethReferenceFileTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = json.loads(check_nemeth.REFERENCE.read_text(encoding="utf-8"))
        cls.items = cls.document["items"]

    def test_names_the_code(self):
        self.assertIn("Nemeth", self.document["document"])
        self.assertIn("2022", self.document["document"])
        self.assertTrue(self.document["url"].startswith("https://brailleauthority.org/"))

    def test_20_to_30_items_each_citing_its_example(self):
        self.assertGreaterEqual(len(self.items), 20)
        self.assertLessEqual(len(self.items), 30)

        for item in self.items:
            with self.subTest(item["id"]):
                self.assertRegex(item["source"]["example"], r"^\d{1,2}-\d{1,3}$")
                self.assertEqual(item["id"], "n" + item["source"]["example"])
                self.assertIsInstance(item["source"]["pdf_page"], int)
                self.assertRegex(item["nemeth"], _CELLS)
                self.assertEqual(len(item["nemeth"]), len(item["ascii"]))


class CellsTests(unittest.TestCase):
    def test_spaces_and_no_break_spaces_are_blank_cells_and_edges_are_ignored(self):
        self.assertEqual(check_nemeth.cells(" ⠌⠨⠅ "), "⠌⠨⠅")
        self.assertEqual(check_nemeth.cells("⠭ ⠨⠅ ⠽"), "⠭⠀⠨⠅⠀⠽")


@unittest.skipUnless(lou.available(), "Liblouis or the app's tables are not here")
class NemethResultsTests(unittest.TestCase):
    def test_results_measured_on_2026_11_17(self):
        rows = check_nemeth.check(check_nemeth.load_reference())
        by_result = {}

        for row in rows:
            by_result.setdefault(row["result"], []).append(row["id"])

        self.assertEqual(by_result["match"], ["n3-5", "n3-6", "n3-11", "n3-12"])
        # Our ≠ -> "!=" rewrite; Liblouis alone writes ⠌⠨⠅ as the book does.
        self.assertEqual(by_result["our code"], ["n21-1"])
        self.assertEqual(len(by_result["Liblouis"]), 22)


if __name__ == "__main__":
    unittest.main()
