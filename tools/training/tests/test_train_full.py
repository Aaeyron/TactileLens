"""Batch-size fallback of train_full.py (no training is run).

From tools/training:  python -m unittest discover -s tests -t .
"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import train_full  # noqa: E402


class FallbackTest(unittest.TestCase):
    def test_sizes(self):
        self.assertEqual(train_full.fallback_sizes(64, "48,32"), [64, 48, 32])
        self.assertEqual(train_full.fallback_sizes(48, "48,32"), [48, 32])
        self.assertEqual(train_full.fallback_sizes(16, "48,32"), [16])

    def test_uses_the_first_size_that_fits(self):
        tried = []

        def attempt(batch):
            tried.append(batch)
            return {"outcome": "oom" if batch > 32 else "early_stop"}

        batch, result, attempts = train_full.train_with_fallback([64, 48, 32], attempt)
        self.assertEqual((batch, result["outcome"]), (32, "early_stop"))
        self.assertEqual(tried, [64, 48, 32])
        self.assertEqual([a["outcome"] for a in attempts], ["oom", "oom", "early_stop"])

    def test_no_retry_when_it_fits(self):
        batch, _, attempts = train_full.train_with_fallback([64, 48, 32], lambda b: {"outcome": "finished"})
        self.assertEqual((batch, len(attempts)), (64, 1))

    def test_other_errors_are_not_retried(self):
        batch, result, _ = train_full.train_with_fallback([64, 48], lambda b: {"outcome": "error"})
        self.assertEqual((batch, result["outcome"]), (64, "error"))

    def test_stops_when_nothing_fits(self):
        with self.assertRaises(SystemExit):
            train_full.train_with_fallback([64, 48, 32], lambda b: {"outcome": "oom"})

    def test_oom_messages_are_recognised(self):
        for line in ("ResourceExhaustedError: Out of memory error on GPU 0",
                     "cudaErrorMemoryAllocation", "CUDA error(2), out of memory",
                     "CUDNN error(4003), CUDNN_STATUS_INTERNAL_ERROR_HOST_ALLOCATION_FAILED"):
            self.assertTrue(any(s in line for s in train_full.OOM_SIGNS) or "out of memory" in line.lower(), line)


if __name__ == "__main__":
    unittest.main()
