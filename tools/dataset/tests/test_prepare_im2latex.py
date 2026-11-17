import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import tempfile  # noqa: E402

from prepare_im2latex import key, topic, write_list  # noqa: E402

# im2latex style: a space between tokens.
CASES = {
    r"f ( x ) = 3 x ^ { 2 } - 2": "function_notation",
    r"0 \leq \alpha \leq \frac { 1 } { 2 }": "inequalities",
    r"x \neq 0": "inequalities",
    r"\sqrt { x + 9 } = 5": "radicals",
    r"\frac { x + 1 } { 2 } = 3": "fractions",
    r"x ^ { 2 } + 3 x - 5 = 0": "quadratic_equations",
    r"a ^ 2 + b ^ 2 = c ^ 2": "quadratic_equations",
    r"2 ^ { 5 } = 3 2": "exponents",
    r"a ^ { - 2 } b ^ { 3 }": "exponents",
    r"x ^ { 3 } + 2 x - 1": "polynomials",
    r"2 x + 5 = 1 1": "linear_equations",
}


class TopicTest(unittest.TestCase):
    def test_topics(self):
        for latex, expected in CASES.items():
            with self.subTest(latex=latex):
                self.assertEqual(topic(latex), expected)

    def test_left_is_not_an_inequality(self):
        self.assertEqual(topic(r"\left( x + 1 \right) = 2"), "linear_equations")

    def test_power_23_is_not_quadratic(self):
        self.assertEqual(topic(r"x ^ { 2 3 } = 1"), "exponents")

    def test_minus_inside_exponent_is_not_a_polynomial(self):
        self.assertEqual(topic(r"x ^ { - 2 }"), "exponents")

    def test_leak_key_ignores_spaces(self):
        self.assertEqual(key(r"x ^ { 2 } = 1"), key(r"x^{2}=1"))

    def test_label_lists_have_lf_line_ends(self):
        # PaddleOCR strips only "\n": CRLF would leave "\r" in every label.
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "val.txt"
            write_list(path, ["images/a.png\tx = 1", "images/b.png\ty = 2"])
            self.assertEqual(path.read_bytes(), b"images/a.png\tx = 1\nimages/b.png\ty = 2\n")


if __name__ == "__main__":
    unittest.main()
