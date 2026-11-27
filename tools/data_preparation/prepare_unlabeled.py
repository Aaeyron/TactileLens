"""Make a working copy of an unlabeled delivery, with every change listed.

The 2026-11-18 delivery came without label files. Before any model reads
it, this copies the intake's extracted images (never the originals in
incoming/) to a working folder and:

- fixes topic names to the config's spelling (TOPIC_FIXES; e.g.
  "quadtratic" -> "quadratic"), and names like "linear_cap_M_092(1).png"
  (a second, different image) to a free number;
- keeps one image per group of byte-identical files (the intake's exact
  duplicate groups); the others are listed with the name kept;
- writes images/, mapping.csv (original name -> working name, what was
  done) and items.csv (working name, topic, source, kind, number, sha256,
  other names of the same image).

Usage (paddle_onnx_env or any Python with Pillow, from tools/data_preparation):
  python prepare_unlabeled.py --intake <root>/datasets/own/intake/<run> --out <root>/datasets/own/working/<id>
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
from pathlib import Path

NAME = re.compile(
    r"^(?P<topic>[A-Za-z]+)_(?P<source>ss|cap)_(?P<kind>[SMTW])_(?P<number>\d+)"
    r"(?P<copy>\(\d+\))?\.(?P<ext>png|jpe?g)$",
    re.IGNORECASE,
)

# Spellings in the delivery -> the topic name used by the tools.
TOPIC_FIXES = {
    "fraction": "fractions",
    "quadtratic": "quadratic",
    "inequalities": "inequalities",  # "Inequalities" with a capital
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse(name: str) -> dict | None:
    match = NAME.match(name)

    if not match:
        return None

    topic = match["topic"].lower()
    return {
        "topic": TOPIC_FIXES.get(topic, topic),
        "source": match["source"].lower(),
        "kind": match["kind"].upper(),
        "number": int(match["number"]),
        "copy": bool(match["copy"]),
        "ext": match["ext"].lower(),
    }


def prepare(intake: Path, out: Path) -> dict:
    report = json.loads((intake / "report.json").read_text(encoding="utf-8"))
    files = sorted(p for p in (intake / "extracted").rglob("*") if p.is_file())
    by_name = {p.name: p for p in files}

    # Byte-identical groups: keep the first name, list the others.
    kept_for = {}
    for group in report["exact_duplicates"]:
        names = sorted(group)
        for name in names[1:]:
            kept_for[name] = names[0]

    images = out / "images"
    images.mkdir(parents=True, exist_ok=False)
    taken: set[tuple] = set()
    mapping, items = [], []
    pending_copies = []

    def working_name(info: dict, number: int) -> str:
        return f"{info['topic']}_{info['source']}_{info['kind']}_{number:03d}.{info['ext'].replace('jpeg', 'jpg')}"

    def key(info: dict, number: int) -> tuple:
        return (info["topic"], info["source"], info["kind"], number)

    for name, path in by_name.items():
        info = parse(name)

        if info is None:
            mapping.append({"original": name, "working": "", "action": "left out: name not understood"})
            continue

        if name in kept_for:
            mapping.append({"original": name, "working": "", "action": f"left out: same bytes as {kept_for[name]}"})
            continue

        if info["copy"]:
            pending_copies.append((name, path, info))
            continue

        new = working_name(info, info["number"])
        taken.add(key(info, info["number"]))
        shutil.copy2(path, images / new)
        action = "copied" if new == name else "copied, renamed (topic spelling)"
        mapping.append({"original": name, "working": new, "action": action})
        items.append((new, info, path))

    # "(1)" names: the base number if free, else the next free number.
    for name, path, info in pending_copies:
        number = info["number"]
        if key(info, number) in taken:
            number = 900
            while key(info, number) in taken:
                number += 1
        taken.add(key(info, number))
        new = working_name(info, number)
        shutil.copy2(path, images / new)
        mapping.append({"original": name, "working": new, "action": "copied, renamed ('(1)' in the name)"})
        items.append((new, info, path))

    also = {}
    for name, first in kept_for.items():
        also.setdefault(first, []).append(name)

    with (out / "mapping.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, ["original", "working", "action"])
        writer.writeheader()
        writer.writerows(sorted(mapping, key=lambda row: row["original"]))

    working_of = {row["original"]: row["working"] for row in mapping if row["working"]}

    with (out / "items.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["filename", "topic", "source", "kind", "sha256", "same_image_as"])
        for new, info, path in sorted(items, key=lambda item: item[0]):
            original = path.name
            writer.writerow([
                new, info["topic"], info["source"], info["kind"], sha256(path),
                ";".join(also.get(original, [])),
            ])

    summary = {
        "intake": str(intake),
        "images": len(items),
        "left_out_duplicates": sum(1 for row in mapping if "same bytes" in row["action"]),
        "renamed": sum(1 for row in mapping if "renamed" in row["action"]),
        "not_understood": sum(1 for row in mapping if "not understood" in row["action"]),
        "working_of_kept_duplicates": {first: working_of.get(first, "") for first in also},
    }
    (out / "summary.json").write_text(json.dumps(summary, indent=1), encoding="utf-8")
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--intake", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    summary = prepare(args.intake, args.out)
    print({key: value for key, value in summary.items() if key != "working_of_kept_duplicates"})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
