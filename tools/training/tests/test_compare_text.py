"""The adoption-rule classification of compare_text.py."""

import unittest

from compare_text import allowed, braille_kind, classify, meaning_key


class Classify(unittest.TestCase):
    def test_wrong_number_is_meaning(self):
        self.assertEqual(classify("x = 30", "x = 30", "x = 80"), "meaning-changing")

    def test_dropped_minus_is_meaning(self):
        self.assertEqual(classify("10⁻³", "10⁻³", "10³"), "meaning-changing")
        self.assertEqual(meaning_key("a -5"), "a-5")

    def test_dash_for_minus_is_kept_as_minus(self):
        self.assertEqual(meaning_key("3 — 5√3"), "3-5√3")
        self.assertEqual(classify("3 - 5", "3 - 5", "3 5"), "meaning-changing")

    def test_punctuation_and_spacing_only(self):
        self.assertEqual(classify("In this case, 30.", "In this case, 30.", "In this case 30"),
                         "spacing/punctuation only")
        self.assertEqual(classify("the LCM", "the LCM", "theLCM"), "spacing/punctuation only")

    def test_better_and_same(self):
        self.assertEqual(classify("x² + 1", "x2 + 1", "x² + 1"), "better")
        self.assertEqual(classify("abc", "abd", "abd"), "same")

    def test_braille_split(self):
        self.assertEqual(braille_kind("of 2, we", "of 2, we", "of 2. we"), "punctuation (changes the Braille)")
        self.assertEqual(braille_kind("3 – Fraction", "3 – Fraction", "3-Fraction"), "punctuation (changes the Braille)")
        self.assertEqual(braille_kind("a's (6)", "a's (6)", "a's(6)"), "spacing only")

    def test_allowed(self):
        self.assertEqual(allowed(100), 2)
        self.assertEqual(allowed(30), 1)


if __name__ == "__main__":
    unittest.main()
