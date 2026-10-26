"""Labelled images -> ERNIEKit PaddleOCR-VL SFT JSONL (train/val), plus the
held-out eval list for evaluate_vl.py.

Example (from tools/training_vl):
  python convert_to_sft.py --data D:\\vl_data --labels D:\\vl_data\\labels.csv --out D:\\vl_data\\sft

Input
  - images anywhere under --data (topic folders are fine), each named
    topic_source_kind_number.ext (e.g. radicals_ss_S_001.png); topic,
    source and kind come from the name (mappings in config.json)
  - labels CSV with columns filename,task,target,split
    task: formula (LaTeX) | table (OTSL) | text;  split: train | val | eval

Output (only if every record is valid and nothing leaks)
  <out>/train.jsonl, val.jsonl   ERNIEKit SFT records:
      {"image_info": [{"matched_text_index": 0, "image_url": "<relative path>"}],
       "text_info": [{"text": "<task prompt>", "tag": "mask"},
                     {"text": "<target>", "tag": "no_mask"}]}
  <out>/eval.jsonl               same format, held out (never trained on)
  <out>/<split>_meta.jsonl       filename, topic, source, kind, task, sha256
  <out>/report.json, report.md   counts per split/topic/kind/source/task
image_url is relative to <out> (run ERNIEKit from <out>), or absolute
with --absolute-urls.

Leak guard: no train/val image may have the same bytes (sha256) as an
eval image of this dataset or of the recognizer tools' eval sets, and no
file name may be in two splits. Then nothing is written.
"""

from __future__ import annotations

import argparse
import json
import os
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

from vl_common import (
    DEFAULT_CONFIG,
    EvalLeakError,
    Item,
    check_no_leak,
    index_images,
    latex_problems,
    load_config,
    otsl_problems,
    parse_filename,
    read_labels_csv,
    recognizer_eval_hashes,
    sha256_file,
    strip_math_delimiters,
)


def build_items(rows: list[dict], data: Path, config: dict) -> list[Item]:
    images = index_images(data, config)
    seen = Counter(row["filename"].strip() for row in rows)
    items = []
    for row in rows:
        name = row["filename"].strip()
        item = Item(filename=name, task=row["task"].strip().lower(), target=row["target"], split=row["split"].strip().lower())
        parts = parse_filename(name, config)
        if parts is None:
            item.errors.append("name is not topic_source_kind_number.ext with a known source and kind")
        else:
            item.topic, item.source, item.kind, item.number = parts["topic"], parts["source"], parts["kind"], parts["number"]
        if seen[name] > 1:
            item.errors.append(f"listed {seen[name]} times in the labels CSV")
        if item.task not in config["tasks"]:
            item.errors.append(f"unknown task {item.task!r} (one of {sorted(config['tasks'])})")
        if item.split not in config["splits"]:
            item.errors.append(f"unknown split {item.split!r} (one of {config['splits']})")

        paths = images.get(name, [])
        if not paths:
            item.errors.append("image not found under --data")
        elif len(paths) > 1:
            item.errors.append(f"{len(paths)} images with this name under --data")
        else:
            item.path = paths[0]
            try:
                with Image.open(item.path) as image:
                    image.verify()
                with Image.open(item.path) as image:
                    item.size = image.size
                item.sha256 = sha256_file(item.path)
            except Exception as error:  # noqa: BLE001
                item.errors.append(f"image cannot be read: {error}")

        target = (item.target or "").strip()
        if not target:
            item.errors.append("empty target")
        elif item.task == "formula":
            item.errors += [f"LaTeX: {p}" for p in latex_problems(target)]
            if strip_math_delimiters(target) == target:
                target = config["formula_wrap"].format(target)
        elif item.task == "table":
            item.errors += [f"OTSL: {p}" for p in otsl_problems(target)]
        item.target = target

        if item.kind == "W" and item.task == "formula":
            item.warnings.append("kind W (full document) with task formula")
        items.append(item)
    return items


def record(item: Item, out: Path, config: dict, absolute: bool) -> dict:
    url = str(item.path.resolve()) if absolute else os.path.relpath(item.path.resolve(), out.resolve()).replace(os.sep, "/")
    rec = {
        "image_info": [{"matched_text_index": 0, "image_url": url}],
        "text_info": [
            {"text": config["tasks"][item.task]["prompt"], "tag": "mask"},
            {"text": item.target, "tag": "no_mask"},
        ],
    }
    check_record(rec)
    return rec


