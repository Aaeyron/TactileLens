"""Runs with the real Liblouis (skipped where it is not installed).

These pin today's measured results, so a change in our text preparation or
in Liblouis shows up as a failing test. They measure; they never change
Braille.
"""

import unittest

from tools.braille_check import check_reference, lou, roundtrip
from tools.braille_check.baseline35 import SELF_WRITTEN


@unittest.skipUnless(lou.available(), "Liblouis or the app's tables are not here")
class WithLiblouisTests(unittest.TestCase):
    def test_version(self):
        self.assertEqual(lou.version(), "3.38.0")

    def test_rulebook_numbers_example(self):
        # RUEB 2024, 6.2.1, p. 66.
        self.assertEqual(lou.translate("1959", lou.UEB_G2), "⠼⠁⠊⠑⠊")

    def test_reference_results_measured_on_2026_11_17(self):
        results = check_reference.check(check_reference.load_reference())
        found = {
            key: [row["id"] for row in rows if row["result"] != "match"]
            for key, rows in results.items()
        }

        # Every example matches. (Until the phone kept dashes in text, "4–3"
        # came out with a hyphen there, RUEB 6.3.1.)
        self.assertEqual(
            found,
            {
                "braille2/offline": [],
                "braille2/online": [],
                "braille1/offline": [],
                "braille1/online": [],
            },
        )
        self.assertEqual(
            results["braille2/offline"][15]["ours"], "⠠⠮⠀⠎⠉⠕⠗⠑⠀⠴⠀⠼⠙⠠⠤⠼⠉"
        )

    def test_round_trip_counts_measured_on_2026_11_17(self):
        counts = {
            key: (sum(r["exact"] for r in rows), sum(r["same_words"] for r in rows))
            for key, rows in roundtrip.run().items()
        }

        self.assertEqual(
            counts,
            {
                "braille2/offline": (41, 45),
                "braille2/online": (45, 45),
                "braille1/offline": (49, 49),
                "braille1/online": (49, 49),
            },
        )


class BaselineInputsTests(unittest.TestCase):
    def test_eleven_self_written_blocks_in_the_recorded_order(self):
        self.assertEqual(len(SELF_WRITTEN), 11)
        self.assertEqual(SELF_WRITTEN[-1][0], "table")
        self.assertIn(r"\sqrt{5}", SELF_WRITTEN[7][1])  # self/7, the root example


if __name__ == "__main__":
    unittest.main()
