"""Tests for formula_list_to_eval.py and compare_online_offline.py (no models, no onnxruntime).

Run from tools/training_vl:  python -m unittest discover -s tests -t .
"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))

from compare_online_offline import END, START, agreement, put_section, strict  # noqa: E402
from formula_list_to_eval import build, parse_name  # noqa: E402


def right(target, reading):
    return target == reading


def same(a, b):
    return a == b


class AgreementTest(unittest.TestCase):
    ROWS = [
        ("a", "a", "a"),  # agree, right
        ("b", "x", "x"),  # agree, both wrong the same way: the flag misses it
        ("c", "y", "c"),  # disagree, offline wrong, online right: caught
        ("d", "z", "w"),  # disagree, both wrong: caught
        ("e", "e", "q"),  # disagree, offline right: false alarm
    ]

    def test_counts(self):
        a = agreement(self.ROWS, right, same)
        self.assertEqual((a["items"], a["agree"], a["agree_right"], a["agree_wrong"]), (5, 2, 1, 1))
        self.assertEqual((a["disagree"], a["disagree_offline_wrong"], a["disagree_offline_right"]), (3, 2, 1))
        self.assertEqual(a["disagree_online_right"], 1)
        self.assertEqual((a["offline_wrong"], a["offline_right"]), (3, 2))
        self.assertEqual((a["flag_catches"], a["flag_misses"], a["flag_false_alarms"]), (2, 1, 1))

    def test_catches_and_misses_add_up(self):
        a = agreement(self.ROWS, right, same)
        self.assertEqual(a["flag_catches"] + a["flag_misses"], a["offline_wrong"])
        self.assertEqual(a["flag_catches"] + a["flag_false_alarms"], a["disagree"])

    def test_empty(self):
        self.assertEqual(agreement([], right, same)["agree"], 0)

    def test_strict_ignores_spaces_and_delimiters(self):
        self.assertTrue(strict(r"x ^ { 2 }", r"$$ x^{2} $$"))
        self.assertFalse(strict(r"x ^ { 2 }", r"x^{3}"))


class PageTest(unittest.TestCase):
    def test_inserted_once_and_replaced(self):
        page = "<div><footer>f</footer></div>"
        once = put_section(page, "<h2>A</h2>")
        self.assertLess(once.index("<h2>A</h2>"), once.index("<footer"))
        twice = put_section(once, "<h2>B</h2>")
        self.assertEqual((twice.count(START), twice.count(END)), (1, 1))
        self.assertNotIn("<h2>A</h2>", twice)


class ConvertTest(unittest.TestCase):
    def test_parse_name(self):
        self.assertEqual(parse_name("images/quadratic_equations_pub_i2l-test_00001.png"),
                         {"topic": "quadratic_equations", "source": "pub", "kind": "i2l-test"})
        self.assertEqual(parse_name("radicals_cap_S_005.png")["topic"], "radicals")
        with self.assertRaises(ValueError):
            parse_name("nothing.png")

    def test_build(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            (tmp / "images").mkdir()
            (tmp / "images" / "fractions_pub_i2l-test_00001.png").write_bytes(b"png")
            (tmp / "list.txt").write_text("images/fractions_pub_i2l-test_00001.png\t\\frac { 1 } { 2 }\n", encoding="utf-8")
            records, metas = build(tmp / "list.txt", "Formula Recognition:")
            self.assertEqual(len(records), 1)
            self.assertTrue(Path(records[0]["image_info"][0]["image_url"]).is_absolute())
            self.assertEqual(records[0]["text_info"][1]["text"], r"\frac { 1 } { 2 }")
            self.assertEqual(metas[0]["filename"], "images/fractions_pub_i2l-test_00001.png")
            self.assertEqual((metas[0]["topic"], metas[0]["task"]), ("fractions", "formula"))
            json.dumps(records)  # serialisable


if __name__ == "__main__":
    unittest.main()
