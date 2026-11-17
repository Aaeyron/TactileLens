"""python -m unittest test_finetune_changes (paddle_onnx_env, from tools/model_prep)."""

import csv
import math
import tempfile
import unittest
from pathlib import Path

from finetune_changes import (SECTION_END, SECTION_START, confidence_bin, error_type, habits, module_of, put_section,
                              recorded_validation, relative_change, sequence_confidence, short_label, trim_at_eos,
                              unchanged_modules)


class ModuleTest(unittest.TestCase):
    def test_modules(self):
        self.assertEqual(module_of("backbone.pphgnet_b4.stem.stem1.conv.weight"), "Image encoder: first layers")
        self.assertEqual(module_of("backbone.pphgnet_b4.stages.0.blocks.0.layers.0.conv.weight"), "Image encoder: stage 1")
        self.assertEqual(module_of("backbone.pphgnet_b4.last_conv.weight"), "Image encoder: output layers")
        self.assertEqual(module_of("backbone.pphgnet_b4.fc.bias"), "Image encoder: output layers")
        self.assertEqual(module_of("head.enc_to_dec_proj.weight"), "Bridge: image features to the decoder")
        self.assertEqual(module_of("head.decoder.model.decoder.layers.1.encoder_attn.k_proj.weight"),
                         "Text decoder layer 2: attention to the image")
        self.assertEqual(module_of("head.decoder.model.decoder.layers.0.self_attn_layer_norm.bias"),
                         "Text decoder layer 1: attention to earlier tokens")
        self.assertEqual(module_of("head.decoder.model.decoder.layers.0.fc2.weight"), "Text decoder layer 1: feed-forward")
        self.assertEqual(module_of("head.decoder.model.decoder.embed_positions.weight"),
                         "Text decoder: token and position inputs")
        self.assertEqual(module_of("head.decoder.lm_head.weight"), "Output layer: picks the next token")

    def test_short_labels_fit_the_chart(self):
        names = ["backbone.pphgnet_b4.stem.x", "backbone.pphgnet_b4.stages.3.x", "backbone.pphgnet_b4.fc.weight",
                 "head.enc_to_dec_proj.weight", "head.decoder.model.decoder.embed_tokens.weight",
                 "head.decoder.model.decoder.layers.1.self_attn.q_proj.weight",
                 "head.decoder.model.decoder.layers.1.encoder_attn.q_proj.weight",
                 "head.decoder.model.decoder.layers.1.fc1.weight", "head.decoder.model.decoder.layer_norm.weight",
                 "head.decoder.lm_head.weight"]
        for name in names:
            self.assertLessEqual(len(short_label(module_of(name))), 24, name)

    def test_relative_change(self):
        self.assertAlmostEqual(relative_change(1.0, 100.0), 0.1)
        self.assertTrue(math.isnan(relative_change(1.0, 0.0)))

    def test_unchanged_modules(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "p.csv"
            with open(path, "w", encoding="utf-8", newline="") as handle:
                w = csv.DictWriter(handle, fieldnames=["module", "statistic", "max_abs_change"])
                w.writeheader()
                w.writerows([{"module": "A", "statistic": "False", "max_abs_change": "0.0"},
                             {"module": "A", "statistic": "True", "max_abs_change": "0.5"},  # statistics ignored
                             {"module": "B", "statistic": "False", "max_abs_change": "0.0"},
                             {"module": "B", "statistic": "False", "max_abs_change": "1e-9"}])
            self.assertEqual(unchanged_modules(path), ["A"])


class ConfidenceTest(unittest.TestCase):
    def test_trim_at_first_end_token(self):
        self.assertEqual(trim_at_eos([5, 6, 2, 1, 1], [.9, .8, .99, .5, .5]), ([5, 6], [.9, .8]))
        self.assertEqual(trim_at_eos([5, 6], [.9, .8]), ([5, 6], [.9, .8]))

    def test_sequence_confidence(self):
        c = sequence_confidence([0.5, 0.8, 1.0])
        self.assertEqual(c["weakest"], 0.5)
        self.assertAlmostEqual(c["geomean"], (0.5 * 0.8 * 1.0) ** (1 / 3))
        self.assertEqual(sequence_confidence([])["tokens"], 0)

    def test_bins(self):
        self.assertEqual(confidence_bin(0.0), "0.00-0.50")
        self.assertEqual(confidence_bin(0.5), "0.50-0.80")
        self.assertEqual(confidence_bin(0.949), "0.90-0.95")
        self.assertEqual(confidence_bin(1.0), "0.99-1.00")

    def test_recorded_validation(self):
        meta = {"train": {"val_items": 104, "baseline_validation": {"exp_rate": 41 / 104},
                          "validations": [{"exp_rate": 47 / 104}, {"exp_rate": 54 / 104}, {"exp_rate": 50 / 104}]}}
        self.assertEqual(recorded_validation(meta), {"original": 41, "fine-tuned": 54})


class ErrorTypeTest(unittest.TestCase):
    def kind(self, target, prediction):
        return error_type(target, prediction)["kind"]

    def test_right_and_equivalent(self):
        self.assertIsNone(self.kind(r"x ^ { 2 }", r"x^{2}"))
        self.assertEqual(self.kind(r"x = 1 \, ,", r"x=1,"), "Spacing only")
        self.assertEqual(self.kind(r"x \le 1", r"x\leq1"), "Same meaning, different notation")

    def test_meaning_changing_kinds(self):
        self.assertEqual(self.kind(r"x = 1 ,", r"x=1"), "Symbols left out")
        self.assertEqual(self.kind(r"u < 2", r"u<<2"), "Extra symbols")
        self.assertEqual(self.kind(r"x + 1", r"x - 1"), "Wrong symbols")
        self.assertEqual(self.kind(r"a + b = c", r"a - b = c d"), "Several kinds of mistake")

    def test_structure_flag(self):
        self.assertTrue(error_type(r"x ^ { 1 2 }", r"x^{1}2")["structure"])
        self.assertFalse(error_type(r"x + 1", r"x - 1")["structure"])


class HabitsTest(unittest.TestCase):
    def test_counts_formulas_not_occurrences(self):
        before = {"a": {"target": r"x \, y \, z", "prediction": "x y z"},
                  "b": {"target": r"a \quad b", "prediction": r"a \qquad b"}}
        after = {"a": {"target": before["a"]["target"], "prediction": r"x \, y"},
                 "b": {"target": before["b"]["target"], "prediction": r"a \quad b"}}
        rows = {r["command"]: r for r in habits(before, after, ["\\,", "\\quad", "\\qquad"])}
        self.assertEqual(rows["\\,"], {"command": "\\,", "target": 1, "original": 0, "fine-tuned": 1})
        self.assertEqual(rows["\\quad"]["original"], 0)  # \qquad is not \quad
        self.assertEqual(rows["\\quad"]["fine-tuned"], 1)


class PageTest(unittest.TestCase):
    PAGE = "<div>\n<h2>Runs</h2>\n<footer>made</footer>\n</div>"

    def test_inserted_before_footer_once(self):
        once = put_section(self.PAGE, "<h2>A</h2>")
        self.assertLess(once.index("<h2>A</h2>"), once.index("<footer"))
        twice = put_section(once, "<h2>B</h2>")
        self.assertNotIn("<h2>A</h2>", twice)
        self.assertEqual(twice.count(SECTION_START), 1)
        self.assertEqual(twice.count(SECTION_END), 1)
        self.assertEqual(twice.replace("<h2>B</h2>", "<h2>A</h2>"), once)

    def test_needs_a_footer(self):
        with self.assertRaises(SystemExit):
            put_section("<div></div>", "x")


if __name__ == "__main__":
    unittest.main()
