import unittest

from services.braille_math_normalizer import BrailleMathNormalizer
from services.formula_braille_guard import (
    ALIGNMENT,
    ENGLISH_TEXT,
    LEFTOVER_MARKUP,
    UNSUPPORTED_LATEX,
    review_formula,
)


def review(latex):
    return review_formula(latex, BrailleMathNormalizer.normalize(latex))


class FormulaBrailleGuardTests(unittest.TestCase):
    def test_worked_example_with_explanations_is_held(self):
        # Shaped like a two-column worked example read as one formula.
        latex = (
            r" $$ \begin{aligned}&2y+y(4-y)\Big(\frac{y}{2}\Big)when y=-3"
            r"\quad&Put -3 in for y\\&(-3)+(-3)(7)\quad&Multiply first"
            r"\\&-24\quad&Answer\end{aligned} $$ "
        )

        result = review(latex)

        # \Big, \quad and aligned are supported; the English words are not.
        self.assertTrue(result.needs_review)
        self.assertEqual(result.categories, (ENGLISH_TEXT,))
        # "in" and single letters are too short to count.
        self.assertEqual(
            result.reason,
            "contains English text (6 words: when, Put, for, Multiply, ...)",
        )

    def test_each_unsupported_construct_is_held(self):
        for latex, expected in (
            (r"\hat{x}=2", r"\hat"),
            (r"\overline{AB}=3", r"\overline"),
            (r"\begin{cases}x=1\end{cases}", "cases environment"),
            (r"\begin{pmatrix}1&2\end{pmatrix}", "pmatrix environment"),
        ):
            with self.subTest(latex=latex):
                result = review(latex)

                self.assertTrue(result.needs_review)
                self.assertIn(UNSUPPORTED_LATEX, result.categories)
                self.assertIn(expected, result.reason)

    def test_newly_supported_constructs_are_translated(self):
        for latex in (
            r"\Big(x+1\Big)^{2}",
            r"\bigg(\frac{a}{b}\biggr)",
            r"x=1\quad y=2",
            r"x=1\qquad y=2",
            r"f^{\prime}(x)=2x",
            r"g^{\prime\prime}(x)=6",
            r"\textbf{A}=\mbox{area}",
            r"\begin{aligned}x+1&=4\\x&=3\end{aligned}",
            r"\begin{align*}2x&=8\\x&=4\end{align*}",
            r"\begin{gathered}x=1\\y=2\end{gathered}",
        ):
            with self.subTest(latex=latex):
                self.assertFalse(review(latex).needs_review)

    def test_bare_alignment_markup_is_held(self):
        for latex in (r"x+1&=4", r"x=1\\y=2"):
            with self.subTest(latex=latex):
                result = review(latex)

                self.assertTrue(result.needs_review)
                self.assertIn(ALIGNMENT, result.categories)

    def test_supported_formulas_are_translated(self):
        for latex in (
            r"$$ x-5=12 $$",
            r"$$ (x+4)(x-2)=10 $$",
            r"$$ x^{2}+5x+6=0 $$",
            r"\frac{x+1}{2}\leq\sqrt{9}",
            r"\text{area}=l\times w",
            r"\sin x+\cos x=1",
            r"\log_{2}8=3",
            r"\left(\frac{a}{b}\right)^{2}",
            r"\left( \begin{array}{c} 3 \\ 4 \end{array} \right)",
            r"(3 \\ 4)",
        ):
            with self.subTest(latex=latex):
                self.assertFalse(review(latex).needs_review)

    def test_one_long_word_outside_text_is_held(self):
        result = review(r"x=2 when y=3")

        self.assertTrue(result.needs_review)
        self.assertEqual(result.categories, (ENGLISH_TEXT,))
        self.assertIn("(1 words: when)", result.reason)

    def test_one_three_letter_word_is_allowed(self):
        # A single short letter group can be a product of variables.
        self.assertFalse(review(r"abc=6").needs_review)

    def test_two_three_letter_words_are_held(self):
        result = review(r"abc+xyz=6")

        self.assertTrue(result.needs_review)
        self.assertEqual(result.categories, (ENGLISH_TEXT,))

    def test_words_inside_text_count_only_toward_the_total(self):
        five_words = r"\text{the total cost per box}=c"
        six_words = r"\text{the total cost per box now}=c"

        self.assertFalse(review(five_words).needs_review)
        self.assertTrue(review(six_words).needs_review)

    def test_two_letter_groups_never_count(self):
        self.assertFalse(review(r"dy+dx=xy").needs_review)

    def test_leftover_markup_is_held(self):
        result = review_formula(r"x+1=2", "x+1{=2")

        self.assertTrue(result.needs_review)
        self.assertEqual(result.categories, (LEFTOVER_MARKUP,))

    def test_empty_content_needs_no_review(self):
        self.assertFalse(review_formula("", "").needs_review)
        self.assertFalse(review_formula("   ", "").needs_review)


if __name__ == "__main__":
    unittest.main()
