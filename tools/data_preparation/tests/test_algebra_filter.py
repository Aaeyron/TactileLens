import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from algebra_filter import reason_to_drop  # noqa: E402

KEEP = [
    r"\frac{x+1}{2}=3",
    r"x^{2}+3x-5=0",
    r"\sqrt{x+9}=5",
    r"\sqrt[3]{27}=3",
    r"2x+5 \leq 11",
    r"f(x)=3x^{2}-2",
    r"a^{-2}b^{3}",
    r"x=\frac{-b \pm \sqrt{b^{2}-4ac}}{2a}",
    r"(x+2)(x-3)=x^{2}-x-6",
    r"x_{1}+x_{2}=7",
]
DROP = {
    r"\int_{0}^{1} x^{2} dx": "integral",
    r"\sum_{i=1}^{n} i": "sum",
    r"\begin{pmatrix} 1 & 0 \end{pmatrix}": "environment",
    r"\mathbf{F}=m\mathbf{a}": "font",
    r"\widetilde \gamma _ { \mathrm { h o p f } }": "command \\widetilde",
    r"x + y": "no algebra feature",
    r"\lim_{x \to 0} f(x)": "limit",
    r"\hat{x}=2": "accent",
}


class AlgebraFilterTest(unittest.TestCase):
    def test_algebra_is_kept(self):
        for latex in KEEP:
            self.assertIsNone(reason_to_drop(latex), latex)

    def test_beyond_algebra_is_dropped(self):
        for latex, why in DROP.items():
            self.assertEqual(reason_to_drop(latex), why, latex)

    def test_long_formulas_are_dropped(self):
        self.assertEqual(reason_to_drop("+".join(["x^{2}"] * 20) + "=0"), "too long")


if __name__ == "__main__":
    unittest.main()
