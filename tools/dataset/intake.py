"""Audit a delivered dataset (folders and/or zips) before anything uses it.

One command, from tools/dataset:
  python intake.py                       # everything in <root>/incoming/
  python intake.py --incoming D:\\delivery --work D:\\intake   # other places

It never changes the originals: zips are extracted, and folders copied,
into <work>/<run>/extracted/ (default <root>/intake/), and only that copy
is read. Then for every image and every labels CSV row:

  counts      topic x source (ss/cap) x kind (S/M/T/W), and task
  names       topic_source_kind_number.ext (tools/training_vl/config.json)
  labels      filename,task,target[,split]; LaTeX braces, \\left/\\right,
              \\begin/\\end; OTSL tokens and even rows; text targets
              against the offline recognizer's charset
  images      opens, size, unlabelled images, labels without an image
  duplicates  same bytes (sha256); near-duplicates (dhash within 6 bits);
              ss/cap pairs of the same item (same task and target, or same
              topic, kind and number)
  flags       personal data (GPS in a photo, email, phone, "Name:" ...),
              third-party material (copyright, ISBN, publisher, page
              numbers), the forbidden textbook page 04 sample
  eval        images that are already in an eval set (recognizer eval
              sets, frozen eval registry): these must never be trained on

Errors (bad name, bad label, unreadable image, missing image) keep an item
out of the split; flags and warnings are for a person to look at. Nothing
is deleted or fixed automatically.

Output: <work>/<run>/items.csv (one row per image), report.md, report.json.
Next step: split_dataset.py --intake <work>/<run>.
"""

from __future__ import annotations

import argparse
import datetime as dt
import os
import shutil
import zipfile
from collections import Counter, defaultdict
from pathlib import Path, PurePosixPath

from PIL import Image

import dataset_common as dc
from dataset_common import rec_common, vl_common


class IntakeError(RuntimeError):
    pass


def safe_extract(archive: Path, target: Path) -> int:
    """Extract a zip without letting any member escape `target`."""

    count = 0
    with zipfile.ZipFile(archive) as zf:
        for member in zf.infolist():
            name = PurePosixPath(member.filename.replace("\\", "/"))
            if name.is_absolute() or ".." in name.parts or (name.parts and ":" in name.parts[0]):
                raise IntakeError(f"{archive.name}: unsafe path in zip: {member.filename!r}")
            if member.is_dir():
                continue
            out = target.joinpath(*name.parts)
            out.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(member) as source, open(out, "wb") as sink:
                shutil.copyfileobj(source, sink)
            count += 1
    return count


def copy_incoming(incoming: Path, extracted: Path) -> list[str]:
    """Copies every zip (extracted) and folder under `incoming`; returns
    what was copied. Loose files at the top level are copied too."""

    copied = []
    extracted.mkdir(parents=True, exist_ok=True)
    for entry in sorted(incoming.iterdir()):
        if entry.name.startswith("."):
            continue
        if entry.is_file() and entry.suffix.lower() == ".zip":
            n = safe_extract(entry, extracted / entry.stem)
            copied.append(f"{entry.name} (zip, {n} files)")
        elif entry.is_dir():
            shutil.copytree(entry, extracted / entry.name)
            copied.append(f"{entry.name}/ (folder)")
        elif entry.is_file():
            (extracted / "_loose").mkdir(exist_ok=True)
            shutil.copy2(entry, extracted / "_loose" / entry.name)
            copied.append(entry.name)
    return copied


def read_all_labels(extracted: Path) -> tuple[list[dict], list[str]]:
    """Rows of every *.csv with the label columns; problems found."""

    rows, problems = [], []
    for path in sorted(extracted.rglob("*.csv")):
        try:
            found = vl_common.read_labels_csv(path)
        except ValueError as error:
            problems.append(f"{path.relative_to(extracted)}: {error}")
            continue
        except KeyError:
            continue
        for row in found:
            row["_csv"] = str(path.relative_to(extracted))
        rows += found
    return rows, problems


