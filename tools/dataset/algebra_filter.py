"""Keep only algebra-level formulas from a public LaTeX dataset.

For the preliminary run (Track A, PP-FormulaNet_plus-S) on a public
printed dataset such as im2latex-100k (CC0) before our own data is ready.
Works on labels only (no download in this script):

  python algebra_filter.py --labels in.tsv --out kept.tsv [--report report.md]

  in.tsv   <image path><TAB><latex>  (one per line; export a dataset's
           labels to this first)

Kept when ALL hold (the topics of DATASET_PLAN.md: fractions, exponents,
radicals, linear and quadratic equations, inequalities, polynomials,
function notation):
  - every command is in ALLOWED (frac, sqrt, cdot, times, div, pm, le/ge,
    neq, left/right, spacing, a few Greek letters used in algebra)
  - at most MAX_TOKENS tokens, at most 2 levels of braces in exponents
  - no environments (\\begin...), no \\mathbf/\\mathcal/... fonts, no
    sums, integrals, limits, matrices, accents
  - at least one algebra feature: =, <, >, \\le, \\ge, ^, \\frac, \\sqrt, f(x)
Everything else is dropped with a reason (counted in the report).
"""

from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path

ALLOWED = {
    "frac", "dfrac", "tfrac", "sqrt", "cdot", "times", "div", "pm", "mp",
    "le", "leq", "ge", "geq", "neq", "ne", "lt", "gt", "approx",
    "left", "right", "quad", "qquad", ",", ";", ":", "!", " ",
    "ldots", "cdots", "dots", "pi", "alpha", "beta", "theta",
    "{", "}", "%", "mathrm", "text",
}
FORBIDDEN_HINT = {
    "begin": "environment", "end": "environment", "sum": "sum", "int": "integral", "lim": "limit",
    "mathbf": "font", "mathcal": "font", "mathbb": "font", "boldsymbol": "font", "operatorname": "operator",
    "hat": "accent", "bar": "accent", "vec": "accent", "tilde": "accent", "dot": "accent",
    "partial": "calculus", "infty": "calculus", "prod": "product", "matrix": "matrix",
}
MAX_TOKENS = 60
TOKEN = re.compile(r"\\[A-Za-z]+|\\.|[{}^_]|[A-Za-z]|\d|[^\sA-Za-z\d]")
FEATURE = re.compile(r"=|<|>|\\le|\\ge|\\leq|\\geq|\\neq|\^|\\frac|\\sqrt|\b[fgh]\s*\(\s*[a-z]\s*\)")


def reason_to_drop(latex: str) -> str | None:
    text = latex.strip().strip("$")
    if not text:
        return "empty"
    tokens = TOKEN.findall(text)
    if len(tokens) > MAX_TOKENS:
        return "too long"
    for token in tokens:
        if token.startswith("\\") and len(token) > 1:
            name = token[1:]
            if name not in ALLOWED:
                return FORBIDDEN_HINT.get(name, f"command \\{name}")
    if "_" in tokens and not re.search(r"[a-z]_\{?\d\}?", text):
        return "subscript beyond x_1"
    depth = max_depth = 0
    for c in text:
        depth += c == "{"
        depth -= c == "}"
        max_depth = max(max_depth, depth)
    if max_depth > 3:
        return "deep nesting"
    letters = set(re.findall(r"(?<!\\)\b[A-Za-z]{4,}\b", re.sub(r"\\[A-Za-z]+", " ", text)))
    if letters - {"text"}:
        return "words (not a formula)"
    if not FEATURE.search(text):
        return "no algebra feature"
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--labels", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--report")
    args = parser.parse_args()

    kept, dropped = [], Counter()
    for line in Path(args.labels).read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        image, latex = line.split("\t", 1)
        why = reason_to_drop(latex)
        if why:
            dropped[why] += 1
        else:
            kept.append(f"{image}\t{latex.strip()}")
    Path(args.out).write_text("\n".join(kept) + ("\n" if kept else ""), encoding="utf-8")
    total = len(kept) + sum(dropped.values())
    lines = [f"# Algebra filter: {len(kept)} of {total} kept", "", "| dropped because | count |", "|---|---|"]
    lines += [f"| {why} | {n} |" for why, n in dropped.most_common()]
    if args.report:
        Path(args.report).write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
