"""Trivial filter, near-duplicate cap and PaddleOCR-VL order of filter_crop_labels.py."""

import unittest

import filter_crop_labels as fc
from evaluate_formula import TOKEN


def is_trivial(label):
    return fc.trivial(label, TOKEN.findall(label))


def row(crop, topic="linear", kind="M", source="cap", category="formula_display", weakest=0.5, tokens=5, label="x"):
    return {"crop": crop, "topic": topic, "kind": kind, "source": source, "category": category,
            "weakest": weakest, "tokens": tokens, "label": label}


class Trivial(unittest.TestCase):
    def test_single_symbols_are_trivial(self):
        for label in ("x", "5", "ab", "x y z"):
            self.assertTrue(is_trivial(label), label)

    def test_short_forms_the_user_keeps(self):
        for label in ("3x", "2y", "10ab", "x^{2}", "a_{1}", "\\frac{1}{2}", "\\sqrt{x}", "x+1"):
            self.assertFalse(is_trivial(label), label)

    def test_slash_is_an_operator(self):
        self.assertFalse(is_trivial("3/2"))

    def test_four_tokens_without_an_operator_are_trivial(self):
        self.assertTrue(is_trivial("(x)"))
        self.assertFalse(is_trivial("x=y"))


class NearDuplicates(unittest.TestCase):
    def test_keeps_three_per_topic_cap_first(self):
        rows = [row(f"s{i}", source="ss", weakest=0.9, label="x+1") for i in range(3)] + [row("c", label="x+1")]
        dropped = fc.keep_near_duplicates(rows, lambda s: s)
        self.assertEqual(len(dropped), 1)
        self.assertNotIn("c", dropped)

    def test_other_topic_is_separate(self):
        rows = [row(f"a{i}", label="x+1") for i in range(3)] + [row("b", topic="radicals", label="x+1")]
        self.assertEqual(fc.keep_near_duplicates(rows, lambda s: s), set())


class Order(unittest.TestCase):
    def test_round_robin_and_weakest_first(self):
        rows = [row("l1", weakest=0.9), row("l2", weakest=0.2), row("l3", source="ss", weakest=0.1),
                row("r1", topic="radicals")]
        self.assertEqual([r["crop"] for r in fc.vl_order(rows)], ["l2", "r1", "l1", "l3"])

    def test_display_before_inline(self):
        rows = [row("i", category="formula_inline", weakest=0.1), row("d", weakest=0.9)]
        self.assertEqual([r["crop"] for r in fc.vl_order(rows)], ["d", "i"])


class Interleave(unittest.TestCase):
    def test_forty_percent_failures_until_they_run_out(self):
        planned, failures = [f"p{i}" for i in range(10)], [f"f{i}" for i in range(3)]
        out = fc.interleave(planned, failures)
        self.assertEqual(sum(x.startswith("f") for x in out[:5]), 2)
        self.assertEqual(sorted(out), sorted(planned + failures))

    def test_only_failures_left(self):
        self.assertEqual(fc.interleave([], ["f1", "f2"]), ["f1", "f2"])


if __name__ == "__main__":
    unittest.main()