def audit(extracted: Path, root: Path, config: dict, check_eval: bool = True, registry: Path | None = None) -> dict:
    images = vl_common.index_images(extracted, config)
    label_rows, csv_problems = read_all_labels(extracted)
    labels_by_name: dict[str, list[dict]] = defaultdict(list)
    for row in label_rows:
        labels_by_name[(row.get("filename") or "").strip()].append(row)

    items: list[dict] = []
    for name in sorted(set(images) | set(labels_by_name)):
        paths = images.get(name, [])
        rows = labels_by_name.get(name, [])
        item = {"filename": name, "errors": [], "warnings": [], "flags": []}
        row = rows[0] if rows else {}
        item["task"] = (row.get("task") or "").strip().lower()
        item["target"] = row.get("target") or ""
        item["split_given"] = (row.get("split") or "").strip().lower()

        parts = vl_common.parse_filename(name, config)
        if parts is None:
            item["errors"].append("name is not topic_source_kind_number.ext with a known source (ss/cap) and kind (S/M/T/W)")
        else:
            item.update({k: parts[k] for k in ("topic", "source", "kind", "number")})

        if len(rows) > 1:
            different = len({(r.get("task"), r.get("target"), r.get("split")) for r in rows}) > 1
            item["errors" if different else "warnings"].append(
                f"labelled {len(rows)} times ({', '.join(sorted({r['_csv'] for r in rows}))})"
                + (" with different labels" if different else ""))
        if not paths:
            item["errors"].append("label without an image")
        elif len(paths) > 1:
            item["errors"].append(f"{len(paths)} images with this name")
        else:
            path = paths[0]
            item["relpath"] = path.relative_to(extracted).as_posix()
            try:
                with Image.open(path) as image:
                    image.verify()
                with Image.open(path) as image:
                    item["width"], item["height"] = image.size
                item["sha256"] = vl_common.sha256_file(path)
                item["dhash"] = dc.dhash(path)
                if min(item["width"], item["height"]) < 16:
                    item["errors"].append(f"image too small ({item['width']}x{item['height']})")
                item["flags"] += dc.exif_flags(path)
            except Exception as error:  # noqa: BLE001
                item["errors"].append(f"image cannot be read: {error}")

        if not rows:
            item["errors"].append("image without a label")
        else:
            check_label(item, config)
        item["flags"] += dc.text_flags(name, item["target"])
        items.append(item)

    report = duplicates_and_pairs(items)
    if check_eval:
        mark_eval_overlap(items, root, registry)
    return {"items": items, "csv_problems": csv_problems, "label_rows": len(label_rows), **report}


def check_label(item: dict, config: dict) -> None:
    task, target = item["task"], (item["target"] or "").strip()
    if task not in config["tasks"]:
        item["errors"].append(f"unknown task {task!r} (one of {sorted(config['tasks'])})")
        return
    if item["split_given"] and item["split_given"] not in config["splits"]:
        item["errors"].append(f"unknown split {item['split_given']!r} (one of {config['splits']}, or empty)")
    if not target:
        item["errors"].append("empty target")
        return
    if task == "formula":
        item["errors"] += [f"LaTeX: {p}" for p in vl_common.latex_problems(target)]
        if vl_common.strip_math_delimiters(target) != target:
            item["warnings"].append("formula has $ or \\[ delimiters (stripped when compared)")
    elif task == "table":
        item["errors"] += [f"OTSL: {p}" for p in vl_common.otsl_problems(target)]
    elif task == "text":
        missing = dc.recognizer_unsupported(target)
        if missing:
            # Fine for the VL model; such lines are left out of the
            # offline recognizer's lists (see split_dataset.py).
            item["warnings"].append("not in the offline recognizer's charset: " + " ".join(sorted(missing)))
    if item.get("kind") == "W" and task == "formula":
        item["warnings"].append("kind W (full page) labelled as one formula")


