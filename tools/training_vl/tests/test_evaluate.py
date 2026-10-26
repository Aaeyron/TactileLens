"""Tests for evaluate_vl.py with the mock engine (no Paddle, no network).

Run from tools/training_vl:  python -m unittest discover -s tests -t .
"""

import csv
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))

import evaluate_vl  # noqa: E402


def run(*args):
    return subprocess.run([sys.executable, "-B", *args], cwd=HERE, capture_output=True, text=True, encoding="utf-8")


class HelperTests(unittest.TestCase):
    def test_prediction_text_picks_the_blocks_for_the_task(self):
        blocks = [{"label": "text", "content": "Solve:"}, {"label": "display_formula", "content": "$$x^{2}$$"},
                  {"label": "image", "content": '<img src="http://example.invalid/a.png">'},
                  {"label": "table", "content": "<table><tr><td>1</td></tr></table>"}]
        self.assertEqual(evaluate_vl.prediction_text("formula", blocks), "$$x^{2}$$")
        self.assertIn("<table>", evaluate_vl.prediction_text("table", blocks))
        self.assertEqual(evaluate_vl.prediction_text("text", blocks), "Solve:\n$$x^{2}$$")
        # No formula block: everything (except images) is used.
        self.assertEqual(evaluate_vl.prediction_text("formula", [{"label": "text", "content": "x^{2}"}]), "x^{2}")

    def test_otsl_to_html_keeps_cell_text(self):
        self.assertEqual(evaluate_vl.otsl_to_html("<fcel>x<fcel>y<nl><fcel>1<ecel><nl>"),
                         "<table><tr><td>x</td><td>y</td></tr><tr><td>1</td><td></td></tr></table>")

    @unittest.skipIf(evaluate_vl.GUARD_ERROR, "formula guard not importable")
    def test_guard_holds_roots_and_passes_plain_formulas(self):
        self.assertTrue(evaluate_vl.guard_holds("formula", r"\sqrt{x+9}=5"))
        self.assertFalse(evaluate_vl.guard_holds("formula", r"x^{2}+3x-5"))
        self.assertIsNone(evaluate_vl.guard_holds("text", "Solve for x"))


class MockEngineTests(unittest.TestCase):
    def test_scores_per_group(self):
        with tempfile.TemporaryDirectory() as tmp:
            data, sft, out = Path(tmp) / "data", Path(tmp) / "sft", Path(tmp) / "out"
            run("make_fake_dataset.py", "--out", str(data))
            converted = run("convert_to_sft.py", "--data", str(data), "--labels", str(data / "labels.csv"),
                            "--out", str(sft), "--skip-recognizer-eval-check")
            self.assertEqual(converted.returncode, 0, converted.stdout)
            # eval: exponents_cap_S_003 (10^{-3}), radicals_cap_S_002 (\sqrt[3]{27}=3),
            # tables_cap_M_002, negative_exponents_ss_S_001 (y^{-2})
            mock = {
                "exponents_cap_S_003.png": "$$ 10^{-3} $$",                          # right, other delimiters
                "radicals_cap_S_002.png": r"\sqrt[3]{27}=3",                         # right
                "tables_cap_M_002.png": "<table><tr><td>n</td><td>n²</td></tr><tr><td>2</td><td>4</td></tr></table>",
                "negative_exponents_ss_S_001.png": "y^{2}",                         # wrong
            }
            (Path(tmp) / "mock.json").write_text(json.dumps(mock, ensure_ascii=False), encoding="utf-8")
            result = run("evaluate_vl.py", "--eval", str(sft), "--engine", "mock",
                         "--mock-file", str(Path(tmp) / "mock.json"), "--out-root", str(out))
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            [folder] = list(out.iterdir())
            self.assertIn("_mock_", folder.name)
            with open(folder / "results.csv", encoding="utf-8") as handle:
                summary = {(r["group"], r["value"]): r for r in csv.DictReader(handle)}
            self.assertEqual(summary[("all", "all")]["count"], "4")
            self.assertEqual(summary[("all", "all")]["exact_pct"], "75.0")
            self.assertEqual(summary[("task", "table")]["exact_pct"], "100.0")
            self.assertEqual(summary[("topic", "negative_exponents")]["exact_pct"], "0.0")
            self.assertEqual(summary[("kind", "S")]["count"], "3")
            self.assertEqual(summary[("source", "cap")]["count"], "3")
            if not evaluate_vl.GUARD_ERROR:
                # The cube root is held by the guard, in the prediction and the target.
                self.assertEqual(summary[("topic", "radicals")]["guard_held_pred_pct"], "100.0")
                self.assertEqual(summary[("topic", "exponents")]["guard_held_pred_pct"], "0.0")
            run_info = json.loads((folder / "run.json").read_text(encoding="utf-8"))
            self.assertEqual(run_info["scored"], 4)
            self.assertTrue((folder / "predictions.tsv").exists())
            self.assertIn("| all | all | 4 | 75.0 |", (folder / "results.md").read_text(encoding="utf-8"))

    def test_hosted_needs_confirmation_and_sends_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            data, sft = Path(tmp) / "data", Path(tmp) / "sft"
            run("make_fake_dataset.py", "--out", str(data))
            run("convert_to_sft.py", "--data", str(data), "--labels", str(data / "labels.csv"),
                "--out", str(sft), "--skip-recognizer-eval-check")
            result = run("evaluate_vl.py", "--eval", str(sft), "--engine", "hosted", "--out-root", str(Path(tmp) / "out"))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("stored by Baidu", result.stderr)
            self.assertIn("--confirm-own-material", result.stderr)
            self.assertFalse((Path(tmp) / "out").exists())


if __name__ == "__main__":
    unittest.main()
