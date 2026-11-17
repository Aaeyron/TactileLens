"""A fixed sample of our Braille for the Braille expert to check.

20 corpus sentences in Braille 2 and in Braille 1 (the phone's path; the
online Braille 2 is shown too when it differs), and 10 corpus formulas in
Nemeth (the AI service's normalizer and Nemeth step, which give the same
Nemeth input as the app's Kotlin port for all 25 corpus formulas). The IDs
are fixed so the sample is the same every time.

Usage (from the repo root):  python -m tools.braille_check.expert_sample [out.json]
"""

import json
import sys
from pathlib import Path

from tools.braille_check import lou, paths
from tools.braille_check.corpus import FORMULA, TEXT

SENTENCES = (
    "t01", "t02", "t03", "t04", "t05", "t06", "t07", "t10", "t11", "t12",
    "t14", "t16", "t18", "t19", "t21", "t23", "t24", "t26", "t28", "t49",
)
FORMULAS = ("f01", "f02", "f03", "f05", "f06", "f07", "f09", "f10", "f15", "f17")


def _formula_braille(latex: str) -> tuple[str, str]:
    paths._server()  # puts ai_service on sys.path
    from services.braille.braille_math_normalizer import BrailleMathNormalizer
    from services.braille.braille_translation_service import (
        BrailleTranslationService,
    )

    nemeth_input = BrailleMathNormalizer.normalize(latex)
    return nemeth_input, BrailleTranslationService().translate_formula(nemeth_input)


def build() -> dict:
    sentences = []

    for key in SENTENCES:
        text = TEXT[key]
        braille2 = paths.offline_braille2(text)
        online2 = paths.server_braille2(text)
        sentences.append(
            {
                "id": key,
                "print": text,
                "braille2": braille2,
                "braille2_online": None if online2 == braille2 else online2,
                "braille1": paths.offline_braille1(text),
            }
        )

    formulas = []

    for key in FORMULAS:
        nemeth_input, braille = _formula_braille(FORMULA[key])
        formulas.append(
            {"id": key, "latex": FORMULA[key], "linear": nemeth_input, "nemeth": braille}
        )

    return {"liblouis": lou.version(), "sentences": sentences, "formulas": formulas}


def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    sys.stdout.reconfigure(encoding="utf-8")
    sample = build()
    text = json.dumps(sample, ensure_ascii=False, indent=1)

    if argv:
        Path(argv[0]).write_text(text, encoding="utf-8")
        print(f"{len(sample['sentences'])} sentences, {len(sample['formulas'])} formulas")
    else:
        print(text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
