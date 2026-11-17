"""Compare our Braille with the UEB rulebook's own examples.

Every reference item (reference_ueb.json, from the Rules of Unified English
Braille 2024) goes through the phone path and the online path, in Braille 2
and, where the rulebook gives an uncontracted form, Braille 1. For each
mismatch it says where it comes from:

- "our code": Liblouis given the printed text unchanged produces the
  expected Braille, so our preparation of the text changed the result;
- "Liblouis": Liblouis itself, on the unchanged printed text, does not
  produce the expected Braille.

Usage (from the repo root):  python -m tools.braille_check.check_reference
          [--json report.json]
Measures only; it never changes any Braille.
"""

import argparse
import json
import sys
from pathlib import Path

from tools.braille_check import lou, paths

REFERENCE = Path(__file__).resolve().parent / "reference_ueb.json"

MODES = ("braille2", "braille1")
SIDES = ("offline", "online")


def load_reference(path: Path = REFERENCE) -> list[dict]:
    return json.loads(path.read_text(encoding="utf-8"))["items"]


def classify(expected: str, ours: str, liblouis_alone: str) -> str:
    """"match", "our code" or "Liblouis" for one result."""

    if ours == expected:
        return "match"

    return "our code" if liblouis_alone == expected else "Liblouis"


def check(items: list[dict], path_functions=None, translate=None) -> dict:
    """Run every item through every path; returns per-path results."""

    path_functions = path_functions or paths.PATHS
    translate = translate or lou.translate
    results = {}

    for mode in MODES:
        for side in SIDES:
            function = path_functions[(mode, side)]
            rows = []

            for item in items:
                expected = item[mode]

                if expected is None:
                    continue

                ours = function(item["print"])
                alone = translate(item["print"], paths.TABLE[mode])
                rows.append(
                    {
                        "id": item["id"],
                        "category": item["category"],
                        "print": item["print"],
                        "expected": expected,
                        "ours": ours,
                        "liblouis_alone": alone,
                        "result": classify(expected, ours, alone),
                        "source": item["source"],
                    }
                )

            results[f"{mode}/{side}"] = rows

    return results


def summary(results: dict) -> str:
    lines = []

    for key, rows in results.items():
        matches = sum(row["result"] == "match" for row in rows)
        lines.append(f"{key}: {matches}/{len(rows)} exact")

        for row in rows:
            if row["result"] != "match":
                lines.append(
                    f"  {row['id']} [{row['result']}] {row['print']!r} "
                    f"(RUEB {row['source']['rule']}, p. {row['source']['page']})\n"
                    f"      expected {row['expected']}\n"
                    f"      ours     {row['ours']}"
                )

    return "\n".join(lines)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", type=Path, help="also write the full results")
    args = parser.parse_args(argv)

    sys.stdout.reconfigure(encoding="utf-8")
    print(f"Liblouis {lou.version()}")
    results = check(load_reference())
    print(summary(results))

    if args.json:
        args.json.write_text(
            json.dumps(results, ensure_ascii=False, indent=1), encoding="utf-8"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
