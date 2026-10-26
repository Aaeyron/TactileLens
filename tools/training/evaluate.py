"""Run the app's current recognizer on an eval set and write the metrics.

Example (from tools/training):
  python evaluate.py --set synthetic-eval
  python evaluate.py --set real-eval --rec path/to/new_model.onnx --tag retrained

Metrics, overall and per topic (topic from the manifest):
  CER                  character edit distance / label length, after
                       treating − and - as the same and ignoring spaces
  exact                whole line right (same comparison)
  exponent exact       exact, over lines whose label has a superscript
  base exact           exact after superscripts are read as plain
                       characters (x² = x2): is the rest of the line right?

Output: <root>/outputs/<tag>/<date>_<model sha256[:8]>_<set>/
  results.md, results.csv, predictions.tsv
The model hash, eval-set hash and date are in every file, so runs before
and after training can be compared.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
from collections import defaultdict
from pathlib import Path

from app_ocr import AppOcr, read_image
from common import (
    REC_CONFIG,
    REC_MODEL,
    SUPERSCRIPT_CHARS,
    Layout,
    check_no_eval_in_training,
    edit_distance,
    loosen,
    read_labels,
    read_manifest,
    root_dir,
    sha256_of,
)


def strict(text: str) -> str:
    return text.replace("−", "-").replace(" ", "")


class Tally:
    def __init__(self) -> None:
        self.lines = self.exact = self.base_exact = 0
        self.errors = self.chars = 0
        self.sup_lines = self.sup_exact = 0

    def add(self, label: str, prediction: str) -> None:
        a, b = strict(label), strict(prediction)
        self.lines += 1
        self.chars += max(len(a), 1)
        self.errors += edit_distance(a, b)
        self.exact += a == b
        self.base_exact += loosen(label) == loosen(prediction)
        if any(c in SUPERSCRIPT_CHARS for c in label):
            self.sup_lines += 1
            self.sup_exact += a == b

    def row(self, name: str) -> dict:
        pct = lambda n, d: round(100.0 * n / d, 1) if d else None  # noqa: E731
        return {
            "group": name,
            "lines": self.lines,
            "cer_pct": pct(self.errors, self.chars),
            "exact_pct": pct(self.exact, self.lines),
            "superscript_lines": self.sup_lines,
            "exponent_exact_pct": pct(self.sup_exact, self.sup_lines),
            "base_exact_pct": pct(self.base_exact, self.lines),
        }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--set", choices=["synthetic-eval", "real-eval"], required=True)
    parser.add_argument("--root")
    parser.add_argument("--rec", default=str(REC_MODEL), help="recognizer ONNX (default: the app's)")
    parser.add_argument("--rec-config", default=str(REC_CONFIG), help="inference.yml with the dictionary")
    parser.add_argument("--tag", default="baseline")
    args = parser.parse_args()

    layout = Layout(root_dir(args.root))
    check_no_eval_in_training(layout)

    rows = read_labels(layout.label_file(args.set))
    if not rows:
        raise SystemExit(f"No eval lines in {layout.label_file(args.set)}")
    topics = {r["path"]: r.get("topic", "unknown") for r in read_manifest(layout.manifest(args.set))}

    ocr = AppOcr(rec_model=Path(args.rec), rec_config=Path(args.rec_config))
    base = layout.set_dir(args.set)

    overall, by_topic, predictions = Tally(), defaultdict(Tally), []
    for image, label in rows:
        text, confidence = ocr.recognize_line(read_image(base / image))
        topic = topics.get(image, "unknown")
        overall.add(label, text)
        by_topic[topic].add(label, text)
        predictions.append((image, topic, label, text, round(confidence, 4), strict(label) == strict(text)))

    model_hash = sha256_of(Path(args.rec))
    eval_hash = hashlib.sha256(layout.label_file(args.set).read_bytes()).hexdigest()
    today = dt.date.today().isoformat()
    out = layout.outputs / args.tag / f"{today}_{model_hash[:8]}_{args.set}"
    out.mkdir(parents=True, exist_ok=True)

    table = [overall.row("ALL")] + [by_topic[t].row(t) for t in sorted(by_topic)]
    header = list(table[0])
    with open(out / "results.csv", "w", encoding="utf-8", newline="") as handle:
        handle.write(f"# date={today} model={Path(args.rec).name} model_sha256={model_hash} eval_set={args.set} eval_labels_sha256={eval_hash}\n")
        writer = csv.DictWriter(handle, fieldnames=header)
        writer.writeheader()
        writer.writerows(table)

    with open(out / "predictions.tsv", "w", encoding="utf-8", newline="\n") as handle:
        handle.write("image\ttopic\tlabel\tprediction\tconfidence\texact\n")
        for row in predictions:
            handle.write("\t".join(str(v) for v in row) + "\n")

    def cell(v):
        return "-" if v is None else str(v)

    lines = [
        f"# Recognizer results: {args.set}",
        "",
        f"- Date: {today}",
        f"- Model: `{Path(args.rec).name}` sha256 `{model_hash}`",
        f"- Dictionary: `{Path(args.rec_config).name}`",
        f"- Eval set: `{args.set}` ({len(rows)} lines), labels sha256 `{eval_hash}`",
        "- Comparison: − and - are the same, spaces ignored.",
        "",
        "| Group | Lines | CER % | Exact % | Lines with superscript | Exponent exact % | Base exact % |",
        "|---|---|---|---|---|---|---|",
    ]
    for r in table:
        lines.append(
            f"| {r['group']} | {r['lines']} | {cell(r['cer_pct'])} | {cell(r['exact_pct'])} | "
            f"{r['superscript_lines']} | {cell(r['exponent_exact_pct'])} | {cell(r['base_exact_pct'])} |"
        )
    (out / "results.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("\n".join(lines))
    print(f"\nWritten to {out}")


if __name__ == "__main__":
    main()
