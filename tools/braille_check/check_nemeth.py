"""Compare our Nemeth with examples from the Nemeth Code 2022 (BANA).

Every example in reference_nemeth.json goes through the formula path (the
AI service's BrailleMathNormalizer and BrailleTranslationService.
translate_formula; the app's Kotlin port gives the same Nemeth input) and
through Liblouis alone, on the unchanged print. A mismatch is put down to
"our code" when Liblouis alone gives the expected Braille, otherwise to
"Liblouis". A space Liblouis writes as U+0020 or U+00A0 counts as the blank
cell, and
blank cells at the very start or end are not compared.

The reference leaves out the Nemeth opening and closing indicators the
book puts around every example; our blocks do not write them (a separate
question on the expert list).

Usage (from the repo root):  python -m tools.braille_check.check_nemeth [--json out]
Measures only; it never changes any Braille.
"""

import argparse
import json
import sys
from pathlib import Path

from tools.braille_check import lou, paths
from tools.braille_check.check_reference import classify

REFERENCE = Path(__file__).resolve().parent / "reference_nemeth.json"


def load_reference(path: Path = REFERENCE) -> list[dict]:
    return json.loads(path.read_text(encoding="utf-8"))["items"]


def cells(braille: str) -> str:
    """Liblouis writes some blank cells as a space (U+0020) or a no-break
    space (U+00A0, around ≠ ≤ ≥); blank cells at the very start or end
    (around a lone sign) are not compared."""

    return braille.replace(" ", "⠀").replace(" ", "⠀").strip("⠀")


def server_nemeth(print_text: str) -> str:
    paths._server()  # puts ai_service on sys.path
    from services.braille.braille_math_normalizer import BrailleMathNormalizer
    from services.braille.braille_translation_service import (
        BrailleTranslationService,
    )

    return BrailleTranslationService().translate_formula(
        BrailleMathNormalizer.normalize(print_text)
    )


def check(items: list[dict], ours=None, translate=None) -> list[dict]:
    ours = ours or server_nemeth
    translate = translate or lou.translate
    rows = []

    for item in items:
        expected = item["nemeth"]
        result = cells(ours(item["print"]))
        alone = cells(translate(item["print"], lou.NEMETH))
        rows.append(
            {
                "id": item["id"],
                "print": item["print"],
                "expected": expected,
                "ours": result,
                "liblouis_alone": alone,
                "result": classify(expected, result, alone),
                "source": item["source"],
            }
        )

    return rows


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", type=Path)
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    rows = check(load_reference())
    matches = sum(row["result"] == "match" for row in rows)
    print(f"Liblouis {lou.version()}: {matches}/{len(rows)} exact")

    for row in rows:
        if row["result"] != "match":
            print(
                f"  {row['id']} [{row['result']}] {row['print']!r} "
                f"(Nemeth 2022, example {row['source']['example']})\n"
                f"      expected {row['expected']}\n"
                f"      ours     {row['ours']}\n"
                f"      Liblouis alone {row['liblouis_alone']}"
            )

    if args.json:
        args.json.write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
