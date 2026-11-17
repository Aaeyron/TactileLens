"""Write offline_text_prep_cases.json: input text -> text the phone sends to
Liblouis, by the Python port in paths.py.

frontend/test/services/ai/offline_text_prep_reference_test.dart runs the
real OfflineOcrService on every input and checks it sends exactly this, so
the checker's offline path is known to match the app.

Usage (from the repo root):  python -m tools.braille_check.make_prep_fixture
"""

import json
from pathlib import Path

from tools.braille_check import paths
from tools.braille_check.check_reference import load_reference
from tools.braille_check.corpus import TEXT

FIXTURE = Path(__file__).resolve().parent / "offline_text_prep_cases.json"


def cases() -> list[dict]:
    inputs = [item["print"] for item in load_reference()] + list(TEXT.values())
    return [{"input": text, "sent": paths.offline_text(text)} for text in inputs]


def main() -> int:
    FIXTURE.write_text(
        json.dumps({"cases": cases()}, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )
    print(f"{len(cases())} cases -> {FIXTURE.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
