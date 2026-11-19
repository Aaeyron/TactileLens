"""Choose eval / validation / training items of an unlabeled delivery.

Run BEFORE any model reading is looked at, so the choice cannot depend on
which items a model gets right. Only single-formula images (kind S) are
used: the formula model reads one formula per image (multi-formula M,
text T and worksheet W images are left for the full pipeline).

- Groups: an ss/cap pair from the intake (same topic, kind and number)
  stays together.
- Eval: per topic, --eval-per-topic groups that contain a phone capture
  (cap), drawn at random with --seed. Validation: --val-per-topic groups
  per topic, phone captures first. Everything else: training.
- The eval items are added to the frozen eval registry only when their
  labels are final (finalize_labels.py), as split_dataset.py does.

Usage (from tools/dataset):
  python split_unlabeled.py --working <root>/datasets/own/working/<id> --intake <root>/datasets/own/intake/<run>
"""

from __future__ import annotations

import argparse
import csv
import json
import random
import re
from collections import defaultdict
from pathlib import Path


def groups_of(items: list[dict], pairs: list[tuple[str, str]]) -> list[list[dict]]:
    by_name = {item["filename"]: item for item in items}
    parent = {name: name for name in by_name}

    def find(name: str) -> str:
        while parent[name] != name:
            parent[name] = parent[parent[name]]
            name = parent[name]
        return name

    for a, b in pairs:
        if a in by_name and b in by_name:
            parent[find(a)] = find(b)

    grouped = defaultdict(list)
    for name in sorted(by_name):
        grouped[find(name)].append(by_name[name])

    return [grouped[key] for key in sorted(grouped)]


SAME_BYTES = re.compile(r"same bytes as (\S+)")


def working_name(mapping: list[dict], original: str) -> str:
    """Working name of an original file. A copy left out as a duplicate
    follows the name that was kept, so an ss/cap pair is not lost when its
    capture survives under another name."""
    by_original = {row["original"]: row for row in mapping}
    seen = set()

    while original in by_original and original not in seen:
        seen.add(original)
        row = by_original[original]
        if row["working"]:
            return row["working"]
        match = SAME_BYTES.search(row["action"])
        if not match:
            return ""
        original = match[1]

    return ""


def choose(items: list[dict], pairs: list[tuple[str, str]], eval_per_topic: int,
           val_per_topic: int, seed: int) -> dict[str, str]:
    rng = random.Random(seed)
    by_topic = defaultdict(list)

    for group in groups_of(items, pairs):
        by_topic[group[0]["topic"]].append(group)

    split = {}

    for topic in sorted(by_topic):
        groups = by_topic[topic][:]
        rng.shuffle(groups)
        has_cap = [g for g in groups if any(item["source"] == "cap" for item in g)]
        eval_groups = has_cap[:eval_per_topic]
        rest = [g for g in groups if g not in eval_groups]
        rest.sort(key=lambda g: not any(item["source"] == "cap" for item in g))  # stable: cap first
        val_groups = rest[:val_per_topic]

        for group in groups:
            side = "eval" if group in eval_groups else "val" if group in val_groups else "train"
            for item in group:
                split[item["filename"]] = side

    return split


def pairs_apart(split: dict[str, str], pairs: list[tuple[str, str]]) -> list[tuple[str, str]]:
    """Pairs whose two images are on different sides (should be none)."""
    return [(a, b) for a, b in pairs
            if a in split and b in split and split[a] != split[b]]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", type=Path, required=True)
    parser.add_argument("--intake", type=Path, required=True)
    parser.add_argument("--eval-per-topic", type=int, default=10)
    parser.add_argument("--val-per-topic", type=int, default=6)
    parser.add_argument("--seed", type=int, default=2026)
    parser.add_argument("--out-name", default="split.csv",
                        help="file written in --working (use another name to compare with an earlier split)")
    parser.add_argument("--check", metavar="SPLIT_CSV",
                        help="only check that an existing split in --working keeps every ss/cap pair together")
    args = parser.parse_args()

    items = [row for row in csv.DictReader((args.working / "items.csv").open(encoding="utf-8"))
             if row["kind"] == "S"]
    mapping = list(csv.DictReader((args.working / "mapping.csv").open(encoding="utf-8")))
    report = json.loads((args.intake / "report.json").read_text(encoding="utf-8"))
    pairs = [(working_name(mapping, a), working_name(mapping, b)) for a, b in report["ss_cap_pairs"]]

    if args.check:
        rows = csv.DictReader((args.working / args.check).open(encoding="utf-8"))
        existing = {row["filename"]: row["split"] for row in rows}
        apart = pairs_apart(existing, pairs)
        together = sum(1 for a, b in pairs if a in existing and b in existing) - len(apart)
        print(f"{args.check}: {together} ss/cap pairs on the same side, {len(apart)} apart")
        for a, b in apart:
            print(f"  APART {a} ({existing[a]}) / {b} ({existing[b]})")
        return 1 if apart else 0

    split = choose(items, pairs, args.eval_per_topic, args.val_per_topic, args.seed)

    with (args.working / args.out_name).open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["filename", "topic", "source", "split"])
        for item in items:
            writer.writerow([item["filename"], item["topic"], item["source"], split[item["filename"]]])

    counts = defaultdict(int)
    for item in items:
        counts[(split[item["filename"]], item["source"])] += 1
    print(dict(sorted(counts.items())))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
