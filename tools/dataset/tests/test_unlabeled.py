"""Working copy and split of an unlabeled delivery (prepare_unlabeled.py,
split_unlabeled.py), on FAKE files in a temporary folder.

Run from tools/dataset:  python -m unittest discover -s tests -t .
"""

import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))

import prepare_unlabeled as pu  # noqa: E402
import split_unlabeled as su  # noqa: E402


class ParseNames(unittest.TestCase):
    def test_topic_spellings_are_fixed(self):
        self.assertEqual(pu.parse("quadtratic_ss_M_076.png")["topic"], "quadratic")
        self.assertEqual(pu.parse("fraction_cap_S_171.png")["topic"], "fractions")
        self.assertEqual(pu.parse("Inequalities_ss_W_006.png")["topic"], "inequalities")

    def test_copy_suffix_is_seen(self):
        info = pu.parse("linear_cap_M_092(1).png")
        self.assertTrue(info["copy"])
        self.assertEqual(info["number"], 92)

    def test_unknown_names(self):
        self.assertIsNone(pu.parse("notes.txt"))
        self.assertIsNone(pu.parse("linear_xx_S_001.png"))


class Prepare(unittest.TestCase):
    def test_working_copy(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            intake = tmp / "intake"
            (intake / "extracted" / "a").mkdir(parents=True)
            files = {
                "fraction_cap_S_001.png": b"same",
                "inequalities_cap_S_009.png": b"same",       # same bytes as the first
                "linear_cap_M_002.png": b"two",
                "linear_cap_M_002(1).png": b"three",         # base number taken
                "linear_cap_M_005(1).png": b"four",          # base number free
            }
            for name, data in files.items():
                (intake / "extracted" / "a" / name).write_bytes(data)
            (intake / "report.json").write_text(json.dumps({
                "exact_duplicates": [["fraction_cap_S_001.png", "inequalities_cap_S_009.png"]],
            }))
            summary = pu.prepare(intake, tmp / "out")

            names = sorted(p.name for p in (tmp / "out" / "images").iterdir())
            self.assertEqual(names, ["fractions_cap_S_001.png", "linear_cap_M_002.png",
                                     "linear_cap_M_005.png", "linear_cap_M_900.png"])
            self.assertEqual(summary["left_out_duplicates"], 1)
            mapping = {r["original"]: r for r in csv.DictReader((tmp / "out" / "mapping.csv").open(encoding="utf-8"))}
            self.assertIn("same bytes as fraction_cap_S_001.png", mapping["inequalities_cap_S_009.png"]["action"])
            # the originals are untouched
            self.assertTrue((intake / "extracted" / "a" / "linear_cap_M_002(1).png").exists())


class Split(unittest.TestCase):
    MAPPING = [
        {"original": "functions_ss_S_096.png", "working": "functions_ss_S_096.png", "action": "copied"},
        {"original": "fraction_cap_S_384.png", "working": "fractions_cap_S_384.png", "action": "copied, renamed"},
        {"original": "functions_cap_S_096.png", "working": "",
         "action": "left out: same bytes as fraction_cap_S_384.png"},
    ]

    def test_pair_follows_the_kept_name(self):
        self.assertEqual(su.working_name(self.MAPPING, "functions_cap_S_096.png"), "fractions_cap_S_384.png")
        self.assertEqual(su.working_name(self.MAPPING, "functions_ss_S_096.png"), "functions_ss_S_096.png")
        self.assertEqual(su.working_name(self.MAPPING, "missing.png"), "")

    def test_pairs_stay_together_and_eval_has_captures(self):
        items = []
        for topic in ("linear", "radicals"):
            for n in range(30):
                items.append({"filename": f"{topic}_cap_S_{n:03d}.png", "topic": topic, "source": "cap"})
                if n % 3 == 0:
                    items.append({"filename": f"{topic}_ss_S_{n:03d}.png", "topic": topic, "source": "ss"})
        pairs = [(f"{i['filename'].replace('_ss_', '_cap_')}", i["filename"]) for i in items if i["source"] == "ss"]
        split = su.choose(items, pairs, eval_per_topic=5, val_per_topic=4, seed=1)

        self.assertEqual(su.pairs_apart(split, pairs), [])
        for topic in ("linear", "radicals"):
            caps = [i for i in items if i["topic"] == topic and i["source"] == "cap" and split[i["filename"]] == "eval"]
            self.assertEqual(len(caps), 5)
        self.assertEqual(split, su.choose(items, pairs, 5, 4, seed=1))  # same seed, same split

    def test_pairs_apart_is_reported(self):
        self.assertEqual(su.pairs_apart({"a": "eval", "b": "train"}, [("a", "b")]), [("a", "b")])


if __name__ == "__main__":
    unittest.main()
