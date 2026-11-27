"""Box rules of crop_formulas.py."""

import tempfile
import unittest
from pathlib import Path

import numpy as np

import crop_formulas as cf


def region(label, score, box):
    return {"label_id": label, "score": score, "box": [float(v) for v in box]}


class CropRules(unittest.TestCase):
    def setUp(self):
        self.page = np.full((400, 600), 255, dtype=np.uint8)

    def test_sample_size_keeps_both_sides_at_800(self):
        self.assertEqual(cf.sample_size(4000, 3000), 2)
        self.assertEqual(cf.sample_size(3200, 3200), 4)
        self.assertEqual(cf.sample_size(1599, 4000), 1)

    def test_regions_use_sigmoid_threshold_and_pixels(self):
        logits = np.full((2, 25), -9.0)
        logits[1, cf.DISPLAY_ID] = 2.0
        boxes = np.array([[0.5, 0.5, 0.1, 0.1], [0.5, 0.5, 0.5, 0.5]])
        found = cf.regions_from(logits, boxes, 200, 100)
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0]["box"], [50.0, 25.0, 150.0, 75.0])

    def test_duplicate_keeps_the_better_region(self):
        kept = cf.remove_duplicates([region(22, 0.6, (10, 10, 110, 60)), region(5, 0.9, (10, 10, 110, 61))])
        self.assertEqual([r["label_id"] for r in kept], [5])

    def test_inline_inside_display_is_dropped(self):
        crops, dropped = cf.select_formulas(
            [region(5, 0.9, (100, 100, 400, 200)), region(15, 0.8, (150, 120, 220, 160))], self.page)
        self.assertEqual([c["category"] for c in crops], ["formula_display"])
        self.assertEqual(dropped["inside a display formula"], 1)

    def test_tiny_box_is_dropped(self):
        crops, dropped = cf.select_formulas([region(15, 0.9, (100, 100, 115, 108))], self.page)
        self.assertEqual((crops, dropped["tiny"]), ([], 1))

    def test_ink_on_the_border_means_cut_off(self):
        self.page[120:140, 0:6] = 0
        crops, dropped = cf.select_formulas([region(5, 0.9, (0, 100, 200, 160))], self.page)
        self.assertEqual((crops, dropped["cut off by the image border"]), ([], 1))

    def test_clean_border_is_kept_and_left_edge_widened(self):
        crops, _ = cf.select_formulas([region(5, 0.9, (100, 100, 300, 140))], self.page)
        self.assertEqual(crops[0]["crop_box"], [94, 100, 300, 140])

    def test_a_retried_image_replaces_its_error_and_a_cut_line_is_ignored(self):
        with tempfile.TemporaryDirectory() as folder:
            log = Path(folder) / "detections.jsonl"
            log.write_text('{"source": "a", "error": "disk full"}\n{"source": "b"}\n{"source": "a"}\n{"sou',
                           encoding="utf-8")
            rows = cf.read_detections(log)
        self.assertEqual({r["source"]: r.get("error") for r in rows}, {"a": None, "b": None})

    def test_inline_box_is_not_widened(self):
        crops, _ = cf.select_formulas([region(15, 0.9, (100, 100, 300, 140))], self.page)
        self.assertEqual(crops[0]["crop_box"], [100, 100, 300, 140])

    def test_inline_outside_text_is_standalone(self):
        crops, _ = cf.select_formulas([region(15, 0.9, (100, 100, 300, 140))], self.page)
        self.assertTrue(crops[0]["standalone"])
        crops, _ = cf.select_formulas(
            [region(15, 0.9, (100, 100, 300, 140)), region(22, 0.7, (50, 50, 500, 300))], self.page)
        self.assertFalse(crops[0]["standalone"])


if __name__ == "__main__":
    unittest.main()
