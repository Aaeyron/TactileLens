"""Regenerate formula_guard_shared.json from the Python formula guard.

Run from ai_service/ after changing the guard or the normalizer's
vocabulary:

    python -B services/braille/fixtures/generate_formula_guard_fixture.py

Then run both test suites: the Python test checks this file against the
online guard, and the Flutter test checks the offline (Dart) guard against
it. Inputs are self-written; never add scanned or third-party content.
"""

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[2]))  # ai_service/

from services.braille import formula_braille_guard as guard  # noqa: E402
from services.braille.braille_math_normalizer import BrailleMathNormalizer  # noqa: E402

OUTPUT = HERE / "formula_guard_shared.json"

INPUTS = [
    # Supported, not held.
    r"$$ x-5=12 $$",
    r"$$ (x+4)(x-2)=10 $$",
    r"$$ x^{2}+5x+6=0 $$",
    r"\text{area}=l\times w",
    r"\sin x+\cos x=1",
    r"\log_{2}8=3",
    r"\left(\frac{a}{b}\right)^{2}",
    r"\left( \begin{array}{c} 3 \\ 4 \end{array} \right)",
    r"(3 \\ 4)",
    r"\Big(x+1\Big)^{2}",
    r"\bigg(\frac{a}{b}\biggr)",
    r"x=1\quad y=2",
    r"f^{\prime}(x)=2x",
    r"g^{\prime\prime}(x)=6",
    r"\textbf{A}=\mbox{area}",
    r"\begin{aligned}x+1&=4\\x&=3\end{aligned}",
    r"\begin{align*}2x&=8\\x&=4\end{align*}",
    r"\begin{gathered}x=1\\y=2\end{gathered}",
    r"abc=6",
    r"dy+dx=xy",
    r"\text{the total cost per box}=c",
    r"\frac{3}{4}+\frac{1}{4}=1",
    r"2x+3\leq 7",
    r"x\neq 0",
    r"\pi r^{2}",
    "",
    # Held: unsupported LaTeX.
    r"\hat{x}=2",
    r"\overline{AB}=3",
    r"\begin{cases}x=1\end{cases}",
    r"\begin{pmatrix}1&2\end{pmatrix}",
    r"\vec{v}+\hat{u}",
    # Held: alignment markup.
    r"x+1&=4",
    r"x=1\\y=2",
    # Held: English text.
    r"x=2 when y=3",
    r"abc+xyz=6",
    r"\text{the total cost per box now}=c",
    r"Solve for x: 2x+3=7",
    (r"$$ \begin{aligned}&2y+y(4-y)\Big(\frac{y}{2}\Big)when y=-3"
     r"\quad&Put -3 in for y\\&(-3)+(-3)(7)\quad&Multiply first"
     r"\\&-24\quad&Answer\end{aligned} $$"),
    # Held: roots (LaTeX and Unicode).
    r"$$ \sqrt{9}=3 $$",
    r"$$ \sqrt[3]{8}=2 $$",
    r"$$ x=\frac{-b\pm\sqrt{b^{2}-4ac}}{2a} $$",
    r"$ 2\sqrt{5} $",
    "∛27 = 3",
    "∜16 = 2",
    "√x = 4",
    r"\frac{x+1}{2}\leq\sqrt{9}",
    # Held for more than one reason.
    r"$$ Simplify \sqrt{8} $$",
    r"\hat{x}=\sqrt{2} when x>0",
]


def main() -> None:
    cases = []

    for raw in INPUTS:
        review = guard.review_formula(raw, BrailleMathNormalizer.normalize(raw))
        cases.append(
            {
                "input": raw,
                "needs_review": review.needs_review,
                "categories": list(review.categories),
                "reason": review.reason,
                # "Leftover markup" is decided on the normalized text, which
                # the offline app does not have; checked online only.
                "online_only": guard.LEFTOVER_MARKUP in review.categories,
            }
        )

    fixture = {
        "about": (
            "Shared by the online formula guard (ai_service/services/braille/"
            "formula_braille_guard.py) and the offline one (frontend/lib/services/"
            "braille/formula_braille_guard.dart). Both test suites check their "
            "vocabulary and every case against this file, so the two cannot "
            "drift apart. Regenerate from the Python guard when it changes."
        ),
        "vocabulary": {
            "supported_commands": sorted(BrailleMathNormalizer.SUPPORTED_COMMANDS),
            "function_names": sorted(BrailleMathNormalizer.FUNCTION_NAMES),
            "supported_environments": sorted(
                BrailleMathNormalizer.SUPPORTED_ENVIRONMENTS
            ),
            "long_word_length": guard.LONG_WORD_LENGTH,
            "short_word_length": guard.SHORT_WORD_LENGTH,
            "short_word_limit": guard.SHORT_WORD_LIMIT,
            "total_word_limit": guard.TOTAL_WORD_LIMIT,
            "root_symbols": guard.ROOT_SYMBOLS,
            "root_reason": guard.ROOT_REASON,
        },
        "cases": cases,
    }

    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(fixture, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    print(f"{len(cases)} cases written to {OUTPUT.name}")


if __name__ == "__main__":
    main()
