"""Even quotas and the offline-only share of build_crop_train.py."""

import unittest

import build_crop_train as bc


def row(crop, topic="linear", kind="M", group="agreed", rank=1):
    return {"crop": crop, "topic": topic, "kind": kind, "group": group, "source": "cap", "vl_rank": rank}


class Quotas(unittest.TestCase):
    def test_even_split(self):
        self.assertEqual(bc.even_quotas({"a": 10, "b": 10}, 10), {"a": 5, "b": 5})

    def test_unused_share_moves_on(self):
        self.assertEqual(bc.even_quotas({"a": 2, "b": 100}, 10), {"a": 2, "b": 8})

    def test_never_more_than_available(self):
        self.assertEqual(bc.even_quotas({"a": 3, "b": 4}, 100), {"a": 3, "b": 4})


class Select(unittest.TestCase):
    def test_vl_labels_first_and_offline_share(self):
        rows = [row(f"v{i}", rank=i) for i in range(6)] + [row(f"o{i}", group="offline only", rank=10 + i)
                                                           for i in range(10)]
        picked = bc.select(rows, cap=100, offline_share=0.4)
        offline = [r for r in picked if r["group"] == "offline only"]
        self.assertEqual(len(picked) - len(offline), 6)
        self.assertEqual(len(offline), 4)  # 4 of 10 = 40%

    def test_no_offline_only(self):
        rows = [row("v")] + [row("o", group="offline only")]
        self.assertEqual([r["crop"] for r in bc.select(rows, 10, 0.0)], ["v"])

    def test_cap_spread_over_groups(self):
        rows = [row(f"a{i}", topic="a") for i in range(10)] + [row(f"b{i}", topic="b") for i in range(10)]
        picked = bc.select(rows, 6, 0.0)
        self.assertEqual(sorted(r["topic"] for r in picked), ["a"] * 3 + ["b"] * 3)


if __name__ == "__main__":
    unittest.main()
