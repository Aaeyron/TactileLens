"""Workspace layout, run sorting and path rewriting (common.py)."""

import json
import tempfile
import unittest
from pathlib import Path

from common import Layout, rewrite_paths, tidy_run, tidy_target


class LayoutTest(unittest.TestCase):
    def test_paths(self):
        layout = Layout(Path("R"))
        self.assertEqual(layout.registry, Path("R/datasets/own/splits/frozen_eval.jsonl"))
        self.assertEqual(layout.set_dir("synthetic-eval"), Path("R/datasets/synthetic/text_lines/eval"))
        self.assertEqual(layout.set_dir("real-val"), Path("R/datasets/own/text_lines/train_val"))
        self.assertEqual(layout.fonts, Path("R/resources/fonts"))
        self.assertEqual(layout.manifest("synthetic-train"), Path("R/datasets/synthetic/text_lines/manifests/synthetic-train.jsonl"))
        self.assertEqual(layout.manifest("pairing_runs"), Path("R/datasets/own/text_lines/manifests/pairing_runs.jsonl"))

    def test_run_name(self):
        name = Layout(Path("R")).run_dir("trackA", "im2latex+synthetic", "follow up", when="20261110-120000").name
        self.assertEqual(name, "20261110-120000_trackA_im2latex+synthetic_follow-up")


class TidyTest(unittest.TestCase):
    def test_targets(self):
        cases = {
            "run.json": "run.json", "summary.md": "summary.md", "train.log": "logs/train.log",
            "model/train.log": "logs/model_train.log", "model/config.yml": "config/model_config.yml",
            "train_list.txt": "config/train_list.txt", "loss_curve.png": "charts/loss_curve.png",
            "loss_curve.csv": "charts/loss_curve.csv", "gpu_memory.csv": "logs/gpu_memory.csv",
            "model/best_accuracy.pdparams": "best_checkpoint/best_accuracy.pdparams",
            "model/latest.pdparams": "checkpoints/latest.pdparams",
            "export/onnx/inference.onnx": "onnx/inference.onnx",
            "export/infer/inference.json": "onnx/paddle_static/inference.json",
            "infer/inference.yml": "onnx/paddle_static/inference.yml", "trial_rec.onnx": "onnx/trial_rec.onnx",
            "eval/comparison.md": "evaluation/comparison.md", "logs/train.log": "logs/train.log",
            "evaluation/app/results.md": "evaluation/app/results.md",
        }
        for old, new in cases.items():
            with self.subTest(old=old):
                self.assertEqual(tidy_target(old), new)

    def test_tidy_moves_files_and_rewrites_paths(self):
        with tempfile.TemporaryDirectory() as tmp:
            run = Path(tmp) / "run"
            for rel in ("train.log", "model/best_accuracy.pdparams", "eval/comparison.md", "export/onnx/inference.onnx"):
                (run / rel).parent.mkdir(parents=True, exist_ok=True)
                (run / rel).write_text("x", encoding="utf-8")
            info = {"checkpoint": str(run / "model" / "best_accuracy"), "comparison": str(run / "eval" / "comparison.md"),
                    "onnx": str(run / "export" / "onnx" / "inference.onnx")}
            (run / "run.json").write_text(json.dumps(info), encoding="utf-8")
            tidy_run(run)
            self.assertTrue((run / "best_checkpoint" / "best_accuracy.pdparams").exists())
            self.assertFalse((run / "model").exists())
            new = json.loads((run / "run.json").read_text(encoding="utf-8"))
            self.assertEqual(new["checkpoint"], str(run / "best_checkpoint" / "best_accuracy"))
            self.assertEqual(new["comparison"], str(run / "evaluation" / "comparison.md"))
            self.assertEqual(new["onnx"], str(run / "onnx" / "inference.onnx"))


class RewriteTest(unittest.TestCase):
    def test_whole_names_only(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            old, new = folder / "run" / "eval", folder / "run" / "evaluation"
            text = f"{old}\\comparison.md and {new}\\x.md and {old}"
            (folder / "a.md").write_text(text, encoding="utf-8")
            rewrite_paths(folder, [(old, new)])
            out = (folder / "a.md").read_text(encoding="utf-8")
            self.assertNotIn("evaluationuation", out)
            self.assertEqual(out.count(str(new)), 3)

    def test_logs_are_not_rewritten(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            (folder / "logs").mkdir()
            (folder / "logs" / "train.txt").write_text("C:\\old\\x", encoding="utf-8")
            rewrite_paths(folder, [(Path("C:\\old"), Path("C:\\new"))])
            self.assertEqual((folder / "logs" / "train.txt").read_text(encoding="utf-8"), "C:\\old\\x")


if __name__ == "__main__":
    unittest.main()
