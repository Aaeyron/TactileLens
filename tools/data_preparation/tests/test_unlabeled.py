"""Working copy and split of an unlabeled delivery (prepare_unlabeled.py,
split_unlabeled.py), on FAKE files in a temporary folder.

Run from tools/data_preparation:  python -m unittest discover -s tests -t .
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


class DedupeIntake(unittest.TestCase):
    def test_one_file_per_content(self):
        import zipfile
        import intake
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            incoming = tmp / "incoming"
            incoming.mkdir()
            with zipfile.ZipFile(incoming / "a.zip", "w") as z:
                z.writestr("A/linear_cap_S_001.png", b"one")
                z.writestr("A/linear_cap_S_002.png", b"two")
            with zipfile.ZipFile(incoming / "b.zip", "w") as z:
                z.writestr("B/linear_cap_S_001.png", b"one")         # same name, same bytes
                z.writestr("B/fractions_cap_S_009.png", b"two")      # other name, same bytes
                z.writestr("B/radicals_ss_S_003.png", b"three")
            copied, plan = intake.copy_incoming(incoming, tmp / "x", dedupe=True)

            files = sorted(p.name for p in (tmp / "x").rglob("*") if p.is_file())
            self.assertEqual(files, ["fractions_cap_S_009.png", "linear_cap_S_001.png", "radicals_ss_S_003.png"])
            self.assertEqual(len(plan), 5)
            self.assertEqual(sum(r["kept"] for r in plan), 3)
            self.assertEqual(intake.same_bytes_groups(plan), [["fractions_cap_S_009.png", "linear_cap_S_002.png"]])
            self.assertEqual((incoming / "a.zip").exists(), True)

    def test_unsafe_member_is_refused(self):
        import zipfile
        import intake
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            (tmp / "in").mkdir()
            with zipfile.ZipFile(tmp / "in" / "bad.zip", "w") as z:
                z.writestr("../evil.png", b"x")
            with self.assertRaises(intake.IntakeError):
                intake.copy_incoming(tmp / "in", tmp / "x", dedupe=True)


class Extend(unittest.TestCase):
    def test_old_sides_fixed_pairs_and_leak_guard(self):
        import extend_unlabeled as eu
        items = [
            {"filename": "a_cap_S_001.png", "topic": "a", "source": "cap", "origin": "old"},   # eval
            {"filename": "a_cap_S_002.png", "topic": "a", "source": "cap", "origin": "old"},   # val
            {"filename": "a_ss_S_001.png", "topic": "a", "source": "ss", "origin": "new"},     # pair of eval
            {"filename": "a_ss_S_002.png", "topic": "a", "source": "ss", "origin": "new"},     # pair of val
            {"filename": "a_cap_S_050.png", "topic": "a", "source": "cap", "origin": "new"},   # near eval
            {"filename": "a_cap_S_060.png", "topic": "a", "source": "cap", "origin": "new"},
            {"filename": "a_ss_S_060.png", "topic": "a", "source": "ss", "origin": "new"},
            {"filename": "a_cap_S_070.png", "topic": "a", "source": "cap", "origin": "new"},
        ]
        old = {"a_cap_S_001.png": "eval", "a_cap_S_002.png": "val"}
        pairs = [("a_ss_S_001.png", "a_cap_S_001.png"), ("a_ss_S_002.png", "a_cap_S_002.png"),
                 ("a_ss_S_060.png", "a_cap_S_060.png")]
        near = [("a_cap_S_001.png", "a_cap_S_050.png")]
        side, note = eu.extend_split(items, old, pairs, near, val_per_topic=1, seed=1)

        self.assertEqual(side["a_cap_S_001.png"], "eval")
        self.assertEqual(side["a_cap_S_002.png"], "val")
        self.assertEqual(side["a_ss_S_001.png"], "")          # eval stays frozen
        self.assertEqual(side["a_ss_S_002.png"], "val")
        self.assertEqual(side["a_cap_S_050.png"], "")         # near-duplicate of eval
        self.assertIn("near-duplicate", note["a_cap_S_050.png"])
        self.assertEqual(side["a_ss_S_060.png"], side["a_cap_S_060.png"])
        self.assertEqual(sorted(side[n] for n in ("a_cap_S_060.png", "a_cap_S_070.png")).count("val") in (1, 2), True)
        self.assertNotIn("eval", {side[i["filename"]] for i in items if i["origin"] == "new"})


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
