"""Freeze reviewed formula labels of an unlabeled delivery.

Inputs:
  --working   working folder (extend_unlabeled.py output: split.csv, items.csv)
  --reviews   folder of the review page's answers, one JSON per image
              (ArtifactData list with out_dir): status checked|exclude, label
  --overrides CSV filename,status,label,provenance,reason: approved
              corrections and exclusions applied on top of the answers
  --ai-labels optional CSV filename,status,label,reason[,topic]: labels reviewed
              by Claude (validation only; never eval)

Every label keeps where it came from (provenance):
  human-verified         a team member accepted or typed it on the review page
  human-approved fix     proposed by Claude, approved by a team member
  AI-reviewed (Claude)   Claude looked at the image and corrected the
                         suggestions; not checked by a person

Label conventions (unify_label), applied to every kept label before anything
is scored: item markers as printed without \text (\text{b)} -> b)), plain
delimiters instead of \left \right. The text as reviewed stays in labels.csv.

Writes <working>/labels/: eval.txt, val_human.txt, val_ai.txt, val_all.txt
(images/<name> TAB latex, LF line ends, as train_formula.py reads them),
labels.csv (every reviewed image, its status, label, label as reviewed,
provenance), frozen.json (counts and SHA-256 of each list) and appends the
eval images to the frozen eval registry (--registry), once.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

import dataset_common as dc

SPLIT_ID = "own_20261118"
ITEM_MARKER_IN_TEXT = re.compile(r"\\text\{\s*(\(?[A-Za-z0-9]{1,3}[.)])\s*\}")
LEFT_RIGHT = re.compile(r"\\(?:left|right)(?![A-Za-z])\s*(?=[()\[\]|]|\\[{}|])")


def unify_label(label: str) -> str:
    """The agreed label conventions; the formula itself does not change."""
    label = ITEM_MARKER_IN_TEXT.sub(r"\1", label)
    return LEFT_RIGHT.sub("", label).strip()


def read_reviews(folder: Path) -> dict[str, dict]:
    out = {}
    for path in folder.glob("*.json"):
        body = json.loads(path.read_text(encoding="utf-8"))
        out[path.name[:-5]] = body.get("data", body)
    return out


def finalize(working: Path, reviews: dict, overrides: list[dict], ai: list[dict]) -> list[dict]:
    split = {r["filename"]: r for r in csv.DictReader((working / "split.csv").open(encoding="utf-8"))}
    rows = {}
    for name, r in reviews.items():
        rows[name] = {"filename": name, "split": split[name]["split"], "status": r["status"],
                      "label": r.get("label", "").strip(), "topic": r.get("topic") or split[name]["topic"],
                      "source": split[name]["source"], "provenance": "human-verified", "reason": r.get("note", "")}
    for o in overrides:
        row = rows[o["filename"]]
        row.update(status=o["status"], provenance=o["provenance"], reason=o["reason"])
        if o["status"] == "checked":
            row["label"] = o["label"].strip()
    for a in ai:
        name = a["filename"]
        if split[name]["split"] != "val":
            raise SystemExit(f"{name}: AI-reviewed labels are for validation only, not {split[name]['split']}")
        if name in rows:
            raise SystemExit(f"{name}: already reviewed by a person")
        rows[name] = {"filename": name, "split": "val", "status": a["status"], "label": a.get("label", "").strip(),
                      "topic": a.get("topic") or split[name]["topic"], "source": split[name]["source"],
                      "provenance": "AI-reviewed (Claude), not human-verified", "reason": a.get("reason", "")}
    for row in rows.values():
        if row["status"] == "checked" and not row["label"]:
            raise SystemExit(f"{row['filename']}: empty label")
        reviewed = reviews.get(row["filename"], {}).get("label", "").strip()
        row["label_as_reviewed"] = reviewed
        if row["status"] == "checked":
            row["label"] = unify_label(row["label"])
    return sorted(rows.values(), key=lambda r: (r["split"], r["filename"]))


def write(working: Path, rows: list[dict], registry: Path | None) -> dict:
    out = working / "labels"
    out.mkdir(exist_ok=True)
    files = {"eval.txt": lambda r: r["split"] == "eval",
             "val_human.txt": lambda r: r["split"] == "val" and not r["provenance"].startswith("AI"),
             "val_ai.txt": lambda r: r["split"] == "val" and r["provenance"].startswith("AI"),
             "val_all.txt": lambda r: r["split"] == "val"}
    frozen = {}
    for name, keep in files.items():
        lines = [f"images/{r['filename']}\t{r['label']}\n" for r in rows if r["status"] == "checked" and keep(r)]
        data = "".join(lines).encode("utf-8")
        (out / name).write_bytes(data)
        frozen[name] = {"items": len(lines), "sha256": hashlib.sha256(data).hexdigest()}
    (out / "frozen.json").write_text(json.dumps(frozen, indent=1) + "\n", encoding="utf-8", newline="\n")
    with (out / "labels.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, ["filename", "split", "status", "label", "label_as_reviewed", "topic", "source",
                                         "provenance", "reason"])
        writer.writeheader()
        writer.writerows(rows)

    added = 0
    if registry is not None:
        items = {r["filename"]: r for r in csv.DictReader((working / "items.csv").open(encoding="utf-8"))}
        existing = set()
        if registry.exists():
            existing = {json.loads(line)["sha256"] for line in registry.read_text(encoding="utf-8").splitlines() if line}
        registry.parent.mkdir(parents=True, exist_ok=True)
        with registry.open("a", encoding="utf-8", newline="\n") as handle:
            for r in rows:
                if r["split"] != "eval" or r["status"] != "checked":
                    continue
                item = items[r["filename"]]
                if item["sha256"] in existing:
                    continue
                handle.write(json.dumps({"split_id": SPLIT_ID, "filename": r["filename"], "sha256": item["sha256"],
                                         "dhash": item["dhash"] or dc.dhash(working / "images" / r["filename"]),
                                         "key": f"formula:{dc.normalize_target('formula', r['label'])}"},
                                        ensure_ascii=False) + "\n")
                added += 1

    counts = Counter((r["split"], r["provenance"].split(" (")[0].split(",")[0], r["status"]) for r in rows)
    return {"counts": {" / ".join(k): v for k, v in sorted(counts.items())}, "registry_added": added, "frozen": frozen}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", type=Path, required=True)
    parser.add_argument("--reviews", type=Path, required=True)
    parser.add_argument("--overrides", type=Path)
    parser.add_argument("--ai-labels", type=Path)
    parser.add_argument("--registry", type=Path, help="frozen eval registry to append the eval images to")
    args = parser.parse_args()

    def rows_of(path):
        return list(csv.DictReader(path.open(encoding="utf-8"))) if path else []

    rows = finalize(args.working, read_reviews(args.reviews), rows_of(args.overrides), rows_of(args.ai_labels))
    print(json.dumps(write(args.working, rows, args.registry), indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
