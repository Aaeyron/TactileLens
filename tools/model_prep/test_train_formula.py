"""Data lists and the time limit of train_formula.py."""

import unittest
from pathlib import Path

import train_formula as tf

STEP_LINE = ("epoch: [2/10], global_step: 120, lr: 0.000020, loss: 1.5, avg_reader_cost: 0.1 s, "
             "avg_batch_cost: 0.2 s, avg_samples: 4.0, ips: 20.0 samples/s, eta: 0:10:00, "
             "max_mem_reserved: 2000 MB, max_mem_allocated: 1500 MB")


class EpochLists(unittest.TestCase):
    def test_no_extra_list(self):
        self.assertEqual(tf.epoch_lists(Path("t"), 10, []), ([Path("t")], [1.0], 10))

    def test_one_extra_list_matches_the_v2_run(self):
        extra = {"list": Path("x"), "items": 2399}
        self.assertEqual(tf.epoch_lists(Path("t"), 2284, [(extra, 0.9521)]),
                         ([Path("t"), Path("x")], [1.0, 0.9521], 4568))

    def test_two_extra_lists(self):
        first, second = {"list": Path("x"), "items": 100}, {"list": Path("y"), "items": 200}
        lists, ratios, per_epoch = tf.epoch_lists(Path("t"), 10, [(first, 0.5), (second, 0.25)])
        self.assertEqual((lists, ratios, per_epoch), ([Path("t"), Path("x"), Path("y")], [1.0, 0.5, 0.25], 110))


class TimeLimit(unittest.TestCase):
    finished = f"cur metric, exp_rate: 0.5\n{STEP_LINE}\n"

    def test_off_by_default(self):
        self.assertIsNone(tf.time_limit_note(10 ** 6, None, self.finished))

    def test_not_before_the_limit(self):
        self.assertIsNone(tf.time_limit_note(59, 1, self.finished))

    def test_waits_for_a_finished_validation(self):
        self.assertIsNone(tf.time_limit_note(600, 1, STEP_LINE))

    def test_waits_until_training_went_on_after_the_validation(self):
        self.assertIsNone(tf.time_limit_note(600, 1, "cur metric, exp_rate: 0.5\n"))

    def test_stops_after_the_limit(self):
        self.assertEqual(tf.time_limit_note(600, 1, self.finished), "time limit of 1 minutes reached")


if __name__ == "__main__":
    unittest.main()