def check_record(rec: dict) -> None:
    """The structure ERNIEKit expects: text_info alternates mask/no_mask and
    every image's matched_text_index points into text_info."""

    texts = rec["text_info"]
    assert texts and all(set(t) == {"text", "tag"} and t["tag"] in ("mask", "no_mask") for t in texts)
    assert all(a["tag"] != b["tag"] for a, b in zip(texts, texts[1:])), "mask/no_mask must alternate"
    assert any(t["tag"] == "no_mask" for t in texts), "nothing to learn (no no_mask)"
    for image in rec["image_info"]:
        assert set(image) == {"matched_text_index", "image_url"}
        assert 0 <= image["matched_text_index"] < len(texts)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data", required=True)
    parser.add_argument("--labels", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--config", default=str(DEFAULT_CONFIG))
    parser.add_argument("--absolute-urls", action="store_true")
    parser.add_argument("--skip-recognizer-eval-check", action="store_true",
                        help="only for tests: do not compare with tools/training eval sets")
    args = parser.parse_args()

    config = load_config(Path(args.config))
    data, out = Path(args.data), Path(args.out)
    items = build_items(read_labels_csv(Path(args.labels)), data, config)

    errors = [(i.filename, e) for i in items for e in i.errors]
    warnings = [(i.filename, w) for i in items for w in i.warnings]

    by_split = defaultdict(list)
    for item in items:
        by_split[item.split].append(item)

    # Leak guard (by bytes and by name).
    eval_items = by_split.get("eval", [])
    eval_hashes = {i.sha256 for i in eval_items if i.sha256}
    if not args.skip_recognizer_eval_check:
        eval_hashes |= recognizer_eval_hashes()
    train_hashes = {i.filename: i.sha256 for s in ("train", "val") for i in by_split.get(s, []) if i.sha256}
    leak = None
    try:
        check_no_leak(train_hashes, eval_hashes, {i.filename for i in eval_items})
    except EvalLeakError as error:
        leak = str(error)

    # Same image under two names (within training data): a warning.
    by_hash = defaultdict(list)
    for item in items:
        if item.sha256:
            by_hash[item.sha256].append(item.filename)
    duplicates = [names for names in by_hash.values() if len(names) > 1]

    counts = {
        key: {split: dict(Counter(getattr(i, key) for i in by_split.get(split, []))) for split in config["splits"]}
        for key in ("topic", "kind", "source", "task")
    }
    report = {
        "records": {split: len(by_split.get(split, [])) for split in config["splits"]},
        "counts": counts,
        "errors": errors,
        "warnings": warnings,
        "duplicate_images": duplicates,
        "leak": leak,
        "written": False,
    }

    print(f"Records: {report['records']}")
    for key in ("topic", "kind", "source", "task"):
        print(f"By {key}: " + "; ".join(f"{s}: {c}" for s, c in counts[key].items() if c))
    for name, problem in errors[:40]:
        print(f"ERROR {name}: {problem}")
    if len(errors) > 40:
        print(f"... {len(errors) - 40} more errors")
    for name, problem in warnings[:20]:
        print(f"warning {name}: {problem}")
    if duplicates:
        print(f"warning: {len(duplicates)} image(s) appear under more than one name, e.g. {duplicates[0]}")
    if leak:
        print(f"LEAK: {leak}")

    out.mkdir(parents=True, exist_ok=True)
    if not errors and not leak:
        for split in config["splits"]:
            rows = by_split.get(split, [])
            with open(out / f"{split}.jsonl", "w", encoding="utf-8", newline="\n") as handle:
                for item in rows:
                    handle.write(json.dumps(record(item, out, config, args.absolute_urls), ensure_ascii=False) + "\n")
            with open(out / f"{split}_meta.jsonl", "w", encoding="utf-8", newline="\n") as handle:
                for item in rows:
                    handle.write(json.dumps({"filename": item.filename, "topic": item.topic, "source": item.source,
                                             "kind": item.kind, "task": item.task, "sha256": item.sha256,
                                             "size": item.size}, ensure_ascii=False) + "\n")
        report["written"] = True
        print(f"Written: {', '.join(f'{s}.jsonl' for s in config['splits'])} in {out}")
    else:
        print("Nothing written: fix the errors above.")

    (out / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding="utf-8")
    lines = ["# SFT conversion report", "", f"Records: {report['records']}", f"Written: {report['written']}", ""]
    for key in ("topic", "kind", "source", "task"):
        lines += [f"## By {key}", "", "| " + key + " | " + " | ".join(config["splits"]) + " |",
                  "|---|" + "---|" * len(config["splits"])]
        values = sorted({v for s in counts[key].values() for v in s})
        for value in values:
            lines.append(f"| {value} | " + " | ".join(str(counts[key][s].get(value, 0)) for s in config["splits"]) + " |")
        lines.append("")
    lines += [f"Errors: {len(errors)}", f"Warnings: {len(warnings)}", f"Duplicate images: {len(duplicates)}", f"Leak: {leak or 'none'}"]
    (out / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    raise SystemExit(0 if report["written"] else 1)


if __name__ == "__main__":
    main()
