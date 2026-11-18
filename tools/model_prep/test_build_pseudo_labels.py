"""python -m unittest test_build_pseudo_labels (paddle_onnx_env, from tools/model_prep)."""

import unittest

from build_pseudo_labels import basic_problem, choose, clean_reading
from compare_formula import notation_key


def block(text, label="formula"):
    return [{"label": label, "content": text}]


class ChecksTest(unittest.TestCase):
    def test_clean_reading(self):
        self.assertEqual(clean_reading(" $$ x^{2}+1 $$ "), "x^{2}+1")

    def test_accepts_one_formula(self):
        self.assertIsNone(basic_problem(block(r"$$ 7.\quad\frac{x}{2}=4 $$")))

    def test_rejections(self):
        cases = {
            "not exactly one block": block("x") * 2,
            "not a formula block": block("x", "text"),
            "empty": block("$$ $$"),
            "non-ASCII characters": block("x=？"),
            "[object Object]": block(r"\sqrt[object Object]{2}"),
            "several lines": block(r"a\\b"),
            "unbalanced braces": block(r"\frac{1}{2"),
            "words in the formula": block(r"\text{solve} x=1"),
            "more than 80 tokens": block("+".join("x" * 50)),
            "repeated token": block("1" * 9),
        }
        for reason, blocks in cases.items():
            self.assertEqual(basic_problem(blocks), reason)

    def test_escaped_braces_are_not_counted(self):
        self.assertIsNone(basic_problem(block(r"\{x\}=1")))


class ChooseTest(unittest.TestCase):
    def test_agreed_uses_unified_vl_label(self):
        row = choose("a.png", r"\left(x\right)\leq 1", block(r"$$ \left( x \right) \le 1 $$"), set())
        self.assertEqual(row["group"], "agreed")
        self.assertNotIn(r"\left", row["label"])

    def test_disagreement_is_teacher(self):
        self.assertEqual(choose("a.png", "x+1", block("x+2"), set())["group"], "teacher")

    def test_failed_check_is_rejected(self):
        self.assertEqual(choose("a.png", "x", block(r"a\\b"), set())["group"], "rejected")

    def test_missing_reading(self):
        self.assertEqual(choose("a.png", None, block("x"), set())["group"], "no reading")
        self.assertEqual(choose("a.png", "x", None, set())["group"], "no reading")

    def test_leak_guard_uses_notation_key(self):
        held = {notation_key(r"x\le 1")}
        self.assertEqual(choose("a.png", "y", block(r"x\leq 1"), held)["group"], "leak guard")


if __name__ == "__main__":
    unittest.main()
