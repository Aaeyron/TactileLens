"""Back-translate our Braille with Liblouis and compare with the source text.

For each of the 50 corpus text blocks, the Braille our paths produce
(phone and online, Braille 2 and Braille 1) is back-translated with the same
Liblouis table, line by line, and compared with the text that was sent to
Liblouis:

- exact: identical, character for character;
- same words: identical after joining lines with spaces and collapsing
  runs of spaces (a line break written as a blank cell, or the reverse,
  counts as the same).

A back-translation that differs is not necessarily wrong Braille (Liblouis
back-translation is not a perfect inverse); every difference is listed.

Usage (from the repo root):  python -m tools.braille_check.roundtrip
"""

import re
import sys

from tools.braille_check import lou, paths
from tools.braille_check.corpus import TEXT


def _words(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def back(braille: str, table: str) -> str:
    return "\n".join(lou.back_translate(line, table) for line in braille.split("\n"))


def run(corpus: dict[str, str] = TEXT) -> dict:
    results = {}

    for mode in ("braille2", "braille1"):
        for side in ("offline", "online"):
            source_of = paths.offline_text if side == "offline" else paths.server_text
            rows = []

            for key, text in corpus.items():
                source = source_of(text)
                braille = paths.PATHS[(mode, side)](text)
                restored = back(braille, paths.TABLE[mode]).replace("⠀", " ")
                rows.append(
                    {
                        "id": key,
                        "source": source,
                        "back": restored,
                        "exact": restored == source,
                        "same_words": _words(restored) == _words(source),
                    }
                )

            results[f"{mode}/{side}"] = rows

    return results


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    print(f"Liblouis {lou.version()}")

    for key, rows in run().items():
        exact = sum(row["exact"] for row in rows)
        words = sum(row["same_words"] for row in rows)
        print(f"{key}: {exact}/{len(rows)} exact, {words}/{len(rows)} same words")

        for row in rows:
            if not row["same_words"]:
                print(f"  {row['id']}: {row['source']!r}\n      back: {row['back']!r}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
