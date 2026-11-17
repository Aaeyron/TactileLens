"""reference_ueb.json is well formed and cites its source for every item."""

import json
import re
import unittest

from tools.braille_check.check_reference import REFERENCE, load_reference

_CELLS = re.compile(r"^[⠀-⣿]+$")
_RULE = re.compile(r"^\d{1,2}\.\d{1,2}\.\d{1,2}$")


class ReferenceFileTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = json.loads(REFERENCE.read_text(encoding="utf-8"))
        cls.items = load_reference()

    def test_names_the_rulebook(self):
        self.assertIn("Rules of Unified English Braille", self.document["document"])
        self.assertIn("2024", self.document["document"])
        self.assertTrue(self.document["url"].startswith("https://iceb.org/"))

    def test_between_30_and_60_short_items_with_unique_ids(self):
        self.assertGreaterEqual(len(self.items), 30)
        self.assertLessEqual(len(self.items), 60)
        self.assertEqual(len({item["id"] for item in self.items}), len(self.items))

        for item in self.items:
            self.assertLessEqual(len(item["print"]), 40, item["print"])

    def test_every_item_cites_a_rule_and_page(self):
        for item in self.items:
            with self.subTest(item["id"]):
                self.assertRegex(item["source"]["rule"], _RULE)
                self.assertIsInstance(item["source"]["page"], int)

    def test_braille_is_cells_only(self):
        for item in self.items:
            for mode in ("braille2", "braille1"):
                if item[mode] is not None:
                    with self.subTest(item["id"], mode=mode):
                        self.assertRegex(item[mode], _CELLS)

    def test_every_item_has_at_least_one_mode_and_braille1_has_a_basis(self):
        for item in self.items:
            with self.subTest(item["id"]):
                self.assertTrue(item["braille2"] or item["braille1"])
                self.assertEqual(item["braille1"] is None, item["braille1_basis"] is None)

    def test_covers_the_requested_categories(self):
        categories = {item["category"] for item in self.items}

        for wanted in (
            "capitals",
            "all caps",
            "numbers",
            "letters next to numbers",
            "single letters",
            "contractions",
            "contraction must not apply",
            "punctuation",
            "abbreviations",
            "hyphenated",
            "lists",
        ):
            self.assertIn(wanted, categories)


if __name__ == "__main__":
    unittest.main()
