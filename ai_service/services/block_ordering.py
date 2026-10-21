"""Give every OCR block a unique reading order and id.

PaddleOCR-VL can return block_order (and block_id) as null, for example
for page headers, page numbers or a lone table. Falling back to the
block's list position could repeat a real block_order, and the saved
text is built by sorting on "order".

A block with a null order keeps its place in the list: it is read right
after the closest earlier block that has a real order, or first if there
is none. Orders are then renumbered 1..n, so they are always unique.
"""

from typing import Any


def assign_identities(raw_blocks: list[dict[str, Any]]) -> list[tuple[int, int]]:
    """Return a unique (id, order) for each block, in list order."""

    orders = _assign_orders(raw_blocks)
    ids = _assign_ids(raw_blocks)

    return list(zip(ids, orders))


def _assign_orders(raw_blocks: list[dict[str, Any]]) -> list[int]:
    sort_keys: list[tuple[float, int, int]] = []
    previous_order = float("-inf")

    for index, block in enumerate(raw_blocks):
        order = _integer_or_none(block.get("block_order"))

        if order is None:
            # After the earlier block's order, before the next real one.
            sort_keys.append((previous_order, 1, index))
        else:
            sort_keys.append((order, 0, index))
            previous_order = order

    ranked = sorted(range(len(raw_blocks)), key=lambda index: sort_keys[index])
    orders = [0] * len(raw_blocks)

    for rank, index in enumerate(ranked, start=1):
        orders[index] = rank

    return orders


def _assign_ids(raw_blocks: list[dict[str, Any]]) -> list[int]:
    received = [_integer_or_none(block.get("block_id")) for block in raw_blocks]
    used: set[int] = set()
    ids: list[int | None] = []

    # Keep each real id the first time it appears.
    for block_id in received:
        if block_id is None or block_id in used:
            ids.append(None)
        else:
            ids.append(block_id)
            used.add(block_id)

    next_id = max(used, default=-1) + 1

    for index, block_id in enumerate(ids):
        if block_id is None:
            ids[index] = next_id
            next_id += 1

    return [block_id for block_id in ids if block_id is not None]


def _integer_or_none(value: Any) -> int | None:
    # Same conversion as PaddleOcrVlService._integer_or_default.
    if value is None:
        return None

    try:
        return int(value)
    except (TypeError, ValueError):
        return None
