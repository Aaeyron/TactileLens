"""Dataset intake and split, on a FAKE delivery in a temporary folder.

Run from tools/dataset:  python -m unittest discover -s tests -t .
Uses a temporary training root (its own small eval set), never the real one.
"""

import csv
import io
import json
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))

import dataset_common as dc  # noqa: E402
import intake  # noqa: E402


def run(script, *args):
    return subprocess.run([sys.executable, str(HERE / script), *map(str, args)], capture_output=True, text=True,
                          encoding="utf-8", cwd=HERE)


class DatasetToolsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        base = Path(cls.tmp.name)
        cls.root = base / "root"
        # A tiny existing eval set (recognizer layout) to leak from.
        images = cls.root / "eval" / "synthetic" / "images"
        images.mkdir(parents=True)
        image = Image.new("RGB", (300, 60), "white")
        ImageDraw.Draw(image).text((10, 20), "EVAL LINE 10^-3", fill="black")
        image.save(images / "e0001.png")
        (cls.root / "eval" / "synthetic" / "labels.txt").write_text("images/e0001.png\tEVAL LINE 10⁻³\n", encoding="utf-8")

        cls.incoming = base / "incoming"
        result = run("make_fake_intake.py", "--out", cls.incoming, "--leak-from", cls.root / "eval" / "synthetic")
        assert result.returncode == 0, result.stderr
        cls.registry = base / "splits" / "frozen_eval.jsonl"
        result = run("intake.py", "--root", cls.root, "--incoming", cls.incoming, "--work", base / "intake",
                     "--registry", cls.registry)
        assert result.returncode == 0, result.stdout + result.stderr
        cls.run_dir = next((base / "intake").iterdir())
        cls.items = {i["filename"]: i for i in dc.read_items(cls.run_dir / "items.csv")}
        cls.base = base

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_originals_unchanged_and_copy_made(self):
        self.assertTrue((self.incoming / "FAKE_dryrun_dataset.zip").exists())
        self.assertTrue((self.run_dir / "extracted" / "FAKE_dryrun_dataset" / "README_FAKE.txt").exists())
        self.assertTrue((self.run_dir / "extracted" / "FAKE_dryrun_extra" / "labels_linear.csv").exists())

    def test_errors(self):
        self.assertIn("LaTeX: unbalanced braces", " ".join(self.items["radicals_ss_S_091.png"]["errors"]))
        self.assertIn("not topic_source_kind_number", " ".join(self.items["IMG_2041.jpg"]["errors"]))
        self.assertEqual(self.items["radicals_cap_S_096.png"]["errors"], ["image without a label"])
        self.assertEqual(self.items["fractions_ss_S_097.png"]["errors"], ["label without an image"])

    def test_flags_and_warnings(self):
        personal = " ".join(self.items["linear_equations_cap_T_094.jpg"]["flags"])
        self.assertIn("GPS", personal)
        self.assertIn("form field for a person", personal)
        self.assertIn("ALREADY IN AN EVAL SET", " ".join(self.items["exponents_ss_T_090.png"]["flags"]))
        self.assertIn("charset: ˣ", " ".join(self.items["exponents_ss_T_095.png"]["warnings"]))
        self.assertIn("same bytes as exponents_ss_S_002.png", " ".join(self.items["exponents_ss_S_092.png"]["warnings"]))
        self.assertIn("near-duplicate of exponents_ss_S_003.png", " ".join(self.items["exponents_ss_S_093.jpg"]["warnings"]))
        self.assertIn("ss/cap pair with fractions_cap_S_001.png", " ".join(self.items["fractions_ss_S_001.png"]["warnings"]))

    def test_no_false_near_duplicates_between_different_formulas(self):
        report = json.loads((self.run_dir / "report.json").read_text(encoding="utf-8"))
        self.assertEqual([p[:2] for p in report["near_duplicates"]], [["exponents_ss_S_003.png", "exponents_ss_S_093.jpg"]])

    def test_counts(self):
        report = json.loads((self.run_dir / "report.json").read_text(encoding="utf-8"))
        self.assertEqual(report["with_errors"], 4)
        self.assertEqual(report["usable"], 48)
        self.assertIn("| exponents |", (self.run_dir / "report.md").read_text(encoding="utf-8"))

    def test_unsafe_zip_is_refused(self):
        bad = self.base / "bad.zip"
        with zipfile.ZipFile(bad, "w") as zf:
            zf.writestr("../escape.txt", "x")
        with self.assertRaises(intake.IntakeError):
            intake.safe_extract(bad, self.base / "bad_out")
        self.assertFalse((self.base / "escape.txt").exists())

    def test_split(self):
        out = self.base / "splits"
        strict = run("split_dataset.py", "--intake", self.run_dir, "--root", self.root, "--out", out,
                     "--registry", self.registry)
        self.assertNotEqual(strict.returncode, 0)
        self.assertIn("LEAK: exponents_ss_T_090.png", strict.stdout)
        self.assertFalse(self.registry.exists(), "nothing may be written when the leak guard stops")

        first = run("split_dataset.py", "--intake", self.run_dir, "--root", self.root, "--out", out,
                    "--registry", self.registry, "--drop-eval-overlap")
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        split_dir = sorted(p for p in out.iterdir() if p.is_dir())[0]
        report = json.loads((split_dir / "split_report.json").read_text(encoding="utf-8"))
        split = report["items"]
        self.assertNotIn("exponents_ss_T_090.png", split)
        self.assertNotIn("linear_equations_cap_T_094.jpg", split)  # flagged: left out until checked
        self.assertEqual(split["tables_cap_M_002.png"], "eval")  # given in the CSV
        self.assertEqual(split["fractions_ss_S_001.png"], split["fractions_cap_S_001.png"])
        self.assertEqual(split["exponents_ss_S_003.png"], split["exponents_ss_S_093.jpg"])
        evals = [k for k, v in split.items() if v == "eval"]
        self.assertTrue(evals)
        self.assertTrue(all("_cap_" in k for k in evals), evals)  # mainly captures

        with open(split_dir / "labels.csv", encoding="utf-8") as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(len(rows), len(split))
        for name in ("rec_train.txt", "formula_train.txt", "formula_eval.txt"):
            for line in (split_dir / name).read_text(encoding="utf-8").splitlines():
                self.assertTrue((split_dir / line.split("\t")[0]).exists(), line)
        self.assertNotIn("xˣ", (split_dir / "rec_train.txt").read_text(encoding="utf-8"))

        second = run("split_dataset.py", "--intake", self.run_dir, "--root", self.root, "--out", out,
                     "--registry", self.registry, "--drop-eval-overlap", "--seed", "5")
        self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
        again = json.loads((sorted(p for p in out.iterdir() if p.is_dir())[-1] / "split_report.json")
                           .read_text(encoding="utf-8"))["items"]
        for name in evals:
            self.assertEqual(again[name], "eval", f"{name} was held out before and must stay in eval")

    def test_hash_helpers(self):
        a = dc.dhash(self.run_dir / "extracted" / "FAKE_dryrun_dataset" / "exponents" / "exponents_ss_S_003.png")
        b = dc.dhash(self.run_dir / "extracted" / "FAKE_dryrun_dataset" / "exponents" / "exponents_ss_S_093.jpg")
        self.assertTrue(dc.is_near_duplicate(a, b))
        wide = Image.new("RGB", (900, 60), "white")
        buffer = io.BytesIO()
        wide.save(buffer, format="PNG")
        path = self.base / "wide.png"
        path.write_bytes(buffer.getvalue())
        self.assertFalse(dc.is_near_duplicate(a, dc.dhash(path)))  # very different shape


if __name__ == "__main__":
    unittest.main()
