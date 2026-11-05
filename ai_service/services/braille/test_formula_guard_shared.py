"""The online guard matches the fixture shared with the offline (Dart) guard.

fixtures/formula_guard_shared.json holds the guard's vocabulary and cases.
frontend/test/services/braille/formula_braille_guard_test.dart checks the
offline guard against the same file, so the two stay in sync.
"""

import json
import unittest
from pathlib import Path

from services.braille import formula_braille_guard as guard
from services.braille.braille_math_normalizer import BrailleMathNormalizer

FIXTURE = Path(__file__).resolve().parent / "fixtures" / "formula_guard_shared.json"


class SharedGuardFixtureTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))

    def test_vocabulary_matches_the_python_guard(self):
        vocabulary = self.fixture["vocabulary"]

        self.assertEqual(
            vocabulary["supported_commands"],
            sorted(BrailleMathNormalizer.SUPPORTED_COMMANDS),
        )
        self.assertEqual(
            vocabulary["function_names"], sorted(BrailleMathNormalizer.FUNCTION_NAMES)
        )
        self.assertEqual(
            vocabulary["supported_environments"],
            sorted(BrailleMathNormalizer.SUPPORTED_ENVIRONMENTS),
        )
        self.assertEqual(vocabulary["long_word_length"], guard.LONG_WORD_LENGTH)
        self.assertEqual(vocabulary["short_word_length"], guard.SHORT_WORD_LENGTH)
        self.assertEqual(vocabulary["short_word_limit"], guard.SHORT_WORD_LIMIT)
        self.assertEqual(vocabulary["total_word_limit"], guard.TOTAL_WORD_LIMIT)
        self.assertEqual(vocabulary["root_symbols"], guard.ROOT_SYMBOLS)
        self.assertEqual(vocabulary["root_reason"], guard.ROOT_REASON)

    def test_every_case_matches_the_python_guard(self):
        cases = self.fixture["cases"]
        self.assertGreaterEqual(len(cases), 40)

        for case in cases:
            raw = case["input"]
            with self.subTest(latex=raw):
                review = guard.review_formula(
                    raw, BrailleMathNormalizer.normalize(raw)
                )

                self.assertEqual(review.needs_review, case["needs_review"])
                self.assertEqual(list(review.categories), case["categories"])
                self.assertEqual(review.reason, case["reason"])


if __name__ == "__main__":
    unittest.main()
