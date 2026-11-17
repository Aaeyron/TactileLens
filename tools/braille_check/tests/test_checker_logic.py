"""The checker's own logic, without Liblouis (fake paths and translator)."""

import unittest

from tools.braille_check import check_reference, paths
from tools.braille_check.baseline35 import compare


class ClassifyTests(unittest.TestCase):
    def test_match(self):
        self.assertEqual(check_reference.classify("⠁", "⠁", "⠃"), "match")

    def test_our_code_when_liblouis_alone_is_right(self):
        self.assertEqual(check_reference.classify("⠁", "⠃", "⠁"), "our code")

    def test_liblouis_when_liblouis_alone_is_wrong_too(self):
        self.assertEqual(check_reference.classify("⠁", "⠃", "⠃"), "Liblouis")


class CheckTests(unittest.TestCase):
    def test_runs_every_path_and_skips_missing_modes(self):
        items = [
            {"id": "a", "category": "c", "print": "x", "braille2": "⠭", "braille1": None,
             "source": {"rule": "1.1.1", "page": 1}},
            {"id": "b", "category": "c", "print": "y", "braille2": "⠽", "braille1": "⠽",
             "source": {"rule": "1.1.1", "page": 1}},
        ]
        braille = {"x": "⠭", "y": "⠽"}
        fake_paths = {key: (lambda text: braille[text]) for key in paths.PATHS}

        results = check_reference.check(
            items, fake_paths, translate=lambda text, table: braille[text]
        )

        self.assertEqual(len(results["braille2/offline"]), 2)
        self.assertEqual(len(results["braille1/online"]), 1)
        self.assertTrue(
            all(row["result"] == "match" for rows in results.values() for row in rows)
        )


class TextPrepTests(unittest.TestCase):
    """The port of the app's _reflowText and _normalizeContent."""

    def test_dashes_become_hyphens_on_the_phone(self):
        self.assertEqual(paths.offline_text("4–3 and −5 — done "), "4-3 and -5 - done")

    def test_list_items_keep_their_lines_and_other_lines_join(self):
        self.assertEqual(
            paths.offline_text("Directions:\n1. Read it.\n2. Show your\nwork."),
            "Directions:\n1. Read it.\n2. Show your work.",
        )

    def test_a_hyphen_at_a_line_end_joins_a_lowercase_word(self):
        self.assertEqual(paths.offline_text("equa-\ntion"), "equation")

    def test_lines_of(self):
        self.assertEqual(paths.lines_of(" a \n\n b "), ["a", "b"])


class CompareTests(unittest.TestCase):
    def test_reports_each_kind_of_change(self):
        before = {
            "k1": {"normalized": "a", "braille": "⠁", "held": False},
            "k2": {"normalized": "b", "braille": "⠃", "held": False},
            "k3": {"normalized": "c", "braille": "", "held": True},
        }
        after = {
            "k1": {"normalized": "a", "braille": "⠁⠁", "held": False},
            "k2": {"normalized": "b", "braille": "", "held": True},
            "k3": {"normalized": "c!", "braille": "⠉", "held": False},
        }

        self.assertEqual(
            compare(before, after),
            {
                "braille_changed": ["k1"],
                "newly_held": ["k2"],
                "no_longer_held": ["k3"],
                "text_changed": ["k3"],
            },
        )

    def test_identical_runs_have_no_changes(self):
        run = {"k": {"normalized": "a", "braille": "⠁", "held": False}}
        self.assertEqual(sum(map(len, compare(run, run).values())), 0)

    def test_different_blocks_are_an_error(self):
        with self.assertRaises(ValueError):
            compare({"a": {}}, {"b": {}})


class PrepFixtureTests(unittest.TestCase):
    def test_fixture_is_up_to_date(self):
        import json

        from tools.braille_check.make_prep_fixture import FIXTURE, cases

        stored = json.loads(FIXTURE.read_text(encoding="utf-8"))["cases"]
        self.assertEqual(stored, cases(), "Run python -m tools.braille_check.make_prep_fixture")


if __name__ == "__main__":
    unittest.main()
