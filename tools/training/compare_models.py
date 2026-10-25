"""Two recognizers side by side on one eval set (baseline vs a trained one).

Example (from tools/training):
  python compare_models.py --set real-eval --b <trial.onnx> --b-name trial
  (--a defaults to the app's current recognizer, named "baseline")

Rows: ALL, controls (no superscript), negative exponents, each topic, and
each worksheet sheet (real photos). Columns per model: exact %, exponent
exact % (lines with a superscript). Same comparison as evaluate.py.
Writes comparison.md and comparison.csv to
<root>/outputs/compare/<date>_<a sha8>_vs_<b sha8>_<set>/.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
from collections import defaultdict
from pathlib import Path

from app_ocr import AppOcr, read_image
from common import REC_MODEL, Layout, check_no_eval_in_training, read_labels, read_manifest, root_dir, sha256_of
from evaluate import Tally


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--set", choices=["synthetic-eval", "real-eval"], required=True)
    parser.add_argument("--root")
    parser.add_argument("--a", default=str(REC_MODEL))
    parser.add_argument("--a-name", default="baseline")
    parser.add_argument("--b", required=True)
    parser.add_argument("--b-name", default="trained")
    args = parser.parse_args()

    layout = Layout(root_dir(args.root))
    check_no_eval_in_training(layout)
    rows = read_labels(layout.label_file(args.set))
    if not rows:
        raise SystemExit(f"No lines in {layout.label_file(args.set)} yet (pair photos first).")
    meta = {r["path"]: r for r in read_manifest(layout.manifest(args.set))}
    base = layout.set_dir(args.set)
    models = {args.a_name: AppOcr(rec_model=Path(args.a)), args.b_name: AppOcr(rec_model=Path(args.b))}

    groups: dict[str, dict[str, Tally]] = defaultdict(lambda: {name: Tally() for name in models})
    for image, label in rows:
        crop = read_image(base / image)
        info = meta.get(image, {})
        keys = ["ALL", f"topic: {info.get('topic', 'unknown')}"]
        if not any(c in "⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿ" for c in label):
            keys.append("controls (no superscript)")
        if info.get("topic") == "negative_exponents":
            keys.append("negative exponents")
        if info.get("sheet"):
            keys.append(f"sheet: {info['sheet']}")
        for name, ocr in models.items():
            text, _ = ocr.recognize_line(crop)
            for key in keys:
                groups[key][name].add(label, text)

    order = ["ALL", "controls (no superscript)", "negative exponents"]
    keys = order + sorted(k for k in groups if k.startswith("topic: ")) + sorted(k for k in groups if k.startswith("sheet: "))
    hashes = {name: sha256_of(Path(path))[:8] for name, path in ((args.a_name, args.a), (args.b_name, args.b))}
    out = layout.outputs / "compare" / f"{dt.date.today().isoformat()}_{hashes[args.a_name]}_vs_{hashes[args.b_name]}_{args.set}"
    out.mkdir(parents=True, exist_ok=True)

    a, b = args.a_name, args.b_name
    lines = [
        f"# {a} vs {b}: {args.set} ({len(rows)} lines)",
        "",
        f"- {a}: `{Path(args.a).name}` sha256 {hashes[a]}...",
        f"- {b}: `{Path(args.b).name}` sha256 {hashes[b]}...",
        "",
        f"| Group | Lines | {a} exact % | {b} exact % | Lines with superscript | {a} exponent exact % | {b} exponent exact % |",
        "|---|---|---|---|---|---|---|",
    ]
    table = []
    for key in keys:
        if key not in groups:
            continue
        ra, rb = groups[key][a].row(key), groups[key][b].row(key)
        cell = lambda v: "-" if v is None else str(v)  # noqa: E731
        lines.append(f"| {key} | {ra['lines']} | {cell(ra['exact_pct'])} | {cell(rb['exact_pct'])} | "
                     f"{ra['superscript_lines']} | {cell(ra['exponent_exact_pct'])} | {cell(rb['exponent_exact_pct'])} |")
        table.append({"group": key, "lines": ra["lines"], f"{a}_exact_pct": ra["exact_pct"], f"{b}_exact_pct": rb["exact_pct"],
                      "superscript_lines": ra["superscript_lines"], f"{a}_exponent_exact_pct": ra["exponent_exact_pct"],
                      f"{b}_exponent_exact_pct": rb["exponent_exact_pct"]})
    (out / "comparison.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    with open(out / "comparison.csv", "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(table[0]))
        writer.writeheader()
        writer.writerows(table)
    print("\n".join(lines))
    print(f"\nWritten to {out}")


if __name__ == "__main__":
    main()
