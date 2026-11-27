"""Resume and crash handling of suggest_vl_resumable.py (no model needed)."""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from suggest_vl_resumable import after_crash, pending, read_done  # noqa: E402


class PendingTest(unittest.TestCase):
    def test_skips_done_and_puts_first_ids_in_front(self):
        jobs = [{"id": name} for name in "abcd"]
        self.assertEqual([j["id"] for j in pending(jobs, {"a"}, {"d"})], ["d", "b", "c"])


class ReadDoneTest(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.path = Path(folder.name) / "out.jsonl"

    def test_missing_file_means_nothing_done(self):
        self.assertEqual(read_done(self.path), set())

    def test_line_cut_off_is_removed_and_read_again(self):
        whole = json.dumps({"id": "a", "blocks": []}) + "\n"
        self.path.write_bytes(whole.encode() + b'{"id": "b", "blo')
        self.assertEqual(read_done(self.path), {"a"})
        self.assertEqual(self.path.read_bytes(), whole.encode())


class AfterCrashTest(unittest.TestCase):
    def test_first_crash_at_an_image_retries_it(self):
        self.assertEqual(after_crash("a", None), (False, "a"))
        self.assertEqual(after_crash("b", "a"), (False, "b"))

    def test_second_crash_in_a_row_skips_it(self):
        self.assertEqual(after_crash("a", "a"), (True, "a"))


if __name__ == "__main__":
    unittest.main()