def duplicates_and_pairs(items: list[dict]) -> dict:
    by_sha = defaultdict(list)
    for item in items:
        if item.get("sha256"):
            by_sha[item["sha256"]].append(item["filename"])
    exact = [names for names in by_sha.values() if len(names) > 1]
    for names in exact:
        for item in items:
            if item["filename"] in names:
                item["warnings"].append("same bytes as " + ", ".join(n for n in names if n != item["filename"]))

    hashes = {i["filename"]: i["dhash"] for i in items if i.get("dhash")}
    exact_pairs = {(min(a, b), max(a, b)) for names in exact for a in names for b in names if a != b}
    near = [(a, b, d) for a, b, d in dc.near_duplicate_pairs(hashes) if (a, b) not in exact_pairs]
    by_name = {i["filename"]: i for i in items}
    for a, b, d in near:
        by_name[a]["warnings"].append(f"near-duplicate of {b} ({d} bits)")
        by_name[b]["warnings"].append(f"near-duplicate of {a} ({d} bits)")

    # ss/cap pairs of the same item: same task + target, or same
    # topic/kind/number (if the team numbered pairs alike).
    pairs = set()
    by_key = defaultdict(list)
    by_number = defaultdict(list)
    for item in items:
        if item.get("source") and item.get("target"):
            by_key[(item["task"], dc.normalize_target(item["task"], item["target"]))].append(item)
        if item.get("source"):
            by_number[(item["topic"], item["kind"], int(item["number"]))].append(item)
    for group in list(by_key.values()) + list(by_number.values()):
        sources = {i["source"] for i in group}
        if {"ss", "cap"} <= sources:
            for a in group:
                for b in group:
                    if a["source"] == "ss" and b["source"] == "cap":
                        pairs.add((a["filename"], b["filename"]))
    for ss, cap in sorted(pairs):
        by_name[ss]["warnings"].append(f"ss/cap pair with {cap} (kept in the same split)")
        by_name[cap]["warnings"].append(f"ss/cap pair with {ss} (kept in the same split)")
    return {"exact_duplicates": exact, "near_duplicates": near, "ss_cap_pairs": sorted(pairs)}


def mark_eval_overlap(items: list[dict], root: Path, registry: Path | None = None) -> None:
    existing = dc.existing_eval_images(root, registry)
    eval_hashes = {v["dhash"]: (sha, v) for sha, v in existing.items() if v.get("dhash")}
    for item in items:
        if not item.get("sha256"):
            continue
        hit = existing.get(item["sha256"])
        if hit:
            item["flags"].append(f"ALREADY IN AN EVAL SET: same bytes as an image in {hit['from']}")
            continue
        for value, (sha, info) in eval_hashes.items():
            if dc.is_near_duplicate(item["dhash"], value):
                item["flags"].append(f"ALREADY IN AN EVAL SET? near-duplicate of an image in {info['from']}")
                break


def counts_table(items: list[dict], config: dict) -> list[str]:
    usable = [i for i in items if i.get("source") and not i["errors"]]
    grid = Counter((i["topic"], i["source"], i["kind"]) for i in usable)
    topics = sorted({i["topic"] for i in usable})
    columns = [(s, k) for s in config["sources"] for k in config["kinds"]]
    lines = ["| topic | " + " | ".join(f"{s} {k}" for s, k in columns) + " | total |",
             "|---|" + "---|" * (len(columns) + 1)]
    for topic in topics:
        row = [grid[(topic, s, k)] for s, k in columns]
        lines.append(f"| {topic} | " + " | ".join(str(v) for v in row) + f" | {sum(row)} |")
    totals = [sum(grid[(t, s, k)] for t in topics) for s, k in columns]
    lines.append("| **all** | " + " | ".join(str(v) for v in totals) + f" | {sum(totals)} |")
    return lines


