"""Measurements and page handling of own_dataset_report.py (no model, no data)."""

import unittest

from own_dataset_report import HEADER_LINK, SECTION_START, add_to_page, label_sources, share, topics_of, vl_agreement


class VlAgreementTest(unittest.TestCase):
    def test_counts(self):
        labels = {"a": "x\\le1", "b": "y", "c": "z", "d": "w"}
        before = {"a": "x<1", "b": "y", "c": "q", "d": "w"}
        after = {"a": "x\\leq1", "b": "k", "c": "r", "d": "w"}
        vl = {"a": "x\\leq1", "b": "k", "c": "r", "d": None}
        result = vl_agreement(labels, before, after, vl)
        self.assertEqual(result["with_vl_reading"], 3)
        self.assertEqual(result["labels_equal_to_vl"], 1)  # a, by notation
        self.assertEqual(result["fine_tuned_equal_to_vl"], 3)
        self.assertEqual(result["vl_differs_from_label"], 2)  # b, c
        self.assertEqual(result["there_original_right"], 1)  # b
        self.assertEqual(result["there_fine_tuned_right"], 0)
        self.assertEqual(result["there_fine_tuned_equal_to_vl"], 2)


class LabelSourcesTest(unittest.TestCase):
    def test_groups(self):
        rows = [{"split": "eval", "status": "checked", "provenance": "human-verified"},
                {"split": "eval", "status": "checked", "provenance": "human-verified, convention fix"},
                {"split": "eval", "status": "checked", "provenance": "human-approved fix (proposed by Claude)"},
                {"split": "eval", "status": "exclude", "provenance": "human-verified"},
                {"split": "val", "status": "checked", "provenance": "AI-reviewed (Claude), not human-verified"},
                {"split": "val", "status": "checked", "provenance": "human-verified"}]
        result = label_sources(rows)
        self.assertEqual((result["eval_accepted"], result["eval_convention"], result["eval_approved_fix"]), (1, 1, 1))
        self.assertEqual((result["val_human"], result["val_ai"]), (1, 1))
        self.assertEqual(result["excluded"], {"eval": 1})


class SmallPartsTest(unittest.TestCase):
    def test_share(self):
        self.assertEqual(share(73, 84), "73/84 (86.9%)")
        self.assertEqual(share(0, 0), "not measured")

    def test_topics_leave_out_other_groups(self):
        groups = {"ALL": 1, "linear": 1, "labels: x": 1, "length <=20 (simple)": 1, "source: cap": 1}
        self.assertEqual(topics_of(groups), ["linear"])

    def test_page_update_replaces_and_links_once(self):
        page = "<header>h</header><footer>f</footer>"
        once = add_to_page(page, "one")
        twice = add_to_page(once, "two")
        self.assertEqual(twice.count(SECTION_START), 1)
        self.assertEqual(twice.count(HEADER_LINK), 1)
        self.assertIn("two", twice)
        self.assertNotIn("one", twice)
        self.assertLess(twice.index(SECTION_START), twice.index("<footer>"))


if __name__ == "__main__":
    unittest.main()
