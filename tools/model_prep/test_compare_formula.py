"""python -m unittest test_compare_formula (paddle_onnx_env, from tools/model_prep)."""

import unittest

from compare_formula import MEANING, SAME_MEANING, SPACING_ONLY, allowed_regressions, classify, compare
from evaluate_formula import length_group, topic_of


def row(image, target, prediction, exact, ned, topic="fractions"):
    return {"image": image, "topic": topic, "target": target, "prediction": prediction,
            "exact": str(exact), "ned": str(ned)}


def scored(image, target, prediction):
    return row(image, target, prediction, target.replace(" ", "") == prediction.replace(" ", ""), 0)


def simple_set(n_simple, n_worse, improve=0):
    """n_simple simple formulas, all right before; n_worse wrong after; improve
    extra (long) formulas wrong before and right after."""
    before, after = {}, {}
    for k in range(n_simple):
        image, target = f"s{k:03d}", f"x = {k}"
        before[image] = scored(image, target, target)
        after[image] = scored(image, target, f"x = {k + 1}" if k < n_worse else target)
    long_target = " + ".join(f"a_{{{j}}}" for j in range(12))
    for k in range(improve):
        image = f"l{k:03d}"
        before[image] = scored(image, long_target, "x")
        after[image] = scored(image, long_target, long_target)
    return before, after


class RuleTest(unittest.TestCase):
    def test_allowed_per_100_rounded_down_minimum_1(self):
        self.assertEqual(allowed_regressions(24), 1)
        self.assertEqual(allowed_regressions(100), 1)
        self.assertEqual(allowed_regressions(199), 1)
        self.assertEqual(allowed_regressions(200), 2)
        self.assertEqual(allowed_regressions(250), 2)

    def check(self, n_simple, n_worse, expected):
        before, after = simple_set(n_simple, n_worse, improve=n_worse + 1)
        rule = compare(before, after, "spacing-normalized")["rule"]
        self.assertEqual(rule["simple_items"], n_simple)
        self.assertEqual(rule["simple_regressions"], n_worse)
        self.assertEqual(rule["simple_rule_met"], expected, (n_simple, n_worse))
        self.assertEqual(rule["passed"], expected)  # overall exact is higher in these sets

    def test_rule_at_24(self):
        self.check(24, 1, True)
        self.check(24, 2, False)

    def test_rule_at_100(self):
        self.check(100, 1, True)
        self.check(100, 2, False)

    def test_rule_at_250(self):
        self.check(250, 2, True)
        self.check(250, 3, False)

    def test_needs_a_higher_exact_match(self):
        before, after = simple_set(24, 1)  # one worse, nothing better
        rule = compare(before, after, "spacing-normalized")["rule"]
        self.assertTrue(rule["simple_rule_met"])
        self.assertFalse(rule["passed"])


class ClassifyTest(unittest.TestCase):
    def test_spacing_only(self):
        self.assertEqual(classify(r"x = 1 , \quad y = 2", r"x=1,\;y=2"), SPACING_ONLY)
        self.assertEqual(classify(r"\{ F , G \} =", r"\{F,G\}\,="), SPACING_ONLY)

    def test_same_meaning_different_notation(self):
        self.assertEqual(classify(r"x \le 1", r"x\leq1"), SAME_MEANING)
        self.assertEqual(classify(r"a \neq b", r"a\ne b"), SAME_MEANING)
        self.assertEqual(classify(r"\frac { 1 } { 2 }", r"\dfrac{1}{2}"), SAME_MEANING)
        self.assertEqual(classify(r"\left( p + 1 \right) q", r"(p+1)q"), SAME_MEANING)
        self.assertEqual(classify(r"x ^ { 2 } + 1", r"x^2+1"), SAME_MEANING)
        self.assertEqual(classify(r"V = - \frac { g } { 3 2 }", r"V=-{\frac{g}{32}}"), SAME_MEANING)

    def test_meaning_changing(self):
        self.assertEqual(classify(r"d f = - [ \theta , f ]", r"d f\,--[\theta,f]"), MEANING)
        self.assertEqual(classify(r"x ^ { 1 2 }", r"x^{1}2"), MEANING)  # 12 vs 1 then 2
        self.assertEqual(classify(r"u < \pi / 2", r"u<<\pi/2"), MEANING)
        self.assertEqual(classify(r"\frac { a } { b } + c", r"\frac{a}{b+c}"), MEANING)
        self.assertEqual(classify(r"x = 1 ,", r"x=1"), MEANING)  # conservative: punctuation counts

    def test_argument_braces_are_kept(self):
        self.assertEqual(classify(r"\sqrt { x + 1 }", r"\sqrt x+1"), MEANING)
        self.assertEqual(classify(r"\sqrt [ 3 ] { 2 7 }", r"\sqrt[3]{27}"), SPACING_ONLY)

    def test_regressions_are_listed_with_their_kind(self):
        before = {"a": scored("a", r"x \le 1", r"x \le 1"), "b": scored("b", "y = 2", "y = 2")}
        after = {"a": scored("a", r"x \le 1", r"x \leq 1"), "b": scored("b", "y = 2", "y = 3")}
        regs = {r["image"]: r["kind"] for r in compare(before, after, "spacing-normalized")["regressions"]}
        self.assertEqual(regs, {"a": SAME_MEANING, "b": MEANING})


class CompareTest(unittest.TestCase):
    def test_counts_worse_and_better(self):
        before = {"a": row("a", "x = 1", "x = 1", True, 0), "b": row("b", "y = 2", "y = 3", False, 0.2)}
        after = {"a": row("a", "x = 1", "x = 7", False, 0.2), "b": row("b", "y = 2", "y = 2", True, 0)}
        result = compare(before, after)
        self.assertEqual(result["groups"]["ALL"]["got_worse"], 1)
        self.assertEqual(result["groups"]["ALL"]["got_better"], 1)
        self.assertEqual(result["groups"]["length <=20 (simple)"]["items"], 2)
        self.assertEqual([i["image"] for i in result["regressions"]], ["a"])

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
