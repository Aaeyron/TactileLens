"""Online holds for math whose Braille would read as another formula.

The rules and reasons are the app's on-device holds; the shared fixture
(services/braille/fixtures/meaning_holds_shared.json) is checked here and by
frontend/test/services/braille/offline_braille_holds_test.dart.
"""

import json
import unittest
from pathlib import Path

from services.braille import meaning_holds as holds
from services.ocr.paddleocr_vl_service import PaddleOcrVlService

FIXTURE = (
    Path(__file__).resolve().parent.parent
    / "braille"
    / "fixtures"
    / "meaning_holds_shared.json"
)


class _RecordingTranslator:
    def __init__(self):
        self.calls = []

    def translate_block(self, content, *, is_formula, is_table=False):
        self.calls.append(content)
        return {
            "success": True,
            "code": "nemeth" if is_formula or is_table else "ueb",
            "content": "⠃⠗⠇",
            "error": None,
        }


def _service(translator):
    service = PaddleOcrVlService.__new__(PaddleOcrVlService)
    service.debug_blocks = False
    service._braille_translator = translator
    return service


def _serialize(service, label, content):
    return service._serialize_block(
        {
            "block_label": label,
            "block_content": content,
            "block_bbox": [0, 0, 10, 10],
            "block_id": 0,
            "block_order": 1,
        },
        fallback_id=0,
        fallback_order=1,
    )


class SharedFixtureTests(unittest.TestCase):
    def test_every_case_matches_the_rules(self):
        fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))

        self.assertEqual(
            fixture["reasons"],
            {
                holds.RELATION_SIGN: holds.RELATION_SIGN_REASON,
                holds.SCRIPT_GROUPING: holds.SCRIPT_GROUPING_REASON,
                holds.SET_BRACES: holds.SET_BRACES_REASON,
            },
        )

        for case in fixture["cases"]:
            with self.subTest(case["input"]):
                review = holds.review_meaning(case["input"])
                self.assertEqual(review.needs_review, case["needs_review"])
                self.assertEqual(list(review.categories), case["categories"])
                self.assertEqual(review.reason, case["reason"])


class ServerPathTests(unittest.TestCase):
    def test_held_formulas_get_no_braille_and_a_plain_reason(self):
        expected = {
            r"$$ a\neq 0 $$": holds.RELATION_SIGN_REASON,
            r"$$ 3x-5\leq 10 $$": holds.RELATION_SIGN_REASON,
            r"$$ 2^{x+1}=8 $$": holds.SCRIPT_GROUPING_REASON,
            r"$$ \{1,2,3\} $$": holds.SET_BRACES_REASON,
        }

        translator = _RecordingTranslator()
        service = _service(translator)

        for content, reason in expected.items():
            with self.subTest(content):
                block = _serialize(service, "display_formula", content)
                self.assertTrue(block["needs_review"])
                self.assertEqual(block["review_reason"], reason)
                self.assertEqual(block["braille_content"], "")

        self.assertEqual(translator.calls, [], "nothing held reaches Liblouis")

    def test_other_formulas_and_text_are_still_translated(self):
        translator = _RecordingTranslator()
        service = _service(translator)

        for label, content in [
            ("display_formula", r"$$ x^{2}-5x+6=0 $$"),
            ("display_formula", r"$$ 3x^{2}y $$"),
            ("text", "Solve each inequality: x is at least 2."),
        ]:
            with self.subTest(content):
                block = _serialize(service, label, content)
                self.assertFalse(block["needs_review"])
                self.assertEqual(block["braille_content"], "⠃⠗⠇")

        self.assertEqual(len(translator.calls), 3)

    def test_the_shared_guard_keeps_its_own_reason(self):
        block = _serialize(
            _service(_RecordingTranslator()),
            "display_formula",
            r"$$ \sqrt{x}\leq 3 $$",
        )

        self.assertTrue(block["needs_review"])
        self.assertIn("root", block["review_reason"])
        self.assertNotIn("≠, ≤", block["review_reason"])

    def test_a_table_row_with_a_relation_sign_is_held(self):
        translator = _RecordingTranslator()
        block = _serialize(
            _service(translator),
            "table",
            "<table><tr><td>x ≤ 3</td><td>y = 2</td></tr></table>",
        )

        self.assertTrue(block["needs_review"])
        self.assertEqual(block["review_reason"], holds.RELATION_SIGN_REASON)
        self.assertEqual(translator.calls, [])


if __name__ == "__main__":
    unittest.main()
