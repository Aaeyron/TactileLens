"""Label conventions of finalize_labels.py."""

import unittest

from finalize_labels import unify_label


class UnifyLabelTest(unittest.TestCase):
    def test_item_marker_without_text(self):
        self.assertEqual(unify_label(r"\text{b)}\sqrt{4\cdot9}"), r"b)\sqrt{4\cdot9}")
        self.assertEqual(unify_label(r"\text{(c)}x"), "(c)x")
        self.assertEqual(unify_label(r"\text{12.}x"), "12.x")

    def test_words_stay_in_text(self):
        self.assertEqual(unify_label(r"x\text{ if }y"), r"x\text{ if }y")

    def test_plain_delimiters(self):
        self.assertEqual(unify_label(r"\left(\frac{a}{b}\right)^{2}"), r"(\frac{a}{b})^{2}")
        self.assertEqual(unify_label(r"\left|x\right|>1"), "|x|>1")
        self.assertEqual(unify_label(r"\left\{x\right\}"), r"\{x\}")

    def test_other_commands_untouched(self):
        for label in (r"\leftarrow x", r"\boxed{6}", r"\bullet\quad x=1", r"\textcircled{b}\ x"):
            self.assertEqual(unify_label(label), label)


if __name__ == "__main__":
    unittest.main()
