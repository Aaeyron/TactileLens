import unittest

from services.braille.braille_translation_service import BrailleTranslationService
from services.braille.formula_braille_guard import ROOT_REASON
from services.braille.test_formula_braille_guard import ROOT_CASES
from services.ocr.paddleocr_vl_service import PaddleOcrVlService

try:
    _LIBLOUIS = BrailleTranslationService()
except FileNotFoundError:
    _LIBLOUIS = None

ROOT_TABLE = "<table><tr><td>x</td><td>√x</td></tr><tr><td>4</td><td>2</td></tr></table>"
ROOT_TABLE_TEXT = "Table\nRow 1: x; √x\nRow 2: 4; 2\nEnd table"


class _RecordingTranslator:
    def __init__(self):
        self.calls = []

    def translate_block(self, content, *, is_formula, is_table=False):
        self.calls.append(content)
        return {
            "success": True,
            "code": "nemeth" if is_formula or is_table else "ueb",
            "content": "BRAILLE",
            "error": None,
        }


def _service():
    service = PaddleOcrVlService.__new__(PaddleOcrVlService)
    service.debug_blocks = False
    service._braille_translator = _RecordingTranslator()
    return service


def _block(label, content):
    return {
        "block_label": label,
        "block_content": content,
        "block_bbox": [0, 0, 10, 10],
        "block_id": 0,
        "block_order": 1,
    }


HELD_LATEX = (
    r" $$ \begin{aligned}&2y+3\quad&Add three\\&5\quad&Answer"
    r"\end{aligned} $$ "
)


class FormulaReviewSerializationTests(unittest.TestCase):
    def test_held_formula_is_never_translated(self):
        service = _service()

        block = service._serialize_block(
            _block("display_formula", HELD_LATEX),
            fallback_id=0,
            fallback_order=0,
        )

        self.assertEqual(service._braille_translator.calls, [])
        self.assertTrue(block["needs_review"])
        self.assertTrue(block["review_reason"])
        self.assertFalse(block["braille_success"])
        self.assertEqual(block["braille_content"], "")
        self.assertEqual(block["braille_code"], "nemeth")
        self.assertEqual(
            block["braille_error"],
            f"Needs review: {block['review_reason']}",
        )
        # Readable text for the teacher; the original LaTeX is kept.
        self.assertEqual(block["normalized_content"], "2y + 3 Add three\n5 Answer")
        self.assertEqual(block["content"], block["normalized_content"])
        self.assertEqual(block["raw_content"], HELD_LATEX.strip())

    def test_a_held_instruction_and_fraction_reads_cleanly(self):
        # Shaped like the reported block: an instruction line and a
        # fraction read as one formula. Still no Braille.
        latex = (
            r"$$ Example: Perform the division and simplify your answer. "
            r"\frac{2\sqrt{5}-4}{7} $$"
        )
        service = _service()

        block = service._serialize_block(
            _block("display_formula", latex),
            fallback_id=0,
            fallback_order=0,
        )

        self.assertTrue(block["needs_review"])
        self.assertEqual(service._braille_translator.calls, [])
        self.assertEqual(block["braille_content"], "")
        self.assertEqual(
            block["normalized_content"],
            "Example: Perform the division and simplify your answer. (2√5 − 4)/7",
        )
        self.assertEqual(block["raw_content"], latex.strip())

    # Add the teacher's real held block here when available:
    # def test_reported_block(self): ...

    def test_supported_formula_is_translated(self):
        service = _service()

        block = service._serialize_block(
            _block("display_formula", " $$ x-5=12 $$ "),
            fallback_id=0,
            fallback_order=0,
        )

        self.assertEqual(service._braille_translator.calls, ["x-5=12"])
        self.assertFalse(block["needs_review"])
        self.assertEqual(block["review_reason"], "")
        self.assertTrue(block["braille_success"])

    def test_text_and_tables_are_not_reviewed(self):
        service = _service()

        for label, content in (
            ("text", "Write the answer when you are ready."),
            ("table", "<table><tr><td>a</td><td>b</td></tr></table>"),
        ):
            with self.subTest(label=label):
                block = service._serialize_block(
                    _block(label, content),
                    fallback_id=0,
                    fallback_order=0,
                )

                self.assertFalse(block["needs_review"])
                self.assertEqual(block["review_reason"], "")

        self.assertEqual(len(service._braille_translator.calls), 2)

    def test_a_formula_with_a_root_is_held(self):
        service = _service()

        block = service._serialize_block(
            _block("display_formula", r" $$ \sqrt{9}=3 $$ "),
            fallback_id=0,
            fallback_order=0,
        )

        self.assertEqual(service._braille_translator.calls, [])
        self.assertTrue(block["needs_review"])
        self.assertEqual(block["review_reason"], ROOT_REASON)
        self.assertFalse(block["braille_success"])
        self.assertEqual(block["braille_content"], "")
        self.assertEqual(block["braille_error"], f"Needs review: {ROOT_REASON}")
        self.assertEqual(block["normalized_content"], "√9 = 3")
        self.assertEqual(block["raw_content"], r"$$ \sqrt{9}=3 $$")

    def test_a_table_with_a_root_keeps_its_row_text(self):
        service = _service()

        block = service._serialize_block(
            _block("table", ROOT_TABLE),
            fallback_id=0,
            fallback_order=0,
        )

        self.assertEqual(service._braille_translator.calls, [])
        self.assertTrue(block["is_table"])
        self.assertTrue(block["needs_review"])
        self.assertEqual(block["review_reason"], ROOT_REASON)
        self.assertFalse(block["braille_success"])
        self.assertEqual(block["braille_content"], "")
        # The row text, never the raw HTML.
        self.assertEqual(block["normalized_content"], ROOT_TABLE_TEXT)
        self.assertEqual(block["table_rows"], [["x", "√x"], ["4", "2"]])
        self.assertEqual(block["raw_content"], ROOT_TABLE)

    @unittest.skipIf(_LIBLOUIS is None, "Liblouis runtime not installed")
    def test_no_root_reaches_braille_as_an_escape(self):
        # Liblouis writes an undefined character as '\x221a', shown in
        # Braille cells as ⠄⡳⠭⠆⠆⠂⠁⠄.
        service = PaddleOcrVlService.__new__(PaddleOcrVlService)
        service.debug_blocks = False
        service._braille_translator = _LIBLOUIS

        cases = [("display_formula", latex) for latex in ROOT_CASES]
        cases.append(("table", ROOT_TABLE))

        for label, content in cases:
            with self.subTest(content=content):
                block = service._serialize_block(
                    _block(label, content),
                    fallback_id=0,
                    fallback_order=0,
                )

                self.assertTrue(block["needs_review"])

                for escape in ("⡳", "'\\x", "\\x"):
                    self.assertNotIn(escape, block["braille_content"])

    def test_guard_counts_are_logged(self):
        service = _service()
        service._guard_counts_lock = __import__("threading").Lock()
        service._formulas_checked = 0
        service._formulas_held = 0

        blocks = [
            service._serialize_block(
                _block("display_formula", latex),
                fallback_id=index,
                fallback_order=index,
            )
            for index, latex in enumerate((HELD_LATEX, " $$ x-5=12 $$ "))
        ]

        service._log_formula_reviews(blocks)
        service._log_formula_reviews(blocks)

        self.assertEqual(service._formulas_checked, 4)
        self.assertEqual(service._formulas_held, 2)


if __name__ == "__main__":
    unittest.main()
