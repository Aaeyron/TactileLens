import unittest

from services.latex_readable_converter import (
    contains_latex,
    ensure_readable,
    latex_to_readable,
    readable_with_prose,
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

    def test_prime_is_written_after_the_letter(self):
        self.assertEqual(latex_to_readable(r"f^{\prime}(x)=2x"), "f′(x) = 2x")
        self.assertEqual(latex_to_readable(r"g^{\prime\prime}(x)"), "g′′(x)")

    def test_aligned_rows_keep_words_after_spacing(self):
        # "\quad&Add" must not turn into an unknown command.
        self.assertEqual(
            latex_to_readable(
                r"\begin{aligned}x+1&=4\quad&\text{Add}\\x&=3\end{aligned}"
            ),
            "x + 1 = 4 Add\nx = 3",
        )

    def test_sized_delimiters_are_dropped(self):
        self.assertEqual(latex_to_readable(r"\bigg(\frac{a}{b}\bigg)^{2}"), "(a/b)²")

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


class ReadableWithProseTests(unittest.TestCase):
    """Display text for formula blocks that mix words and math."""

    def test_instruction_and_fraction(self):
        self.assertEqual(
            readable_with_prose(
                r"$$ Example: Perform the division and simplify your answer. "
                r"\frac{2\sqrt{5}-4}{7} $$"
            ),
            "Example: Perform the division and simplify your answer. (2√5 − 4)/7",
        )

    def test_one_word_label(self):
        self.assertEqual(
            readable_with_prose(r"$$ Divide: \frac{2\sqrt{5}-4}{7} $$"),
            "Divide: (2√5 − 4)/7",
        )

    def test_word_between_equations_keeps_its_spaces(self):
        self.assertEqual(readable_with_prose(r"$$ x=2 when y=3 $$"), "x = 2 when y = 3")

    def test_single_letters_stay_math(self):
        self.assertEqual(
            readable_with_prose(r"$$ simplify a fraction \frac{4}{8} $$"),
            "simplify a fraction 4/8",
        )

    def test_existing_text_groups_and_commands_are_untouched(self):
        self.assertEqual(
            readable_with_prose(
                r"$$ \text{Example: Perform the division.} \quad "
                r"\frac{2\sqrt{5}-4}{7} $$"
            ),
            "Example: Perform the division. (2√5 − 4)/7",
        )
        self.assertEqual(readable_with_prose(r"$$ \sin x+\cos x=1 $$"), "sin x + cos x = 1")

    def test_aligned_rows_stay_on_their_lines(self):
        self.assertEqual(
            readable_with_prose(
                r"$$ \begin{aligned}&2y+3\quad&Add three\\&5\quad&Answer"
                r"\end{aligned} $$"
            ),
            "2y + 3 Add three\n5 Answer",
        )

    def test_plain_math_is_unchanged(self):
        for latex in (r"$$ x-5=12 $$", r"\frac{x+1}{2}\leq\sqrt{9}"):
            with self.subTest(latex=latex):
                self.assertEqual(readable_with_prose(latex), latex_to_readable(latex))

    def test_inline_math_delimiters_are_not_shown(self):
        self.assertEqual(
            readable_with_prose(r"Read \textbf{all} and simplify $\sqrt{2}$ first."),
            "Read all and simplify √2 first.",
        )

    def test_empty(self):
        self.assertEqual(readable_with_prose(""), "")
        self.assertEqual(readable_with_prose("   "), "")


if __name__ == "__main__":
    unittest.main()