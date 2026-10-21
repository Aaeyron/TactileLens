import unittest

from services.braille_math_normalizer import BrailleMathNormalizer
from services.braille_translation_service import BrailleTranslationService


def normalize(latex):
    return BrailleMathNormalizer.normalize(latex)


class BrailleMathNormalizerTests(unittest.TestCase):
    """The linear math sent to Liblouis. Whether the resulting Braille is
    correct is for a Braille expert to confirm."""

    def test_existing_behaviour_is_unchanged(self):
        for latex, expected in (
            (r"$$ x-5=12 $$", "x-5=12"),
            (r"\frac{x+1}{2}\leq\sqrt{9}", "(x+1)/(2)≤√(9)"),
            (r"x^{2}+5x+6=0", "x^2+5x+6=0"),
            (r"\left(\frac{a}{b}\right)^{2}", "((a)/(b))^2"),
            (r"\text{area}=l\times w", "area=l× w"),
        ):
            with self.subTest(latex=latex):
                self.assertEqual(normalize(latex), expected)

    def test_sized_delimiters_keep_only_the_delimiter(self):
        self.assertEqual(normalize(r"\bigg(\frac{a}{b}\bigg)^{2}"), "((a)/(b))^2")
        self.assertEqual(normalize(r"\Big[x+1\Big]"), "[x+1]")
        self.assertEqual(normalize(r"\bigl(x\bigr)"), "(x)")

    def test_spacing_commands_become_one_space(self):
        self.assertEqual(normalize(r"x=1\quad y=2"), "x=1 y=2")
        self.assertEqual(normalize(r"x=1\qquad y=2"), "x=1 y=2")

    def test_primes_become_prime_marks(self):
        self.assertEqual(normalize(r"f^{\prime}(x)=2x"), "f′(x)=2x")
        self.assertEqual(normalize(r"f^\prime(x)=2x"), "f′(x)=2x")
        self.assertEqual(normalize(r"g^{\prime\prime}(x)=6"), "g′′(x)=6")

    def test_text_wrappers_are_unwrapped(self):
        self.assertEqual(normalize(r"\textbf{A}=\mbox{area}"), "A=area")
        self.assertEqual(normalize(r"\textit{n}=3"), "n=3")

    def test_aligned_rows_become_lines(self):
        self.assertEqual(
            normalize(r"\begin{aligned}x+1&=4\\x&=3\end{aligned}"),
            "x+1=4\nx=3",
        )

    def test_other_line_environments_and_row_spacing(self):
        self.assertEqual(
            normalize(r"\begin{align*}2x&=8\\[2pt]x&=4\end{align*}"),
            "2x=8\nx=4",
        )
        self.assertEqual(
            normalize(r"\begin{gathered}x=1\\y=2\end{gathered}"),
            "x=1\ny=2",
        )

    def test_removing_alignment_never_joins_a_command_to_a_word(self):
        self.assertEqual(
            normalize(r"\begin{aligned}x&=4\quad&y&=2\end{aligned}"),
            "x=4 y=2",
        )

    def test_stacked_fractions_still_work(self):
        self.assertEqual(normalize(r"(3 \\ 4)"), "(3)/(4)")
        self.assertEqual(normalize(r"(3 \ 4)"), "(3)/(4)")

    def test_a_command_after_a_backslash_is_not_a_fraction(self):
        # Previously "(x)/(right)" and "(x)/(bigr)".
        self.assertEqual(normalize(r"\left(x\right)"), "(x)")
        self.assertEqual(normalize(r"\bigl(x\bigr)"), "(x)")


try:
    _TRANSLATOR = BrailleTranslationService()
except FileNotFoundError:
    _TRANSLATOR = None


@unittest.skipIf(_TRANSLATOR is None, "Liblouis runtime not installed")
class LiblouisSmokeTests(unittest.TestCase):
    """Liblouis runs on the new inputs. Not an accuracy check."""

    def test_aligned_rows_give_one_braille_line_each(self):
        braille = _TRANSLATOR.translate_formula(
            normalize(r"\begin{aligned}x+1&=4\\x&=3\end{aligned}")
        )

        lines = braille.split("\n")
        self.assertEqual(len(lines), 2)
        self.assertTrue(all(lines))
        # Rows translate exactly as the same equations on their own.
        self.assertEqual(lines[0], _TRANSLATOR.translate_formula("x+1=4"))
        self.assertEqual(lines[1], _TRANSLATOR.translate_formula("x=3"))

    def test_prime_and_sized_delimiters_translate(self):
        for latex in (r"f^{\prime}(x)=2x", r"\bigg(\frac{a}{b}\bigg)^{2}"):
            with self.subTest(latex=latex):
                self.assertTrue(_TRANSLATOR.translate_formula(normalize(latex)))


if __name__ == "__main__":
    unittest.main()
