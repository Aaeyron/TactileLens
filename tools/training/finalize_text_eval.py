"""Text eval: apply the human review (review page export) and recheck leaks against training.

From tools/training (paddle_onnx_env):
  python finalize_text_eval.py --working <working folder> --reviews <folder of <line>.json review documents>

Each review document: {status: checked|exclude, label, note, ...} (the review page's "reviews"
collection, saved one JSON file per line). Writes text_lines_mtw/test/{eval.txt, eval_final_rows.json,
eval_final_report.json}; refuses if eval.txt exists (the eval set is frozen once). Leak recheck against
train_sets/text_v1/rec_train.txt: same label (compare_text main comparison, lower case), same bytes,
same source image.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path

from compare_text import main_key


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", required=True)
    parser.add_argument("--reviews", required=True)
    args = parser.parse_args()
    working = Path(args.working)
    test = working / "text_lines_mtw" / "test"
    rows = {r["line"]: r for r in json.loads((test / "eval_rows.json").read_text(encoding="utf-8"))}
    reviews = {p.name[:-5]: json.loads(p.read_text(encoding="utf-8")) for p in Path(args.reviews).glob("*.json")}
    if set(reviews) != set(rows):
        raise SystemExit(f"{len(set(rows) - set(reviews))} eval lines have no review")
    if (test / "eval.txt").exists():
        raise SystemExit("eval.txt exists already; the eval set is frozen")

    kept, fixed, excluded, notes = [], [], [], []
    for line, row in sorted(rows.items()):
        review = reviews[line]
        if review.get("note"):
            notes.append([line, review["status"], review["note"]])
        if review["status"] == "exclude":
            excluded.append([line, review.get("note", "")])
            continue
        if review["status"] != "checked":
            raise SystemExit(f"{line}: status {review['status']!r}")
        label = review["label"].strip()
        if label != row["label"]:
            fixed.append([line, row["label"], label])
        kept.append({**row, "label": label, "suggested": row["label"]})

    train_file = working / "train_sets" / "text_v1" / "rec_train.txt"
    train = [line.split("\t", 1) for line in train_file.read_text(encoding="utf-8").splitlines() if line.strip()]
    keys = {main_key(r["label"]).lower() for r in kept}
    hashes = {sha(test / "images" / r["line"]) for r in kept}
    sources = {r["line"].split("__")[0] for r in kept}
    report = {
        "reviewed": len(reviews), "kept": len(kept), "fixed": len(fixed), "excluded": len(excluded),
        "train_label_equals_eval_label": [i for i, t in train if main_key(t).lower() in keys],
        "train_same_bytes_as_eval": [i for i, _ in train if sha(train_file.parent / i) in hashes],
        "shared_source_images": sorted(sources & {Path(i).name.split("__")[0] for i, _ in train}),
        "by_source": Counter(r["source"] for r in kept), "by_kind": Counter(r["kind"] for r in kept),
        "by_topic": Counter(r["topic"] for r in kept),
    }
    leaks = report["train_label_equals_eval_label"] or report["train_same_bytes_as_eval"] or report["shared_source_images"]
    if leaks:
        raise SystemExit(f"LEAK between training and the verified eval: {json.dumps(report, indent=1)}")
    (test / "eval_final_rows.json").write_text(json.dumps(kept, ensure_ascii=False, indent=1), encoding="utf-8")
    (test / "eval.txt").write_text("".join(f"images/{r['line']}\t{r['label']}\n" for r in kept), encoding="utf-8")
    (test / "eval_final_report.json").write_text(
        json.dumps({**report, "fixed_lines": fixed, "excluded_lines": excluded, "notes": notes},
                   ensure_ascii=False, indent=1), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
