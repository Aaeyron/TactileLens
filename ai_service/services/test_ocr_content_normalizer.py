import unittest

from services.ocr_content_normalizer import OcrContentNormalizer


def normalize(content, block_type):
    return OcrContentNormalizer.normalize(content=content, block_type=block_type)


class FormulaDisplayTests(unittest.TestCase):
    """Formula display text only; formula Braille is made from the raw text."""

    def test_text_groups_keep_their_spaces(self):
        self.assertEqual(
            normalize(
                r"$$ \text{Example: Perform the division.} \quad "
                r"\frac{2\sqrt{5}-4}{7} $$",
                "display_formula",
            ),
            "Example: Perform the division. (2√5 − 4)/7",
        )

    def test_other_wrappers_still_convert(self):
        for latex, expected in (
            (r"$$ \mathrm{cm}=10 $$", "cm = 10"),
            (r"$$ \mathbf{v}=(1,2) $$", "v = (1, 2)"),
            (r"$$ \operatorname{sgn}(x)=1 $$", "sgn(x) = 1"),
            (r"$$ x-5=12 $$", "x − 5 = 12"),
        ):
            with self.subTest(latex=latex):
                self.assertEqual(normalize(latex, "display_formula"), expected)


class TextPathTests(unittest.TestCase):
    """Text blocks: this output is the UEB Braille input, so it must not
    change."""

    def test_wrappers_in_text_blocks_are_still_unwrapped(self):
        self.assertEqual(
            normalize(r"Read \textbf{all} questions.", "text"),
            "Read all questions.",
        )

    def test_inline_math_in_text(self):
        self.assertEqual(
            normalize(r"Simplify $\sqrt{2}$ first.", "text"),
            "Simplify √2 first.",
        )


if __name__ == "__main__":
    unittest.main()
