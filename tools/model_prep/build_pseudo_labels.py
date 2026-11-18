"""Training lists for the offline formula model from an unlabeled delivery.

Nobody checked these labels: they are pseudo-labels from two models.

  version 1  the app's offline model and PaddleOCR-VL read the image the same
             way (notation-normalized), and the reading passes the checks
  version 2  version 1, plus images where they disagree and PaddleOCR-VL's
             reading (the "teacher") passes the checks

Basic checks on the PaddleOCR-VL reading (basic_problem): exactly one formula
block, not empty, ASCII only, one line (no \\\\ or environments), balanced
braces, no word-like \\text, at most MAX_TOKENS LaTeX tokens, no token repeated
MAX_REPEAT times in a row, no "[object Object]".

Leak guard: an item is dropped when its image bytes are an eval or validation
image, or its label equals an eval or validation label (notation-normalized).
The synthetic formulas go through the same label guard.

  python build_pseudo_labels.py --working <working folder> --synthetic <folder>
      [--extra-vl old.json --extra-offline old_predictions.tsv]

Reads split.csv, items.csv, labels/ (finalize_labels.py), suggest_offline/
predictions.tsv and suggest_vl.jsonl. Writes <working>/train_sets/v1, v2 and
synthetic: train.txt (LF), val.txt (labels/val_all.txt), images (a folder
junction), manifest.csv, plus report.json / report.md.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "dataset"))

from compare_formula import OBJECT_OBJECT, notation_key  # noqa: E402
from evaluate_formula import TOKEN  # noqa: E402
from finalize_labels import unify_label  # noqa: E402

MAX_TOKENS = 80
MAX_REPEAT = 8
WORD_TEXT = re.compile(r"\\(?:text|mathrm|textbf)\s*\{[^{}]*[A-Za-z]{3,}")


def clean_reading(content: str) -> str:
    text = content.strip()
    for mark in ("$$", "\\[", "\\]", "$"):
        text = text.replace(mark, " ")
    return " ".join(text.split())


def balanced(latex: str) -> bool:
    depth = 0
    for match in re.finditer(r"\\.|[{}]", latex):
        if match.group() == "{":
            depth += 1
        elif match.group() == "}":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


def basic_problem(blocks: list[dict]) -> str | None:
    """Why a PaddleOCR-VL reading cannot be a label, or None."""
    if len(blocks) != 1:
        return "not exactly one block"
    if "formula" not in blocks[0].get("label", "").lower() and "equation" not in blocks[0].get("label", "").lower():
        return "not a formula block"
    latex = clean_reading(blocks[0].get("content", ""))
    if not latex:
        return "empty"
    if not latex.isascii():
        return "non-ASCII characters"
    if OBJECT_OBJECT.search(latex):
        return "[object Object]"
    if "\\begin" in latex or "\\\\" in latex or "\\hline" in latex:
        return "several lines"
    if not balanced(latex):
        return "unbalanced braces"
    if WORD_TEXT.search(latex):
        return "words in the formula"
    tokens = TOKEN.findall(latex)
    if len(tokens) > MAX_TOKENS:
        return f"more than {MAX_TOKENS} tokens"
    run = 1
    for a, b in zip(tokens, tokens[1:]):
        run = run + 1 if a == b else 1
        if run >= MAX_REPEAT:
            return "repeated token"
    return None


def choose(name: str, offline: str | None, blocks: list[dict] | None, held: set[str]) -> dict:
    """The decision for one training image."""
    row = {"filename": name, "group": "", "label": "", "reason": ""}
    if blocks is None or offline is None:
        row.update(group="no reading", reason="missing offline or PaddleOCR-VL reading")
        return row
    problem = basic_problem(blocks)
    if problem:
        row.update(group="rejected", reason=problem)
        return row
    label = unify_label(clean_reading(blocks[0]["content"]))
    if notation_key(label) in held:
        row.update(group="leak guard", reason="label equals an eval or validation label")
        return row
    agree = notation_key(offline) == notation_key(label)
    row.update(group="agreed" if agree else "teacher", label=label)
    return row


def read_list(path: Path) -> list[tuple[str, str]]:
    out = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if "\t" in line:
            out.append(tuple(line.split("\t", 1)))
    return out


def junction(link: Path, target: Path) -> None:
    if not link.exists():
        subprocess.run(["cmd", "/c", "mklink", "/J", str(link), str(target)], check=True, capture_output=True)


def write_set(folder: Path, items: list[tuple[str, str]], val: Path, images: Path) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    junction(folder / "images", images)
    (folder / "train.txt").write_bytes("".join(f"{a}\t{b}\n" for a, b in items).encode("utf-8"))
    if val.exists():
        (folder / "val.txt").write_bytes(val.read_bytes())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", required=True, type=Path)
    parser.add_argument("--synthetic", required=True, type=Path)
    parser.add_argument("--extra-vl", type=Path, help="earlier local_vl_worker.py JSON")
    parser.add_argument("--extra-offline", type=Path, help="earlier evaluate_formula.py predictions.tsv")
    args = parser.parse_args()
    w = args.working

    split = list(csv.DictReader((w / "split.csv").open(encoding="utf-8")))
    items = {r["filename"]: r for r in csv.DictReader((w / "items.csv").open(encoding="utf-8"))}
    offline = {}
    for path in [p for p in (args.extra_offline, w / "suggest_offline" / "predictions.tsv") if p]:
        with path.open(encoding="utf-8", newline="") as handle:
            for r in csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE):
                offline[Path(r["image"]).name] = r["prediction"]
    vl = {}
    if args.extra_vl:
        vl.update({p["id"]: p for p in json.loads(args.extra_vl.read_text(encoding="utf-8"))["predictions"]})
    for line in (w / "suggest_vl.jsonl").read_text(encoding="utf-8").splitlines():
        p = json.loads(line)
        vl[p["id"]] = p

    held_lists = [w / "labels" / n for n in ("eval.txt", "val_all.txt")]
    held_items = [x for path in held_lists for x in read_list(path)]
    held = {notation_key(label) for _, label in held_items}
    held_sha = {items[Path(image).name]["sha256"] for image, _ in held_items}

    rows = []
    for r in split:
        if r["split"] != "train":
            continue
        name = r["filename"]
        p = vl.get(name)
        row = choose(name, offline.get(name), None if p is None or p.get("error") else p["blocks"], held)
        if items[name]["sha256"] in held_sha:
            row.update(group="leak guard", label="", reason="same image bytes as an eval or validation image")
        row.update(topic=r["topic"], source=r["source"], offline=offline.get(name, ""))
        rows.append(row)

    v1 = [(f"images/{r['filename']}", r["label"]) for r in rows if r["group"] == "agreed"]
    v2 = v1 + [(f"images/{r['filename']}", r["label"]) for r in rows if r["group"] == "teacher"]
    root = w / "train_sets"
    val = w / "labels" / "val_all.txt"
    write_set(root / "v1", v1, val, w / "images")
    write_set(root / "v2", v2, val, w / "images")

    syn, syn_dropped = [], 0
    for image, label in read_list(args.synthetic / "train.txt"):
        if notation_key(label) in held:
            syn_dropped += 1
        else:
            syn.append((image, label))
    write_set(root / "synthetic", syn, val, args.synthetic / "images")

    with (root / "manifest.csv").open("w", encoding="utf-8", newline="") as handle:
        fields = ["filename", "topic", "source", "group", "label", "offline", "reason"]
        writer = csv.DictWriter(handle, fields, extrasaction="ignore", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    report = {
        "train_images": len(rows), "groups": dict(Counter(r["group"] for r in rows)),
        "rejected_reasons": dict(Counter(r["reason"] for r in rows if r["group"] == "rejected")),
        "v1_items": len(v1), "v2_items": len(v2),
        "v1_by_topic": dict(Counter(r["topic"] for r in rows if r["group"] == "agreed")),
        "v2_by_topic": dict(Counter(r["topic"] for r in rows if r["group"] in ("agreed", "teacher"))),
        "v1_by_source": dict(Counter(r["source"] for r in rows if r["group"] == "agreed")),
        "v2_by_source": dict(Counter(r["source"] for r in rows if r["group"] in ("agreed", "teacher"))),
        "synthetic_items": len(syn), "synthetic_dropped_by_leak_guard": syn_dropped,
        "held_out_labels": len(held),
        "offline_object_object_in_train_readings": sum(bool(OBJECT_OBJECT.search(r["offline"])) for r in rows),
        "training_labels_equal_to_held_out": sum(notation_key(l) in held for _, l in v2 + syn),
        "training_images_equal_to_held_out": sum(items[Path(i).name]["sha256"] in held_sha for i, _ in v2),
    }
    (root / "report.json").write_text(json.dumps(report, indent=1) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