def write_report(run: Path, result: dict, copied: list[str], config: dict) -> dict:
    items = result["items"]
    with_errors = [i for i in items if i["errors"]]
    flagged = [i for i in items if i["flags"]]
    summary = {
        "run": run.name,
        "copied": copied,
        "images_and_labels": len(items),
        "label_rows": result["label_rows"],
        "usable": len(items) - len(with_errors),
        "with_errors": len(with_errors),
        "flagged_for_review": len(flagged),
        "by_task": dict(Counter(i["task"] for i in items if not i["errors"])),
        "by_source": dict(Counter(i.get("source", "?") for i in items if not i["errors"])),
        "exact_duplicate_groups": len(result["exact_duplicates"]),
        "near_duplicate_pairs": len(result["near_duplicates"]),
        "ss_cap_pairs": len(result["ss_cap_pairs"]),
        "already_in_eval": sum(1 for i in items if any(f.startswith("ALREADY IN AN EVAL SET") for f in i["flags"])),
        "csv_problems": result["csv_problems"],
    }
    dc.write_json(run / "report.json", {**summary, "exact_duplicates": result["exact_duplicates"],
                                         "near_duplicates": result["near_duplicates"], "ss_cap_pairs": result["ss_cap_pairs"]})
    lines = [f"# Dataset intake {run.name}", "",
             "Read from the copy in `extracted/`; the originals were not changed.", "",
             "Copied: " + ("; ".join(copied) or "nothing"), "",
             f"- Images and label rows: {summary['images_and_labels']} ({summary['label_rows']} label rows)",
             f"- Usable (no errors): **{summary['usable']}**; with errors: **{summary['with_errors']}**",
             f"- Flagged for a person to check: **{summary['flagged_for_review']}**"
             f" (already in an eval set: {summary['already_in_eval']})",
             f"- By task: {summary['by_task']}; by source: {summary['by_source']}",
             f"- Exact duplicate groups: {summary['exact_duplicate_groups']}; near-duplicate pairs:"
             f" {summary['near_duplicate_pairs']}; ss/cap pairs: {summary['ss_cap_pairs']}", "",
             "## Usable items: topic x source x kind", ""] + counts_table(items, config)
    if result["csv_problems"]:
        lines += ["", "## Label files that could not be read", ""] + [f"- {p}" for p in result["csv_problems"]]
    for title, key in (("Errors (left out of the split)", "errors"), ("Flags (check by hand)", "flags"),
                       ("Warnings", "warnings")):
        rows = [(i["filename"], m) for i in items for m in i[key]]
        if rows:
            lines += ["", f"## {title}: {len(rows)}", "", "| file | problem |", "|---|---|"]
            lines += [f"| {name} | {message.replace('|', '/')} |" for name, message in rows]
    (run / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", help="training root (eval sets, frozen eval registry)")
    parser.add_argument("--incoming", help="default <root>/incoming")
    parser.add_argument("--work", help="where the copy and the report go (default <root>/intake)")
    parser.add_argument("--registry", help="frozen eval registry (default <root>/splits/frozen_eval.jsonl)")
    parser.add_argument("--config", default=str(vl_common.DEFAULT_CONFIG))
    args = parser.parse_args()

    root = rec_common.root_dir(args.root)
    registry = Path(args.registry) if args.registry else None
    incoming = Path(args.incoming) if args.incoming else root / "incoming"
    work = Path(args.work) if args.work else root / "intake"
    if not incoming.is_dir() or not any(incoming.iterdir()):
        raise SystemExit(f"Nothing to audit in {incoming}")
    if work.resolve().is_relative_to(incoming.resolve()):
        raise SystemExit("--work must not be inside --incoming")

    config = vl_common.load_config(Path(args.config))
    run = work / dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    copied = copy_incoming(incoming, run / "extracted")
    result = audit(run / "extracted", root, config, registry=registry)
    dc.write_items(run / "items.csv", result["items"])
    summary = write_report(run, result, copied, config)

    print((run / "report.md").read_text(encoding="utf-8").split("\n## Errors")[0])
    print(f"Intake: {run}")
    print(f"Next: python split_dataset.py --intake {run}")
    raise SystemExit(0 if summary["usable"] else 1)


if __name__ == "__main__":
    os.environ.setdefault("PYTHONIOENCODING", "utf-8")
    main()
