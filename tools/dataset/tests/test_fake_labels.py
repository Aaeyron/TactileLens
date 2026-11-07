"""The fake generator labels exactly what it draws."""

import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import make_fake_intake as fake  # noqa: E402

SUP = str.maketrans("⁰¹²³⁴⁵⁶⁷⁸⁹⁻", "0123456789-")


def drawn_to_latex(drawn: str) -> str:
    """The drawn one-line formula written as LaTeX, spaces removed."""

    text = re.sub(r"[⁰¹²³⁴⁵⁶⁷⁸⁹⁻]+", lambda m: "^{" + m.group(0).translate(SUP) + "}", drawn)
    text = re.sub(r"∛(\d+)", r"\\sqrt[3]{\1}", text)
    text = re.sub(r"√(\([^)]*\))", r"\\sqrt{\1}", text)
    text = re.sub(r"√(\w+)", r"\\sqrt{\1}", text)
    return text.replace(" ", "")


class FakeLabelsTest(unittest.TestCase):
    def test_every_formula_target_is_what_is_drawn(self):
        for topic, formulas in fake.TOPICS.items():
            for latex, drawn in formulas:
                self.assertEqual(drawn_to_latex(drawn), latex.replace(" ", ""), f"{topic}: {drawn!r}")

    def test_numbered_lines_differ_per_topic(self):
        lines = {f"{n}. Show your work." for n, _ in enumerate(fake.TOPICS, 1)}
        self.assertEqual(len(lines), len(fake.TOPICS))


if __name__ == "__main__":
    unittest.main()
