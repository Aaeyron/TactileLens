import types
import unittest

from services.ocr.block_ordering import assign_identities
from services.ocr.paddleocr_vl_service import PaddleOcrVlService


def _blocks(*pairs):
    """Blocks from (block_id, block_order) pairs; None means null."""

    return [
        {"block_id": block_id, "block_order": order} for block_id, order in pairs
    ]


def _orders(blocks):
    return [order for _, order in assign_identities(blocks)]


def _ids(blocks):
    return [block_id for block_id, _ in assign_identities(blocks)]


class BlockOrderingTests(unittest.TestCase):
    def test_real_orders_are_kept_in_sequence(self):
        self.assertEqual(_orders(_blocks((0, 1), (1, 2), (2, 3))), [1, 2, 3])

    def test_gaps_are_renumbered(self):
        self.assertEqual(_orders(_blocks((0, 3), (1, 7), (2, 12))), [1, 2, 3])

    def test_null_first_is_read_first(self):
        # A page header before the title: [null, 1, 2].
        self.assertEqual(_orders(_blocks((0, None), (1, 1), (2, 2))), [1, 2, 3])

    def test_null_in_the_middle_follows_the_block_before_it(self):
        self.assertEqual(
            _orders(_blocks((0, 1), (1, None), (2, 2), (3, 3))),
            [1, 2, 3, 4],
        )

    def test_null_last_is_read_last(self):
        # A page number after the last block.
        self.assertEqual(
            _orders(_blocks((0, None), (1, 1), (2, 2), (3, None))),
            [1, 2, 3, 4],
        )

    def test_a_null_cannot_collide_with_a_real_order(self):
        # With the old list-position fallback this null became order 1,
        # the same as the first block.
        orders = _orders(_blocks((0, 1), (1, None), (2, 2)))

        self.assertEqual(len(set(orders)), 3)
        self.assertEqual(orders, [1, 2, 3])

    def test_all_null_keeps_list_order(self):
        self.assertEqual(_orders(_blocks((None, None), (None, None))), [1, 2])

    def test_a_lone_null_block_gets_order_one(self):
        self.assertEqual(_orders(_blocks((0, None))), [1])

    def test_duplicate_orders_keep_list_order(self):
        self.assertEqual(_orders(_blocks((0, 2), (1, 2), (2, 1))), [2, 3, 1])

    def test_reading_order_follows_block_order_not_list_position(self):
        self.assertEqual(_orders(_blocks((0, 3), (1, 1), (2, 2))), [3, 1, 2])

    def test_invalid_orders_count_as_null(self):
        self.assertEqual(_orders(_blocks((0, 1), (1, "x"), (2, 2))), [1, 2, 3])

    def test_null_and_duplicate_ids_get_unused_numbers(self):
        self.assertEqual(
            _ids(_blocks((0, 1), (None, 2), (1, 3), (1, 4), (None, 5))),
            [0, 2, 1, 3, 4],
        )

    def test_results_are_always_unique(self):
        blocks = _blocks((None, None), (5, 2), (5, None), (None, 2), (1, 9))
        identities = assign_identities(blocks)

        self.assertEqual(len({block_id for block_id, _ in identities}), 5)
        self.assertEqual(
            sorted(order for _, order in identities),
            [1, 2, 3, 4, 5],
        )

    def test_empty_page(self):
        self.assertEqual(assign_identities([]), [])


class _Translator:
    def translate_block(self, content, *, is_formula, is_table=False):
        return {"success": True, "code": "ueb", "content": "B", "error": None}


class SerializedPageOrderTests(unittest.TestCase):
    def test_page_blocks_get_unique_ids_and_orders(self):
        service = PaddleOcrVlService.__new__(PaddleOcrVlService)
        service.debug_blocks = False
        service._braille_translator = _Translator()

        page = {
            "parsing_res_list": [
                {"block_label": "header", "block_content": "Unit 2",
                 "block_id": 0, "block_order": None},
                {"block_label": "text", "block_content": "Read the notes.",
                 "block_id": 1, "block_order": 1},
                {"block_label": "number", "block_content": "7",
                 "block_id": None, "block_order": None},
            ]
        }

        result = service._serialize_page(
            types.SimpleNamespace(json=page),
            fallback_page_index=0,
            fallback_width=100,
            fallback_height=100,
        )

        self.assertEqual([block["order"] for block in result["blocks"]], [1, 2, 3])
        self.assertEqual([block["id"] for block in result["blocks"]], [0, 1, 2])
        self.assertEqual(
            [block["type"] for block in result["blocks"]],
            ["header", "text", "number"],
        )


if __name__ == "__main__":
    unittest.main()
