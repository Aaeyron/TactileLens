"""python -m unittest test_repeated_tokens (paddle_onnx_env, from tools/model_prep)."""

import unittest

from repeated_tokens import problems


class RepeatedTokens(unittest.TestCase):
    def test_clean_reading(self):
        self.assertEqual(problems(r"\frac{1}{x^{2}}", r"\frac{1}{x^{2}}"), [])

    def test_stutter_and_carets(self):
        found = problems(r"-\frac{c}{a}", r"-\\fraccc{a}+\}fracfracfrac{^^{2}}")
        for kind in ("stutter", "^^ / __", "\\\\", "run3"):
            self.assertIn(kind, found)

    def test_braces_count_only_beyond_the_target(self):
        self.assertEqual(problems(r"\frac{1}{x^{2}}", r"\frac{1}{x^{3}}"), [])
        self.assertIn("braces", problems("m=2", r"m=\sqrt{{}}}"))

    def test_runs_in_the_target_are_allowed(self):
        self.assertEqual(problems("111x", "111x"), [])


if __name__ == "__main__":
    unittest.main()
