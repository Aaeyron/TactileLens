"""python -m unittest test_compare_formula (paddle_onnx_env, from tools/model_prep)."""

import unittest

from compare_formula import compare
from evaluate_formula import length_group, topic_of


def row(image, target, prediction, exact, ned, topic="fractions"):
    return {"image": image, "topic": topic, "target": target, "prediction": prediction,
            "exact": str(exact), "ned": str(ned)}


class CompareTest(unittest.TestCase):
    def test_counts_worse_and_better(self):
        before = {"a": row("a", "x = 1", "x = 1", True, 0), "b": row("b", "y = 2", "y = 3", False, 0.2)}
        after = {"a": row("a", "x = 1", "x = 7", False, 0.2), "b": row("b", "y = 2", "y = 2", True, 0)}
        result = compare(before, after)
        self.assertEqual(result["groups"]["ALL"]["got_worse"], 1)
        self.assertEqual(result["groups"]["ALL"]["got_better"], 1)
        self.assertEqual(result["groups"]["length <=20 (simple)"]["items"], 2)
        self.assertEqual([i["image"] for i in result["got_worse"]], ["a"])
        self.assertTrue(result["pass_bar"]["passed"])  # 1 simple worse, overall 1 -> 1

    def test_pass_bar_fails_when_two_simple_items_get_worse(self):
        before = {k: row(k, "x = 1", "x = 1", True, 0) for k in "abc"}
        after = {"a": row("a", "x = 1", "x = 2", False, 0.2), "b": row("b", "x = 1", "x = 2", False, 0.2),
                 "c": row("c", "x = 1", "x = 1", True, 0)}
        self.assertFalse(compare(before, after)["pass_bar"]["passed"])

    def test_refuses_different_images(self):
        with self.assertRaises(SystemExit):
            compare({"a": row("a", "x", "x", True, 0)}, {"b": row("b", "x", "x", True, 0)})

    def test_refuses_different_targets(self):
        with self.assertRaises(SystemExit):
            compare({"a": row("a", "x", "x", True, 0)}, {"a": row("a", "y", "y", True, 0)})


class SpacingTest(unittest.TestCase):
    def test_spacing_commands_are_ignored(self):
        from compare_formula import spacing_scores
        self.assertTrue(spacing_scores(r"b \geq a r , \qquad a \geq 2 n", r"b\geq a r,\;a\geq2n")[0])
        self.assertTrue(spacing_scores(r"\{ F , G \} =", r"\{F,G\}\,=")[0])
        self.assertTrue(spacing_scores(r"x = 1 \ ,", r"x=1~,")[0])
        self.assertTrue(spacing_scores(r"a \hspace{2em} b", r"a b")[0])

    def test_other_differences_still_count(self):
        from compare_formula import spacing_scores
        self.assertFalse(spacing_scores(r"d f = - [ \theta , f ]", r"d f\,--[\theta,f]")[0])
        self.assertFalse(spacing_scores(r"\frac { a } { b }", r"{\frac{a}{b}}")[0])
        self.assertFalse(spacing_scores(r"x \le 1", r"x \leq 1")[0])
        self.assertFalse(spacing_scores(r"\quadrant", r"rant")[0])  # only whole commands

    def test_line_break_is_not_spacing(self):
        from compare_formula import drop_spacing
        self.assertIn(r"\\", drop_spacing(r"a \\ b"))

    def test_both_modes_reported(self):
        before = {"a": row("a", r"x = 1 \quad y", r"x=1 \quad y", True, 0)}
        after = {"a": row("a", r"x = 1 \quad y", r"x=1\;y", False, 0.1)}
        self.assertFalse(compare(before, after, "strict")["pass_bar"]["passed"] is None)
        self.assertEqual(compare(before, after, "strict")["groups"]["ALL"]["got_worse"], 1)
        self.assertEqual(compare(before, after, "spacing-normalized")["groups"]["ALL"]["got_worse"], 0)


class GroupsTest(unittest.TestCase):
    def test_topic_from_public_name(self):
        self.assertEqual(topic_of("images/fractions_pub_i2l-test_00012.png"), "fractions")
        self.assertEqual(topic_of("quadratic_equations_pub_i2l-test_00001.png"), "quadratic_equations")
        self.assertEqual(topic_of("radicals_cap_S_005.png"), "radicals")

    def test_length_groups(self):
        self.assertEqual(length_group(r"x ^ { 2 } = 4"), "length <=20 (simple)")
        self.assertEqual(length_group(" ".join("x") * 1 + " + 1" * 10), "length 21-40")
        self.assertEqual(length_group(" + 1" * 25), "length >40")


if __name__ == "__main__":
    unittest.main()
