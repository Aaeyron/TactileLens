import unittest

from services.braille.braille_math_normalizer import BrailleMathNormalizer
from services.braille.braille_translation_service import BrailleTranslationService


def normalize(latex):
    return BrailleMathNormalizer.normalize(latex)


# (Unicode superscript form, the same expression in caret form). The same
# cases are in the Kotlin BrailleMathNormalizerTest.
SUPERSCRIPT_CASES = (
    ("x²", r"x^{2}"),
    ("xⁿ", r"x^{n}"),
    ("(a+b)²", r"(a+b)^{2}"),
    ("10⁻³", r"10^{-3}"),
    ("2x³y²", r"2x^{3}y^{2}"),
    ("x² + 3x - 5", r"x^{2} + 3x - 5"),
    ("a²b³ = c²", r"a^{2}b^{3} = c^{2}"),
    ("xⁿ⁺¹", r"x^{n+1}"),
    ("x⁰ + y¹ + z⁴⁵⁶⁷⁸⁹", r"x^{0} + y^{1} + z^{456789}"),
)


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

    def test_unicode_superscripts_become_the_caret_form(self):
        for unicode_form, expected in (
            ("x²", "x^2"),
            ("xⁿ", "x^n"),
            ("(a+b)²", "(a+b)^2"),
            ("10⁻³", "10^-3"),
            ("2x³y²", "2x^3y^2"),
            ("a²b³ = c²", "a^2b^3 = c^2"),
            # Grouped like x^{n+1}; see the expert note on baseline return.
            ("xⁿ⁺¹", "x^n+1"),
        ):
            with self.subTest(unicode_form=unicode_form):
                self.assertEqual(normalize(unicode_form), expected)

    def test_unicode_superscripts_match_their_caret_form(self):
        for unicode_form, caret_form in SUPERSCRIPT_CASES:
            with self.subTest(unicode_form=unicode_form):
                self.assertEqual(normalize(unicode_form), normalize(caret_form))

    def test_spaces_around_operators_are_removed(self):
        for text, expected in (
            ("x + 3x - 5", "x+3x-5"),
            ("x - 5", "x-5"),
            ("x- 5", "x-5"),
            ("x -5", "x-5"),
            ("x = -5", "x=-5"),
            ("x − 5", "x−5"),
            ("x != 5", "x!=5"),
            ("x <= 5", "x<=5"),
            ("2 × 3 ÷ 6 · 1", "2×3÷6·1"),
            ("(x) / (2)", "(x)/(2)"),
            ("- 5 + x", "-5+x"),
        ):
            with self.subTest(text=text):
                self.assertEqual(BrailleMathNormalizer.tighten_operators(text), expected)

    def test_a_sign_after_a_separator_keeps_its_place(self):
        # Table cells are joined with "; ", so "-3" starts a cell.
        self.assertEqual(
            BrailleMathNormalizer.tighten_operators("Row 1: x; -3"), "Row 1: x; -3"
        )
        self.assertEqual(BrailleMathNormalizer.tighten_operators("a, - 3"), "a, -3")

    def test_line_breaks_between_rows_are_kept(self):
        self.assertEqual(
            BrailleMathNormalizer.tighten_operators("x + 1 = 4\nx = 3"), "x+1=4\nx=3"
        )

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

    def test_unicode_superscripts_give_the_caret_braille_and_no_escape(self):
        # Before, "x²" reached Liblouis as is and came out as the escape
        # '\x00b2' written in cells (⠄⡳⠭...).
        for unicode_form, caret_form in SUPERSCRIPT_CASES:
            with self.subTest(unicode_form=unicode_form):
                braille = _TRANSLATOR.translate_formula(normalize(unicode_form))

                self.assertEqual(
                    braille, _TRANSLATOR.translate_formula(normalize(caret_form))
                )
                self.assertNotIn("⡳", braille)

    def test_spaced_operators_give_the_unspaced_braille(self):
        # Before, "x + 3x - 5" lost its minus: ⠰⠭⠀⠬⠀⠼⠒⠰⠭⠀⠼⠢.
        for spaced, unspaced in (
            ("x + 3x - 5", "x+3x-5"),
            ("x^2 + 3x - 5", "x^2+3x-5"),
            ("x + 3x − 5", "x+3x-5"),
            ("x - 5", "x-5"),
            ("x = -5", "x=-5"),
            ("x != 5", "x!=5"),
            ("x ≠ 5", "x≠5"),
            ("2 × 3", "2×3"),
        ):
            with self.subTest(spaced=spaced):
                self.assertEqual(
                    _TRANSLATOR.translate_formula(spaced),
                    _TRANSLATOR.translate_formula(unspaced),
                )

        self.assertEqual(_TRANSLATOR.translate_formula("x + 3x - 5"), "⠰⠭⠬⠼⠒⠰⠭⠤⠼⠢")

    def test_unicode_minus_matches_the_ascii_minus(self):
        self.assertEqual(
            _TRANSLATOR.translate_formula("x − 5"), _TRANSLATOR.translate_formula("x-5")
        )

    def test_prime_and_sized_delimiters_translate(self):
        for latex in (r"f^{\prime}(x)=2x", r"\bigg(\frac{a}{b}\bigg)^{2}"):
            with self.subTest(latex=latex):
                self.assertTrue(_TRANSLATOR.translate_formula(normalize(latex)))


if __name__ == "__main__":
    unittest.main()
