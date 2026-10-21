import unittest

from services.paddleocr_vl_service import PaddleOcrVlService


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
        # The teacher sees exactly what OCR returned.
        self.assertEqual(block["normalized_content"], HELD_LATEX.strip())
        self.assertEqual(block["content"], HELD_LATEX.strip())
        self.assertEqual(block["raw_content"], HELD_LATEX.strip())

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
