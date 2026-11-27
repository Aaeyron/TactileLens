"""Count readings with repeated tokens in evaluate_formula.py predictions.tsv files.

A reading is counted once if it has any of:
  stutter  - a command word glued to itself: fracfrac, sqrtsqrt, quadquad, ... (any count of repeats)
  ^^ / __  - two superscript or two subscript marks in a row
  braces   - more '{{' or '}}' than the target has (nested groups like \\frac{1}{x^{2}} are legitimate)
  \\\\     - more doubled backslashes than the target has
  run3     - the same character three or more times in a row where the target has no such run (e.g. 'ccc')

The original model's hits are mostly \\begin{array}/\\begin{aligned} wrappers, which use
{{}} and \\\\ by design; a stutter (fracfrac) is a different failure. Both are listed per reading.

usage (paddle_onnx_env, from tools/offline_math_model):
  python repeated_tokens.py name=<predictions.tsv> [name=<predictions.tsv> ...]
"""
import csv
import re
import sys

WORDS = "frac|dfrac|sqrt|quad|qquad|cdot|times|left|right|pm|mp|leq|geq|neq|div|text|mathrm|textcircled|bullet|cfrac"
STUTTER = re.compile(rf"({WORDS})\1")
CARETS = re.compile(r"\^\^|__")
RUN3 = re.compile(r"([^\s])\1\1")


def problems(target: str, prediction: str) -> list[str]:
    found = []
    if STUTTER.search(prediction) and not STUTTER.search(target):
        found.append("stutter")
    if CARETS.search(prediction):
        found.append("^^ / __")
    if prediction.count("{{") > target.count("{{") or prediction.count("}}") > target.count("}}"):
        found.append("braces")
    if prediction.count("\\\\") > target.count("\\\\"):
        found.append("\\\\")
    if {m.group(0) for m in RUN3.finditer(prediction)} - {m.group(0) for m in RUN3.finditer(target)}:
        found.append("run3")
    return found


def main() -> None:
    kinds = ["stutter", "^^ / __", "braces", "\\\\", "run3"]
    print("| model | readings | any repeated token | " + " | ".join(kinds) + " |")
    print("|---|---|---|" + "---|" * len(kinds))
    examples = {}
    for spec in sys.argv[1:]:
        name, path = spec.split("=", 1)
        rows = list(csv.DictReader(open(path, encoding="utf-8", newline=""), delimiter="\t"))
        counts = dict.fromkeys(kinds, 0)
        flagged = []
        for r in rows:
            p = problems(r["target"], r["prediction"])
            for k in p:
                counts[k] += 1
            if p:
                flagged.append((r["image"].split("/")[-1], ",".join(p), r["prediction"]))
        print(f"| {name} | {len(rows)} | {len(flagged)} | " + " | ".join(str(counts[k]) for k in kinds) + " |")
        examples[name] = flagged
    for name, flagged in examples.items():
        print(f"\n{name}:")
        for image, kind, prediction in flagged:
            print(f"  {image} [{kind}] {prediction[:120]}")


if __name__ == "__main__":
    main()
