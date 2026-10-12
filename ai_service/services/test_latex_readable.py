import unittest

from services.latex_readable_converter import (
    contains_latex,
    ensure_readable,
    latex_to_readable,
)


class LatexToReadableTests(unittest.TestCase):
    def test_empty_input_returns_empty_string(self):
        self.assertEqual(latex_to_readable(""), "")
        self.assertEqual(latex_to_readable("   "), "")

    def test_square_root_in_equation(self):
        self.assertEqual(latex_to_readable(r"\sqrt{x+9}=5"), "√(x + 9) = 5")

    def test_fraction_with_polynomials(self):
        self.assertEqual(
            latex_to_readable(r"\frac{3x+1}{x-2}"),
            "(3x + 1)/(x − 2)",
        )

    def test_simple_fraction_then_variable(self):
        self.assertEqual(latex_to_readable(r"\frac{1}{2}x"), "1/2x")

    def test_symbolic_exponent_keeps_parentheses(self):
        self.assertEqual(latex_to_readable("x^{n+1}"), "x^(n + 1)")

    def test_integer_exponents_become_superscripts(self):
        self.assertEqual(
            latex_to_readable("x^2 + y^2 = r^2"),
            "x² + y² = r²",
        )

    def test_subscripts_become_subscripts(self):
        self.assertEqual(latex_to_readable("x_{1}+x_{2}"), "x₁ + x₂")

    def test_inequality_with_minus_and_leq(self):
        self.assertEqual(latex_to_readable(r"3x-4\leq11"), "3x − 4 ≤ 11")

    def test_indexed_root_with_superscript_radicand(self):
        self.assertEqual(
            latex_to_readable(r"\sqrt[11]{x^{11}}=x"),
            "¹¹√(x¹¹) = x",
        )

    def test_plus_minus_then_root(self):
        self.assertEqual(latex_to_readable(r"\pm\sqrt{2}"), "±√2")

    def test_not_equal(self):
        self.assertEqual(latex_to_readable(r"x \neq 0"), "x ≠ 0")

    def test_greek_letters(self):
        self.assertEqual(latex_to_readable(r"\alpha + \beta"), "α + β")

    def test_absolute_value_keeps_bars(self):
        self.assertEqual(latex_to_readable("|x-3| = 5"), "|x − 3| = 5")

    def test_left_and_right_delimiters_are_removed(self):
        self.assertEqual(latex_to_readable(r"\left( x + 1 \right)"), "(x + 1)")

    def test_text_wrapper_keeps_words(self):
        self.assertEqual(latex_to_readable(r"\text{ cm}"), "cm")

    def test_infinity(self):
        self.assertEqual(latex_to_readable(r"\infty"), "∞")

    def test_unknown_command_keeps_its_argument(self):
        self.assertEqual(latex_to_readable(r"\lefted{x}"), "x")

    def test_output_never_contains_backslash_or_dollar(self):
        inputs = [
            r"\sqrt{x}",
            r"\frac{a}{b}",
            r"\hat{x}",
            r"x \cdot y",
            r"\begin{cases} x \end{cases}",
            r"\unknowncmd{y}",
            r"$$x^{2}$$",
        ]

        for latex in inputs:
            with self.subTest(latex=latex):
                result = latex_to_readable(latex)
                self.assertNotIn("\\", result)
                self.assertNotIn("$", result)


class ContainsLatexTests(unittest.TestCase):
    def test_detects_commands(self):
        self.assertTrue(contains_latex(r"\sqrt{2}"))

    def test_plain_text_has_no_latex(self):
        self.assertFalse(contains_latex("costs 5 pesos"))


class EnsureReadableTests(unittest.TestCase):
    def test_text_without_latex_is_unchanged(self):
        self.assertEqual(ensure_readable("costs $5 today"), "costs $5 today")

    def test_inline_dollar_math_is_converted(self):
        self.assertEqual(
            ensure_readable(r"The answer is $\sqrt{2}$ units"),
            "The answer is √2 units",
        )

    def test_bare_latex_in_text_is_converted(self):
        self.assertEqual(
            ensure_readable(r"Solve \frac{x}{2} = 3"),
            "Solve x/2 = 3",
        )

    def test_empty_text_is_unchanged(self):
        self.assertEqual(ensure_readable(""), "")


if __name__ == "__main__":
    unittest.main()