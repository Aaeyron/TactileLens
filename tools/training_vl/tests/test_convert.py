"""Tests for the SFT converter and shared helpers (no Paddle needed).

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

from vl_common import (  # noqa: E402
    html_table_to_otsl,
    latex_problems,
    load_config,
    normalize_for_compare,
    otsl_problems,
    parse_filename,
)

CONFIG = load_config()


def run(*args):
    return subprocess.run([sys.executable, "-B", *args], cwd=HERE, capture_output=True, text=True, encoding="utf-8")


class FilenameTests(unittest.TestCase):
    def test_parts_come_from_the_name(self):
        self.assertEqual(
            parse_filename("radicals_ss_S_001.png", CONFIG),
            {"topic": "radicals", "source": "ss", "kind": "S", "number": "001"},
        )
        parts = parse_filename("negative_exponents_cap_T_012.jpg", CONFIG)
        self.assertEqual((parts["topic"], parts["source"], parts["kind"]), ("negative_exponents", "cap", "T"))

    def test_kind_t_is_text_plus_notation_not_table(self):
        self.assertEqual(CONFIG["kinds"]["T"], "text + notation")

    def test_unknown_source_or_kind_is_rejected(self):
        for name in ("radicals_web_S_001.png", "radicals_ss_X_001.png", "radicals_S_001.png", "radicals_ss_S_001.gif"):
            with self.subTest(name=name):
                self.assertIsNone(parse_filename(name, CONFIG))


class TargetChecks(unittest.TestCase):
    def test_latex(self):
        self.assertEqual(latex_problems(r"\frac{x+1}{2}=3"), [])
        self.assertEqual(latex_problems(r"\[x^{2}\]"), [])
        self.assertTrue(latex_problems(r"\frac{x+1}{2=3"))
        self.assertTrue(latex_problems(r"\left( x"))
        self.assertTrue(latex_problems(r"\begin{aligned} x \end{array}"))
        self.assertTrue(latex_problems("$$  $$"))

    def test_otsl(self):
        self.assertEqual(otsl_problems("<fcel>x<fcel>y<nl><fcel>1<ecel><nl>"), [])
        self.assertTrue(otsl_problems("<fcel>x<fcel>y<nl><fcel>1<nl>"))  # uneven rows
        self.assertTrue(otsl_problems("<fcel>x<td>y<nl>"))  # unknown token
        self.assertTrue(otsl_problems("<fcel>x<fcel>y"))  # no final <nl>

    def test_html_to_otsl_with_spans(self):
        html = "<table><tr><td colspan=2>Head</td></tr><tr><td rowspan=2>a</td><td>b</td></tr><tr><td>c</td></tr></table>"
        self.assertEqual(html_table_to_otsl(html), "<fcel>Head<lcel><nl><fcel>a<fcel>b<nl><ucel><fcel>c<nl>")

    def test_comparison_forms(self):
        self.assertEqual(normalize_for_compare("formula", r"$$ x^{2} + 1 $$"), "x^{2}+1")
        self.assertEqual(normalize_for_compare("formula", r"\[x^{2}+1\]"), "x^{2}+1")
        self.assertEqual(
            normalize_for_compare("table", "<table><tr><td>x</td><td>y</td></tr></table>"),
            normalize_for_compare("table", "<fcel>x<fcel>y<nl>"),
        )


class ConverterTests(unittest.TestCase):
    def test_fake_dataset_converts_and_validates(self):
        with tempfile.TemporaryDirectory() as tmp:
            data, out = Path(tmp) / "data", Path(tmp) / "sft"
            self.assertEqual(run("make_fake_dataset.py", "--out", str(data)).returncode, 0)
            result = run("convert_to_sft.py", "--data", str(data), "--labels", str(data / "labels.csv"),
                         "--out", str(out), "--skip-recognizer-eval-check")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            report = json.loads((out / "report.json").read_text(encoding="utf-8"))
            self.assertEqual(report["records"], {"train": 6, "val": 2, "eval": 4})
            self.assertEqual(report["errors"], [])
            self.assertIsNone(report["leak"])

            records = [json.loads(line) for line in (out / "train.jsonl").read_text(encoding="utf-8").splitlines()]
            self.assertEqual(len(records), 6)
            first = records[0]
            self.assertEqual([t["tag"] for t in first["text_info"]], ["mask", "no_mask"])
            self.assertIn(first["text_info"][0]["text"], {"OCR:", "Formula Recognition:", "Table Recognition:"})
            self.assertEqual(first["image_info"][0]["matched_text_index"], 0)
            self.assertTrue((out / first["image_info"][0]["image_url"]).exists())
            formulas = [r for r in records if r["text_info"][0]["text"] == "Formula Recognition:"]
            self.assertTrue(all(r["text_info"][1]["text"].startswith("\\[") for r in formulas))

            eval_names = {json.loads(l)["filename"] for l in (out / "eval_meta.jsonl").read_text(encoding="utf-8").splitlines()}
            train_names = {json.loads(l)["filename"] for l in (out / "train_meta.jsonl").read_text(encoding="utf-8").splitlines()}
            self.assertFalse(eval_names & train_names)

    def test_an_eval_image_in_train_is_refused_and_nothing_is_written(self):
        with tempfile.TemporaryDirectory() as tmp:
            data, out = Path(tmp) / "data", Path(tmp) / "sft"
            run("make_fake_dataset.py", "--out", str(data), "--leak")
            result = run("convert_to_sft.py", "--data", str(data), "--labels", str(data / "labels.csv"),
                         "--out", str(out), "--skip-recognizer-eval-check")
            self.assertEqual(result.returncode, 1)
            self.assertIn("LEAK", result.stdout)
            self.assertFalse((out / "train.jsonl").exists())
            report = json.loads((out / "report.json").read_text(encoding="utf-8"))
            self.assertIn("same bytes as an eval image", report["leak"])

    def test_bad_labels_are_reported_and_nothing_is_written(self):
        with tempfile.TemporaryDirectory() as tmp:
            data, out = Path(tmp) / "data", Path(tmp) / "sft"
            run("make_fake_dataset.py", "--out", str(data))
            with open(data / "labels.csv", encoding="utf-8", newline="") as handle:
                rows = list(csv.DictReader(handle))
            rows[0]["target"] = r"\frac{x+1}{2"           # unbalanced
            rows[6]["target"] = "<fcel>x<fcel>y<nl><fcel>1<nl>"  # uneven table
            rows[1]["task"] = "chart"                       # unknown task
            with open(data / "labels.csv", "w", encoding="utf-8", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=["filename", "task", "target", "split"])
                writer.writeheader()
                writer.writerows(rows)
            result = run("convert_to_sft.py", "--data", str(data), "--labels", str(data / "labels.csv"),
                         "--out", str(out), "--skip-recognizer-eval-check")
            self.assertEqual(result.returncode, 1)
            report = json.loads((out / "report.json").read_text(encoding="utf-8"))
            problems = " ".join(p for _, p in report["errors"])
            self.assertIn("unbalanced braces", problems)
            self.assertIn("different numbers of cells", problems)
            self.assertIn("unknown task", problems)
            self.assertFalse((out / "train.jsonl").exists())


if __name__ == "__main__":
    unittest.main()
