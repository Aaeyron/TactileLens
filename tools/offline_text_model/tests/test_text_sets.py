"""to_charset, draw and the line filter of the Track B own-data tools."""

import unittest

from common import load_character_list
from cut_text_lines import formula_share, keep_line
from text_sets import draw, to_charset

CHARS = set(load_character_list())


class ToCharset(unittest.TestCase):
    def check(self, text, expected):
        self.assertEqual(to_charset(text, CHARS)[0], expected, text)

    def test_plain_text_unchanged(self):
        self.check("Multiply every term by the LCM.", "Multiply every term by the LCM.")

    def test_exponents_become_superscripts(self):
        self.check("$x^{2}+3x^2-10^{-3}$", "x²+3x²-10⁻³")
        self.check(r"so \(a^{n}\) grows", "so aⁿ grows")

    def test_dollar_sign_kept(self):
        self.check("a maximum of $87.50.", "a maximum of $87.50.")
        self.check("b)  $ 3^{2}(y)^{2} $", "b) 3²(y)²")
        self.check("costs $5 and $ x^{2} $", "costs $5 and x²")
        self.check(" $$ 2 x^{2} \\sqrt{5} $$ ", "2 x² √5")

    def test_symbols(self):
        self.check(r"$x \leq 5$ and $y \geq 2$", "x ≤ 5 and y ≥ 2")
        self.check(r"$\sqrt{x}$", "√x")

    def test_refuses_what_it_cannot_write(self):
        for text, reason in ((r"$\frac{1}{2}$", "fraction"), ("$a_{1}$", "subscript"),
                             ("$x^{y}$", "exponent not in the dictionary (y)"),
                             (r"$\sqrt{x+1}$", "root over several characters"), ("two\nlines", "several lines")):
            self.assertEqual(to_charset(text, CHARS), (None, reason), text)


class Draw(unittest.TestCase):
    def rows(self, image, n, topic="linear", source="ss"):
        return [{"line": f"{image}_{i}", "source_image": image, "topic": topic, "source": source} for i in range(n)]

    def test_at_most_three_per_image_and_spread(self):
        rows = self.rows("a", 10) + self.rows("b", 10, topic="radicals")
        out = draw(rows, 6, seed=1)
        self.assertEqual(len(out), 6)
        self.assertEqual(sum(r["source_image"] == "a" for r in out), 3)

    def test_fewer_when_images_run_out(self):
        self.assertEqual(len(draw(self.rows("a", 10), 5, seed=1)), 3)


class LineFilter(unittest.TestCase):
    def test_inside_formula(self):
        self.assertEqual(formula_share([0, 0, 10, 10], [[0, 0, 10, 5]]), 0.5)
        self.assertEqual(keep_line("T", 20, 100, "text", 0.5), "inside a formula")

    def test_m_needs_a_word(self):
        self.assertEqual(keep_line("M", 20, 100, "a 4x", 0.0), "M line without a word")
        self.assertIsNone(keep_line("M", 20, 100, "Simplify each", 0.0))
        self.assertIsNone(keep_line("T", 20, 100, "4x", 0.0))


if __name__ == "__main__":
    unittest.main()
