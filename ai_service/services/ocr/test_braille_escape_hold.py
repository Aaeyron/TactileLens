"""Blocks whose Braille contains an undefined-character escape are held.

Liblouis writes a character its tables do not define as an escape such as
'\\x221b', shown in cells as ⠄⡳⠭⠆⠆⠂⠃⠄. Its backslash is an 8-dot cell
(dot 7), which UEB and Nemeth never use, so any cell with dot 7 or 8
means the Braille is not real Braille for that symbol.
"""

import unittest

from services.braille.braille_translation_service import BrailleTranslationService
from services.braille.formula_braille_guard import (
    UNSUPPORTED_SYMBOL,
    UNSUPPORTED_SYMBOL_REASON,
    contains_braille_escape,
)
from services.ocr.paddleocr_vl_service import PaddleOcrVlService

try:
    _LIBLOUIS = BrailleTranslationService()
except FileNotFoundError:
    _LIBLOUIS = None

ESCAPED = "⠠⠋⠔⠙⠀⠄⡳⠭⠆⠆⠂⠃⠄⠼⠃⠛"  # "Find ∛27" in UEB
CLEAN = "⠠⠋⠔⠙⠀⠼⠃⠛"


class _FixedTranslator:
    def __init__(self, content):
        self.content = content
        self.calls = []

    def translate_block(self, content, *, is_formula, is_table=False):
        self.calls.append(content)
        return {
            "success": True,
            "code": "nemeth" if is_formula or is_table else "ueb",
            "content": self.content,
            "error": None,
        }


def _service(translator):
    service = PaddleOcrVlService.__new__(PaddleOcrVlService)
    service.debug_blocks = False
    service._braille_translator = translator
    return service


def _block(label, content):
    return {
        "block_label": label,
        "block_content": content,
        "block_bbox": [0, 0, 10, 10],
        "block_id": 0,
        "block_order": 1,
    }


class BrailleEscapeDetectionTests(unittest.TestCase):
    def test_eight_dot_cells_are_escapes(self):
        self.assertTrue(contains_braille_escape(ESCAPED))
        self.assertTrue(contains_braille_escape("⣿"))
        self.assertTrue(contains_braille_escape("⢀"))

    def test_six_dot_braille_and_spaces_are_not(self):
        self.assertFalse(contains_braille_escape(CLEAN))
        self.assertFalse(contains_braille_escape("⠀⠿\n⠁"))
        self.assertFalse(contains_braille_escape(""))

    def test_reason_text(self):
        self.assertEqual(
            UNSUPPORTED_SYMBOL_REASON,
            "contains a symbol our Braille tables don't support",
        )


class BrailleEscapeHoldTests(unittest.TestCase):
    def _serialize(self, label, content, braille):
        service = _service(_FixedTranslator(braille))
        return service._serialize_block(
            _block(label, content), fallback_id=0, fallback_order=0
        )

    def test_text_block_with_an_escape_is_held(self):
        block = self._serialize("text", "Find ∛27", ESCAPED)

        self.assertTrue(block["needs_review"])
        self.assertEqual(block["review_reason"], UNSUPPORTED_SYMBOL_REASON)
        self.assertFalse(block["braille_success"])
        self.assertEqual(block["braille_content"], "")
        self.assertEqual(block["braille_code"], "ueb")
        self.assertEqual(
            block["braille_error"], f"Needs review: {UNSUPPORTED_SYMBOL_REASON}"
        )
        # Text stays as read.
        self.assertEqual(block["normalized_content"], "Find ∛27")

    def test_formula_with_an_escape_is_held(self):
        block = self._serialize("display_formula", r"$$ x-5=12 $$", ESCAPED)

        self.assertTrue(block["needs_review"])
        self.assertEqual(block["review_reason"], UNSUPPORTED_SYMBOL_REASON)
        self.assertEqual(block["braille_content"], "")
        self.assertEqual(block["braille_code"], "nemeth")
        self.assertEqual(block["raw_content"], r"$$ x-5=12 $$")

    def test_table_with_an_escape_is_held_and_keeps_its_rows(self):
        table = "<table><tr><td>a</td><td>b</td></tr></table>"
        block = self._serialize("table", table, ESCAPED)

        self.assertTrue(block["needs_review"])
        self.assertEqual(block["review_reason"], UNSUPPORTED_SYMBOL_REASON)
        self.assertEqual(block["braille_content"], "")
        self.assertEqual(block["table_rows"], [["a", "b"]])
        self.assertEqual(block["normalized_content"], "Table\nRow 1: a; b\nEnd table")

    def test_clean_braille_is_kept(self):
        for label, content in (
            ("text", "Find 27"),
            ("display_formula", r"$$ x-5=12 $$"),
            ("table", "<table><tr><td>a</td></tr></table>"),
        ):
            with self.subTest(label=label):
                block = self._serialize(label, content, CLEAN)

                self.assertFalse(block["needs_review"])
                self.assertEqual(block["review_reason"], "")
                self.assertTrue(block["braille_success"])
                self.assertEqual(block["braille_content"], CLEAN)

    @unittest.skipIf(_LIBLOUIS is None, "Liblouis runtime not installed")
    def test_a_cube_root_in_ueb_text_is_held_with_real_liblouis(self):
        service = _service(_LIBLOUIS)

        held = service._serialize_block(
            _block("text", "Find ∛27 now."), fallback_id=0, fallback_order=0
        )
        self.assertTrue(held["needs_review"])
        self.assertEqual(held["review_reason"], UNSUPPORTED_SYMBOL_REASON)
        self.assertEqual(held["braille_content"], "")

        # UEB has superscript digits, so this text is not held.
        kept = service._serialize_block(
            _block("text", "Write x² + 1 here."), fallback_id=0, fallback_order=0
        )
        self.assertFalse(kept["needs_review"])
        self.assertTrue(kept["braille_content"])
        self.assertFalse(contains_braille_escape(kept["braille_content"]))

    def test_category_name(self):
        self.assertEqual(UNSUPPORTED_SYMBOL, "unsupported_symbol")


if __name__ == "__main__":
    unittest.main()
