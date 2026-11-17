"""Algebra-level subset of im2latex-100k for the preliminary Track A run.

With C:\\Projects\\Capstone\\paddle_formula_env (needs pyarrow), run with -I:
  python -I prepare_im2latex.py --src <dir with the three .parquet files> --out <new folder>

im2latex-100k (huggingface.co/datasets/yuntian-deng/im2latex-100k, CC0-1.0):
printed formulas rendered from arXiv LaTeX, splits train / val / test.
Labels are kept exactly as published (LaTeX with a space between tokens,
the same style as PaddleOCR's formula demo set).

1. algebra_filter.reason_to_drop keeps expressions using general-algebra notation only
   (the formulas still come from physics papers; this is not a worksheet algebra set).
2. Each kept formula gets ONE topic by the first rule that matches
   (a heuristic on the LaTeX, see TOPIC_RULES): function_notation,
   inequalities, radicals, fractions, quadratic_equations, exponents,
   polynomials, linear_equations. The features each formula contains are
   counted too (one formula can have several).
3. Leak guard between the splits: test is the held-out public check, val
   picks the checkpoint. A train or val formula is dropped when its image
   (sha256) or its LaTeX (spaces removed) is also in test; a train formula
   is dropped when it is also in val.
4. Writes <out>/images/<topic>_pub_i2l-<split>_<n>.png (the published
   PNG bytes, unchanged), <out>/train.txt, val.txt, test.txt
   (images/<name><TAB><latex>, PaddleOCR's LaTeXOCR format),
   <out>/report.json and report.md.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from algebra_filter import reason_to_drop  # noqa: E402

SPLITS = ("train", "val", "test")
EXP_TWO = r"\^\s*(?:2(?!\s*\d)|\{\s*2\s*\})"
REL = r"<|>|\\le(?![a-z])|\\leq|\\ge(?![a-z])|\\geq|\\lt|\\gt|\\neq|\\ne(?![a-z])"
FEATURES = {
    "function_notation": r"\b[fgh]\s*\(\s*[a-z]\s*\)",
    "inequality": REL,
    "radical": r"\\sqrt",
    "fraction": r"\\[dt]?frac",
    "exponent": r"\^",
    "equals": r"=",
}


def features(latex: str) -> set[str]:
    return {name for name, pattern in FEATURES.items() if re.search(pattern, latex)}


def topic(latex: str) -> str:
    """One topic per formula; the first matching rule wins (TOPIC_RULES)."""

    f = features(latex)
    if "function_notation" in f:
        return "function_notation"
    if "inequality" in f:
        return "inequalities"
    if "radical" in f:
        return "radicals"
    if "fraction" in f:
        return "fractions"
    if "exponent" in f and "equals" in f and re.search(EXP_TWO, latex):
        return "quadratic_equations"
    if "exponent" in f and "equals" not in f and re.search(r"[+-]", re.sub(r"\^\s*\{[^{}]*\}", "", latex)):
        return "polynomials"
    if "exponent" in f:
        return "exponents"
    return "linear_equations"


TOPIC_RULES = [
    "function_notation: f(x), g(x) or h(x)",
    "inequalities: <, >, \\le, \\ge, \\neq",
    "radicals: \\sqrt",
    "fractions: \\frac",
    "quadratic_equations: = and a power of 2",
    "polynomials: a power, + or - outside the exponents, no =",
    "exponents: any other formula with a power",
    "linear_equations: the rest (has =, no power, fraction or root)",
]


def key(latex: str) -> str:
    return re.sub(r"\s+", "", latex)


def write_list(path: Path, lines: list[str]) -> None:
    """LF line ends: PaddleOCR strips only "\\n", so a CRLF file would leave
    "\\r" at the end of every label (and the model would learn it)."""

    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--src", required=True, help="folder with train-*.parquet, val-*.parquet, test-*.parquet")
    parser.add_argument("--out", required=True, help="new folder (must not exist or be empty)")
    args = parser.parse_args()

    import pyarrow.parquet as pq

    src, out = Path(args.src), Path(args.out)
    if out.exists() and any(out.iterdir()):
        raise SystemExit(f"{out} is not empty")
    (out / "images").mkdir(parents=True, exist_ok=True)

    kept, dropped, totals = {}, {s: Counter() for s in SPLITS}, {}
    for split in SPLITS:
        files = sorted(src.glob(f"{split}-*.parquet"))
        if len(files) != 1:
            raise SystemExit(f"expected one {split}-*.parquet in {src}, found {len(files)}")
        table = pq.read_table(files[0])
        rows = []
        formulas = table.column("formula").to_pylist()
        names = table.column("filename").to_pylist()
        totals[split] = len(formulas)
        for index, (latex, name) in enumerate(zip(formulas, names)):
            why = reason_to_drop(latex or "")
            if why:
                dropped[split][why] += 1
            else:
                rows.append({"index": index, "source_name": name, "latex": latex.strip()})
        images = table.column("image").to_pylist()
        for row in rows:
            data = images[row["index"]]["bytes"]
            row["bytes"] = data
            row["sha256"] = hashlib.sha256(data).hexdigest()
        kept[split] = rows

    # Leak guard between the splits.
    held = {"test": ({r["sha256"] for r in kept["test"]}, {key(r["latex"]) for r in kept["test"]}),
            "val": ({r["sha256"] for r in kept["val"]}, {key(r["latex"]) for r in kept["val"]})}
    leaks = {s: Counter() for s in SPLITS}
    for split, against in (("val", ["test"]), ("train", ["test", "val"])):
        clean = []
        for row in kept[split]:
            hit = None
            for other in against:
                shas, keys = held[other]
                if row["sha256"] in shas:
                    hit = f"same image as {other}"
                elif key(row["latex"]) in keys:
                    hit = f"same formula as {other}"
                if hit:
                    break
            if hit:
                leaks[split][hit] += 1
            else:
                clean.append(row)
        kept[split] = clean
        if split == "val":
            held["val"] = ({r["sha256"] for r in clean}, {key(r["latex"]) for r in clean})

    report = {"source": str(src), "license": "CC0-1.0 (dataset README)", "topic_rules": TOPIC_RULES, "splits": {}}
    for split in SPLITS:
        per_topic, per_feature, label_lines = Counter(), Counter(), []
        for n, row in enumerate(kept[split]):
            t = topic(row["latex"])
            per_topic[t] += 1
            per_feature.update(features(row["latex"]))
            name = f"{t}_pub_i2l-{split}_{n:05d}.png"
            (out / "images" / name).write_bytes(row["bytes"])
            label_lines.append(f"images/{name}\t{row['latex']}")
        write_list(out / f"{split}.txt", label_lines)
        report["splits"][split] = {
            "published": totals[split], "passed_filter": totals[split] - sum(dropped[split].values()),
            "dropped_by_leak_guard": dict(leaks[split]), "kept": len(kept[split]),
            "topics": dict(per_topic.most_common()), "features": dict(per_feature.most_common()),
            "duplicate_formulas_within_split": len(kept[split]) - len({key(r["latex"]) for r in kept[split]}),
            "filter_drop_reasons": dict(dropped[split].most_common()),
        }
    (out / "report.json").write_text(json.dumps(report, indent=1), encoding="utf-8")

    topics = sorted({t for s in SPLITS for t in report["splits"][s]["topics"]})
    lines = ["# im2latex-100k, general-algebra notation", "", "Data: im2latex-100k filtered to expressions using general-algebra notation; the source formulas come from physics papers.", "", f"Source: `{src}` (CC0-1.0).", "",
             "| | " + " | ".join(SPLITS) + " |", "|---|" + "---|" * len(SPLITS)]
    for label, field in (("published", "published"), ("passed the general-algebra notation filter", "passed_filter")):
        lines.append(f"| {label} | " + " | ".join(str(report["splits"][s][field]) for s in SPLITS) + " |")
    lines.append("| dropped by the leak guard | " + " | ".join(
        str(sum(report["splits"][s]["dropped_by_leak_guard"].values())) for s in SPLITS) + " |")
    lines.append("| **kept** | " + " | ".join(f"**{report['splits'][s]['kept']}**" for s in SPLITS) + " |")
    lines += ["", "Per topic (one topic per formula, rules below):", "",
              "| topic | " + " | ".join(SPLITS) + " |", "|---|" + "---|" * len(SPLITS)]
    for t in topics:
        lines.append(f"| {t} | " + " | ".join(str(report["splits"][s]["topics"].get(t, 0)) for s in SPLITS) + " |")
    lines += ["", "Formulas containing each feature (a formula can count several times):", "",
              "| feature | " + " | ".join(SPLITS) + " |", "|---|" + "---|" * len(SPLITS)]
    for f in FEATURES:
        lines.append(f"| {f} | " + " | ".join(str(report["splits"][s]["features"].get(f, 0)) for s in SPLITS) + " |")
    lines += ["", "Topic rules (first match wins; a heuristic on the LaTeX, not checked by hand):", ""]
    lines += [f"{i}. {r}" for i, r in enumerate(TOPIC_RULES, 1)]
    lines += ["", "Leak guard drops: " + "; ".join(f"{s}: {dict(leaks[s]) or 'none'}" for s in SPLITS)]
    lines += ["", "Duplicate formulas within a split (kept): " + ", ".join(
        f"{s} {report['splits'][s]['duplicate_formulas_within_split']}" for s in SPLITS)]
    lines += ["", "Main filter drop reasons (train): " + ", ".join(
        f"{why} {n}" for why, n in list(dropped["train"].most_common())[:8])]
    (out / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
