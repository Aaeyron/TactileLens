"""Add a later, larger unlabeled delivery to an existing working copy and
split, without moving anything that is already split.

Input: the old working folder (prepare_unlabeled.py + split_unlabeled.py)
and a new intake run made with `intake.py --dedupe` (one file per distinct
content, every copy listed in same_bytes.csv).

- Working copy: a NEW folder. Old images keep their names (hard links,
  no extra disk space); new images (content not in the old copy) get the
  config's topic spelling and a free number if the name is taken.
- Split (kind S only): every old image keeps its side; the frozen eval set
  does not grow. New images go to validation or training:
    * ss/cap pairs (same topic, kind and number, looked up through EVERY
      file name a content had in the zips) stay on one side; a new image
      paired with an old one takes the old one's side;
    * leak guard: a new image that is a near-duplicate (dhash) of an eval
      image is left out; near-duplicates of a validation image go to
      validation; near-duplicates among new images stay together;
    * per topic, --val-per-topic new groups go to validation (phone
      captures first), drawn with a per-topic seed, so one topic's draw
      never changes another's.
- Topics: a content filed under several topic folders keeps the topic of
  its kept name and lists the others in `filed_under` (set it from the
  content on the review page).

Writes <out>/images, mapping.csv, items.csv, split.csv, summary.json.

Usage (from tools/data_preparation):
  python extend_unlabeled.py --old <root>/datasets/own/working/20261118 \
      --intake <root>/datasets/own/intake/<run> --out <root>/datasets/own/working/<new id>
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import random
import shutil
from collections import Counter, defaultdict
from pathlib import Path

import dataset_common as dc
from prepare_unlabeled import parse

SIDES = ("eval", "val", "train")


def link(source: Path, target: Path) -> None:
    try:
        os.link(source, target)
    except OSError:
        shutil.copy2(source, target)


def working_name(info: dict, number: int) -> str:
    ext = info["ext"].replace("jpeg", "jpg")
    return f"{info['topic']}_{info['source']}_{info['kind']}_{number:03d}.{ext}"


def union_find(names):
    parent = {n: n for n in names}

    def find(n):
        while parent[n] != n:
            parent[n] = parent[parent[n]]
            n = parent[n]
        return n

    def join(a, b):
        if a in parent and b in parent:
            parent[find(a)] = find(b)

    return find, join


def extend_split(items: list[dict], old_side: dict[str, str], pairs: list[tuple[str, str]],
                 near: list[tuple[str, str]], val_per_topic: int, seed: int) -> tuple[dict, dict]:
    """Sides for kind S items. `items`: filename, topic, source, origin.
    Returns ({filename: side or ''}, {filename: note})."""
    names = [i["filename"] for i in items]
    by_name = {i["filename"]: i for i in items}
    find, join = union_find(names)
    for a, b in pairs:
        join(a, b)

    eval_names = {n for n, s in old_side.items() if s == "eval"}
    side, note = {}, {}

    # Near-duplicates: of eval -> left out; others join the group.
    for a, b in near:
        a_new, b_new = by_name.get(a, {}).get("origin") == "new", by_name.get(b, {}).get("origin") == "new"
        for x, y, x_new in ((a, b, a_new), (b, a, b_new)):
            if x_new and y in eval_names:
                side[x], note[x] = "", f"left out: near-duplicate of eval image {y}"
        if not (a in eval_names or b in eval_names):
            join(a, b)

    groups = defaultdict(list)
    for n in names:
        groups[find(n)].append(n)

    rank = {"eval": 0, "val": 1, "train": 2}
    free_by_topic = defaultdict(list)
    for members in groups.values():
        olds = sorted({old_side[n] for n in members if n in old_side}, key=rank.get)
        if olds:
            target = olds[0]
            for n in members:
                if n in old_side:
                    side[n] = old_side[n]
                elif n not in side:
                    if target == "eval":
                        side[n], note[n] = "", "left out: same item as an eval image (eval stays frozen)"
                    else:
                        side[n], note[n] = target, f"same item as an old {target} image"
            continue
        members = [n for n in members if n not in side]
        if members:
            free_by_topic[by_name[members[0]]["topic"]].append(sorted(members))

    for topic in sorted(free_by_topic):
        rng = random.Random(f"{seed}-{topic}")
        groups_t = sorted(free_by_topic[topic])
        rng.shuffle(groups_t)
        groups_t.sort(key=lambda g: not any(by_name[n]["source"] == "cap" for n in g))  # stable: cap first
        for i, members in enumerate(groups_t):
            for n in members:
                side[n] = "val" if i < val_per_topic else "train"
    return side, note


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--old", type=Path, required=True, help="old working folder (with split.csv)")
    parser.add_argument("--intake", type=Path, required=True, help="intake run made with --dedupe")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--val-per-topic", type=int, default=4, help="new validation groups per topic")
    parser.add_argument("--seed", type=int, default=2026)
    args = parser.parse_args()

    old_items = list(csv.DictReader((args.old / "items.csv").open(encoding="utf-8")))
    old_split = {r["filename"]: r for r in csv.DictReader((args.old / "split.csv").open(encoding="utf-8"))}
    old_sha = {r["sha256"]: r["filename"] for r in old_items}
    new_items = [r for r in csv.DictReader((args.intake / "items.csv").open(encoding="utf-8")) if r.get("relpath")]
    plan = list(csv.DictReader((args.intake / "same_bytes.csv").open(encoding="utf-8")))

    images = args.out / "images"
    images.mkdir(parents=True, exist_ok=False)
    taken = set()
    items, mapping = [], []

    for r in old_items:
        link(args.old / "images" / r["filename"], images / r["filename"])
        info = parse(r["filename"])
        taken.add((info["topic"], info["source"], info["kind"], info["number"]))
        topic = old_split.get(r["filename"], {}).get("topic") or r["topic"]
        items.append({"filename": r["filename"], "topic": topic, "source": r["source"], "kind": r["kind"],
                      "sha256": r["sha256"], "origin": "old", "filed_under": ""})

    filed = defaultdict(set)
    for row in plan:
        info = parse(row["name"])
        if info:
            filed[row["sha256"]].add(info["topic"])

    working_of_sha = dict((sha, name) for sha, name in old_sha.items())
    for r in sorted(new_items, key=lambda r: r["filename"]):
        sha = r["sha256"]
        if sha in old_sha:
            mapping.append({"extracted": r["relpath"], "working": old_sha[sha], "action": "already in the old working copy"})
            continue
        info = parse(r["filename"])
        if info is None:
            mapping.append({"extracted": r["relpath"], "working": "", "action": "left out: name not understood"})
            continue
        number = info["number"]
        if (info["topic"], info["source"], info["kind"], number) in taken:
            number = 900
            while (info["topic"], info["source"], info["kind"], number) in taken:
                number += 1
        taken.add((info["topic"], info["source"], info["kind"], number))
        new = working_name(info, number)
        link(args.intake / "extracted" / r["relpath"], images / new)
        working_of_sha[sha] = new
        action = "linked" if new == r["filename"] else "linked, renamed"
        mapping.append({"extracted": r["relpath"], "working": new, "action": action})
        others = sorted(filed[sha] - {info["topic"]})
        items.append({"filename": new, "topic": info["topic"], "source": info["source"], "kind": info["kind"],
                      "sha256": sha, "origin": "new", "filed_under": ";".join(others)})

    # ss/cap pairs through every name a content had in the zips.
    by_key = defaultdict(set)
    for row in plan:
        info = parse(row["name"])
        if info and row["sha256"] in working_of_sha:
            by_key[(info["topic"], info["kind"], info["number"], info["source"])].add(working_of_sha[row["sha256"]])
    for r in old_items:  # old names (topic spelling already fixed)
        info = parse(r["filename"])
        by_key[(info["topic"], info["kind"], info["number"], info["source"])].add(r["filename"])
    pairs = set()
    for (topic, kind, number, source), names in by_key.items():
        if source != "ss":
            continue
        for a in names:
            for b in by_key.get((topic, kind, number, "cap"), ()):
                pairs.add((a, b))

    s_items = [i for i in items if i["kind"] == "S"]
    hashes = {i["filename"]: dc.dhash(images / i["filename"]) for i in s_items}
    near = [(a, b) for a, b, _ in dc.near_duplicate_pairs(hashes)]
    old_side = {n: r["split"] for n, r in old_split.items()}
    side, note = extend_split(s_items, old_side, sorted(pairs), near, args.val_per_topic, args.seed)

    for i in items:
        i["dhash"] = hashes.get(i["filename"], "")
    with (args.out / "items.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, ["filename", "topic", "source", "kind", "sha256", "dhash", "origin", "filed_under"])
        writer.writeheader()
        writer.writerows(sorted(items, key=lambda i: i["filename"]))
    with (args.out / "mapping.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, ["extracted", "working", "action"])
        writer.writeheader()
        writer.writerows(mapping)
    with (args.out / "split.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["filename", "topic", "source", "split", "origin", "topic_by_name", "filed_under", "note"])
        for i in sorted(s_items, key=lambda i: i["filename"]):
            n = i["filename"]
            writer.writerow([n, i["topic"], i["source"], side.get(n, ""), i["origin"],
                             old_split.get(n, {}).get("topic_by_name", i["topic"]), i["filed_under"], note.get(n, "")])

    counts = Counter((i["origin"], side.get(i["filename"]) or "left out") for i in s_items)
    summary = {
        "old": str(args.old), "intake": str(args.intake),
        "images": len(items), "old_images": sum(i["origin"] == "old" for i in items),
        "new_images": sum(i["origin"] == "new" for i in items),
        "kind_S": len(s_items), "split": {f"{o} {s}": c for (o, s), c in sorted(counts.items())},
        "ss_cap_pairs_S": sum(1 for a, b in pairs if a in hashes and b in hashes),
        "near_duplicate_pairs_S": len(near),
        "pairs_apart": [(a, b) for a, b in pairs if a in hashes and b in hashes
                        and side.get(a) and side.get(b) and side[a] != side[b]],
        "old_sides_changed": [n for n, s in old_side.items() if side.get(n) != s],
    }
    (args.out / "summary.json").write_text(json.dumps(summary, indent=1), encoding="utf-8")
    print(json.dumps({k: v for k, v in summary.items() if k not in ("old", "intake")}, indent=1))
    # Old sides never change (the eval set stays frozen), so two OLD images
    # that only a new file name links can end up apart: listed for a person
    # to look at. In the 2026-11-18 delivery none of them was the same
    # formula (ss and cap were numbered independently).
    if summary["pairs_apart"]:
        print("Pairs by number on different sides (check by eye):", len(summary["pairs_apart"]))
    return 1 if summary["old_sides_changed"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
