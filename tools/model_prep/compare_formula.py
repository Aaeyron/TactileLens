"""Compare two evaluate_formula.py runs on the same formula list.

  python compare_formula.py --before <results dir> --after <results dir> [--out <dir>]

Both runs must have scored the same images with the same targets. Two
scores, applied the same way to both models:

- strict: evaluate_formula.py's comparison (math delimiters and
  whitespace removed). The agreed pass bar is decided on this score.
- spacing-normalized: strict, and in addition these LaTeX spacing
  commands are removed from target and prediction before comparing
  (SPACING_RULE): \\, \\: \\; \\! \\  (backslash-space) ~ \\quad \\qquad
  \\enspace \\thinspace \\medspace \\thickspace \\negthinspace
  \\negmedspace \\negthickspace \\hspace{...} \\hspace*{...}. Nothing else
  is changed (braces, \\left/\\right, \\le vs \\leq still count).

Per group (ALL, each topic, each formula length; "simple" = at most 20
LaTeX tokens): exact before / after with counts, mean edit distance,
items that got worse (exact before, not after) or better, and the pass
bar. Writes comparison.md and comparison.json to --out (default: the
--after folder).
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

from evaluate_formula import length_group

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "training_vl"))
import vl_common  # noqa: E402

SPACING_COMMANDS = ["qquad", "quad", "enspace", "thinspace", "medspace", "thickspace", "negthinspace",
                    "negmedspace", "negthickspace"]
SPACING = re.compile(r"\\hspace\*?\s*\{[^{}]*\}|\\(?:" + "|".join(SPACING_COMMANDS) + r")(?![A-Za-z])"
                     r"|(?<!\\)\\[,:;! ]|~")
SPACING_RULE = ("LaTeX spacing commands are ignored: \\, \\: \\; \\! \\(space) ~ \\quad \\qquad \\enspace "
                "\\thinspace \\medspace \\thickspace \\negthinspace \\negmedspace \\negthickspace \\hspace{...}; "
                "then math delimiters and whitespace are removed as in the strict score. Nothing else changes.")
MODES = ("strict", "spacing-normalized")

# Agreed bar: at most 1 simple item exact before and not after, overall exact not lower.
PASS_SIMPLE_WORSE_MAX = 1


def drop_spacing(latex: str) -> str:
    return SPACING.sub(" ", latex)


def spacing_scores(target: str, prediction: str) -> tuple[bool, float]:
    a = vl_common.normalize_for_compare("formula", drop_spacing(target))
    b = vl_common.normalize_for_compare("formula", drop_spacing(prediction))
    return a == b, vl_common.normalized_edit_distance(a, b)


def read(folder: Path) -> dict[str, dict]:
    with open(folder / "predictions.tsv", encoding="utf-8", newline="") as handle:
        return {r["image"]: r for r in csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE)}


def compare(before: dict[str, dict], after: dict[str, dict], mode: str = "strict") -> dict:
    if before.keys() != after.keys():
        raise SystemExit(f"different images: {len(before.keys() ^ after.keys())} not in both runs")
    for image in before:
        if before[image]["target"] != after[image]["target"]:
            raise SystemExit(f"different target for {image}")
    groups = defaultdict(list)
    for image, b in before.items():
        a = after[image]
        if mode == "strict":
            eb, nb = b["exact"] == "True", float(b["ned"])
            ea, na = a["exact"] == "True", float(a["ned"])
        else:
            eb, nb = spacing_scores(b["target"], b["prediction"])
            ea, na = spacing_scores(a["target"], a["prediction"])
        item = {"image": image, "target": b["target"], "before": b["prediction"], "after": a["prediction"],
                "exact_before": eb, "exact_after": ea, "ned_before": nb, "ned_after": na}
        for group in ("ALL", b["topic"], length_group(b["target"])):
            groups[group].append(item)

    def summary(items: list[dict]) -> dict:
        n = len(items)
        return {"items": n,
                "exact_before": sum(i["exact_before"] for i in items),
                "exact_after": sum(i["exact_after"] for i in items),
                "exact_before_pct": round(100 * sum(i["exact_before"] for i in items) / n, 1),
                "exact_after_pct": round(100 * sum(i["exact_after"] for i in items) / n, 1),
                "ned_before": round(sum(i["ned_before"] for i in items) / n, 4),
                "ned_after": round(sum(i["ned_after"] for i in items) / n, 4),
                "got_worse": sum(i["exact_before"] and not i["exact_after"] for i in items),
                "got_better": sum(i["exact_after"] and not i["exact_before"] for i in items)}

    order = ["ALL"] + sorted(g for g in groups if g != "ALL" and not g.startswith("length")) + sorted(
        g for g in groups if g.startswith("length"))
    worse = [i for i in groups["ALL"] if i["exact_before"] and not i["exact_after"]]
    worse.sort(key=lambda i: (not length_group(i["target"]).endswith("(simple)"), i["image"]))
    table = {g: summary(groups[g]) for g in order}
    simple = next((s for g, s in table.items() if g.endswith("(simple)")), None)
    bar = {"simple_got_worse": simple["got_worse"] if simple else 0, "simple_items": simple["items"] if simple else 0,
           "all_exact_before": table["ALL"]["exact_before"], "all_exact_after": table["ALL"]["exact_after"]}
    bar["passed"] = bar["simple_got_worse"] <= PASS_SIMPLE_WORSE_MAX and bar["all_exact_after"] >= bar["all_exact_before"]
    return {"mode": mode, "groups": table, "got_worse": worse, "pass_bar": bar}


def section(result: dict) -> list[str]:
    mode = result["mode"]
    lines = [f"## {mode.capitalize()} score", ""]
    if mode != "strict":
        lines += [f"Rule: {SPACING_RULE}", ""]
    lines += ["| group | items | exact before | exact after | NED before | NED after | got worse | got better |",
              "|---|---|---|---|---|---|---|---|"]
    for g, s in result["groups"].items():
        lines.append(f"| {g} | {s['items']} | {s['exact_before_pct']}% ({s['exact_before']}/{s['items']})"
                     f" | {s['exact_after_pct']}% ({s['exact_after']}/{s['items']}) | {s['ned_before']}"
                     f" | {s['ned_after']} | {s['got_worse']} | {s['got_better']} |")
    b = result["pass_bar"]
    lines += ["", f"Pass bar (at most {PASS_SIMPLE_WORSE_MAX} simple item got worse, overall exact not lower), "
              f"{mode}: **{'passed' if b['passed'] else 'not passed'}** (simple got worse {b['simple_got_worse']}/"
              f"{b['simple_items']}; overall exact {b['all_exact_before']} -> {b['all_exact_after']})", "",
              f"Items exact before and not after ({mode}): {len(result['got_worse'])}", ""]
    for i in result["got_worse"][:30]:
        lines.append(f"- `{Path(i['image']).name}` ({length_group(i['target'])}): target `{i['target']}`;"
                     f" after `{i['after']}`")
    return lines + [""]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--before", required=True, help="evaluate_formula.py output folder (original model)")
    parser.add_argument("--after", required=True, help="evaluate_formula.py output folder (fine-tuned model)")
    parser.add_argument("--out")
    args = parser.parse_args()

    before, after = read(Path(args.before)), read(Path(args.after))
    results = {mode: compare(before, after, mode) for mode in MODES}
    strict = results["strict"]["pass_bar"]["passed"]
    out = Path(args.out or args.after)
    out.mkdir(parents=True, exist_ok=True)
    (out / "comparison.json").write_text(json.dumps(
        {"before": args.before, "after": args.after, "spacing_rule": SPACING_RULE,
         "decision": "pass bar decided on the strict score", "passed_strict_bar": strict, **results},
        indent=1, ensure_ascii=False), encoding="utf-8")
    lines = ["# Formula model: before vs after", "", f"- Before: `{args.before}`", f"- After: `{args.after}`",
             f"- **Pre-agreed strict pass bar: {'PASSED' if strict else 'FAILED'}.** The spacing-normalized score is "
             "reported alongside; it does not change the decision.", ""]
    for mode in MODES:
        lines += section(results[mode])
    (out / "comparison.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
