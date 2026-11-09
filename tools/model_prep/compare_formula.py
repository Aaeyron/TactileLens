"""Compare two evaluate_formula.py runs on the same formula list.

  python compare_formula.py --before <results dir> --after <results dir> [--out <dir>]

Both runs must have scored the same images with the same targets. Per
group (ALL, each topic, each formula length; "simple" = at most 20 LaTeX
tokens): exact match before / after, mean edit distance before / after,
and how many items got worse (exact before, not after) or better. The
items that got worse are listed, simple ones first. Writes
comparison.md and comparison.json to --out (default: the --after folder).
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path

from evaluate_formula import length_group


def read(folder: Path) -> dict[str, dict]:
    with open(folder / "predictions.tsv", encoding="utf-8", newline="") as handle:
        return {r["image"]: r for r in csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE)}


def compare(before: dict[str, dict], after: dict[str, dict]) -> dict:
    if before.keys() != after.keys():
        raise SystemExit(f"different images: {len(before.keys() ^ after.keys())} not in both runs")
    for image in before:
        if before[image]["target"] != after[image]["target"]:
            raise SystemExit(f"different target for {image}")
    groups = defaultdict(list)
    for image, b in before.items():
        a = after[image]
        item = {"image": image, "target": b["target"], "before": b["prediction"], "after": a["prediction"],
                "exact_before": b["exact"] == "True", "exact_after": a["exact"] == "True",
                "ned_before": float(b["ned"]), "ned_after": float(a["ned"])}
        for group in ("ALL", b["topic"], length_group(b["target"])):
            groups[group].append(item)

    def summary(items: list[dict]) -> dict:
        n = len(items)
        return {"items": n,
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
    return {"groups": {g: summary(groups[g]) for g in order}, "got_worse": worse}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--before", required=True, help="evaluate_formula.py output folder (original model)")
    parser.add_argument("--after", required=True, help="evaluate_formula.py output folder (fine-tuned model)")
    parser.add_argument("--out")
    args = parser.parse_args()

    result = compare(read(Path(args.before)), read(Path(args.after)))
    result.update(before=args.before, after=args.after)
    out = Path(args.out or args.after)
    out.mkdir(parents=True, exist_ok=True)
    (out / "comparison.json").write_text(json.dumps(result, indent=1, ensure_ascii=False), encoding="utf-8")
    lines = ["# Formula model: before vs after", "", f"- Before: `{args.before}`", f"- After: `{args.after}`", "",
             "| group | items | exact before % | exact after % | NED before | NED after | got worse | got better |",
             "|---|---|---|---|---|---|---|---|"]
    for g, s in result["groups"].items():
        lines.append(f"| {g} | {s['items']} | {s['exact_before_pct']} | {s['exact_after_pct']} | {s['ned_before']}"
                     f" | {s['ned_after']} | {s['got_worse']} | {s['got_better']} |")
    lines += ["", f"Items exact before and not after: {len(result['got_worse'])}", ""]
    for i in result["got_worse"][:30]:
        lines.append(f"- `{Path(i['image']).name}` ({length_group(i['target'])}): target `{i['target']}`;"
                     f" after `{i['after']}`")
    (out / "comparison.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
