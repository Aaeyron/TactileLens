"""Split an audited intake into held-out eval, validation and training.

From tools/dataset, after intake.py:
  python split_dataset.py --intake <root>/intake/<run>
  python split_dataset.py --intake ... --eval 0.10 --val 0.10 --seed 7

Rules
  - Only items without intake errors are used.
  - Items that belong together stay in ONE split (a "group"): same bytes,
    near-duplicates, the same task + target (an ss/cap pair of one item,
    or the same exercise twice), and ss/cap files with the same topic,
    kind and number.
  - Held-out eval is drawn per topic, mainly from labelled phone captures
    (cap): groups with a cap image are taken first; ss-only groups only if
    a topic has too few caps (reported). Then validation, then training.
  - A split already given in the labels CSV is kept for eval; a group with
    any eval member is eval.
  - Leak guard against every existing eval set: the recognizer's
    eval/real and eval/synthetic and every item ever put in a held-out eval
    split (frozen_eval.jsonl). An item that matches the frozen eval of an
    earlier split goes to eval again. An item that matches the recognizer's
    eval sets (same bytes or near-duplicate) stops the split: nothing is
    written unless --drop-eval-overlap leaves those items out.
  - Before writing, it checks again that no train/val item has the bytes,
    a near-duplicate or the target of an eval item.

Output <out>/<split id>/ (default <root>/splits/):
  images/...                  copies of the used images (or hard links, --link)
  labels.csv                  filename,task,target,split -> convert_to_sft.py
  rec_{train,val,eval}.txt    one-line text items in the recognizer's charset
                              (kinds S, M, T) -> tools/training/train_full.py
  formula_{train,val,eval}.txt  formula items (LaTeX, no delimiters) ->
                              PP-FormulaNet training lists
  split_report.md / .json     counts per topic x split x source, exclusions
and appends this split's eval items to the frozen eval registry, so later
splits never train on them.
"""

from __future__ import annotations

import argparse
import datetime as dt
import os
import random
import shutil
from collections import Counter, defaultdict
from pathlib import Path

import dataset_common as dc
from dataset_common import rec_common, vl_common

SPLITS = ("train", "val", "eval")
REC_KINDS = {"S", "M", "T"}


class SplitError(RuntimeError):
    pass


def build_groups(items: list[dict]) -> dict[str, str]:
    uf = dc.UnionFind()
    for item in items:
        uf.find(item["filename"])
    by_sha, by_key, by_number = defaultdict(list), defaultdict(list), defaultdict(list)
    for item in items:
        by_sha[item["sha256"]].append(item["filename"])
        by_key[(item["task"], dc.normalize_target(item["task"], item["target"]))].append(item["filename"])
        by_number[(item["topic"], item["kind"], int(item["number"]))].append(item)
    for names in list(by_sha.values()) + list(by_key.values()):
        for name in names[1:]:
            uf.union(names[0], name)
    for group in by_number.values():
        if {i["source"] for i in group} >= {"ss", "cap"}:
            for item in group[1:]:
                uf.union(group[0]["filename"], item["filename"])
    for a, b, _ in dc.near_duplicate_pairs({i["filename"]: i["dhash"] for i in items}):
        uf.union(a, b)
    return {item["filename"]: uf.find(item["filename"]) for item in items}


def eval_overlap(items: list[dict], root: Path, registry: Path | None) -> tuple[dict[str, str], dict[str, str]]:
    """(must_be_eval, must_not_train): filename -> reason."""

    existing = dc.existing_eval_images(root, registry)
    keys = {v["key"]: v["from"] for v in existing.values() if v.get("key")}
    must_eval, blocked = {}, {}
    for item in items:
        hit = existing.get(item["sha256"])
        how = "same bytes"
        if hit is None:
            for value in existing.values():
                if value.get("dhash") and dc.is_near_duplicate(value["dhash"], item["dhash"]):
                    hit, how = value, "near-duplicate"
                    break
        key = f"{item['task']}:{dc.normalize_target(item['task'], item['target'])}"
        if hit is None and key in keys:
            hit, how = {"from": keys[key]}, "same task and target"
        if hit is None:
            continue
        reason = f"{how} as an image in {hit['from']}"
        if hit["from"].startswith("frozen eval"):
            must_eval[item["filename"]] = reason
        else:
            blocked[item["filename"]] = reason
    return must_eval, blocked


def assign(items: list[dict], groups: dict[str, str], must_eval: set[str], eval_frac: float, val_frac: float,
           seed: int, keep_given: bool) -> tuple[dict[str, str], list[str]]:
    members = defaultdict(list)
    for item in items:
        members[groups[item["filename"]]].append(item)
    split_of: dict[str, str] = {}
    notes: list[str] = []

    for gid, group in members.items():
        if any(i["filename"] in must_eval or (keep_given and i["split_given"] == "eval") for i in group):
            split_of[gid] = "eval"

    by_topic = defaultdict(list)
    for gid, group in members.items():
        by_topic[sorted(i["topic"] for i in group)[0]].append(gid)

    rng = random.Random(seed)
    for topic in sorted(by_topic):
        gids = sorted(by_topic[topic])
        rng.shuffle(gids)
        total = sum(len(members[g]) for g in gids)
        want_eval = round(total * eval_frac)
        want_val = round(total * val_frac)
        have = Counter()
        for g in gids:
            if g in split_of:
                have[split_of[g]] += len(members[g])

        def take(split: str, want: int, candidates: list[str]) -> None:
            for g in candidates:
                if have[split] >= want:
                    return
                if g not in split_of:
                    split_of[g] = split
                    have[split] += len(members[g])

        with_cap = [g for g in gids if any(i["source"] == "cap" for i in members[g])]
        take("eval", want_eval, with_cap)
        if have["eval"] < want_eval:
            notes.append(f"{topic}: not enough cap images for eval; eval also has screenshots")
            take("eval", want_eval, gids)
        if not keep_given:
            take("val", want_val, gids)
        else:
            given_val = [g for g in gids if any(i["split_given"] == "val" for i in members[g])]
            take("val", want_val, given_val + gids)
        for g in gids:
            split_of.setdefault(g, "train")
        if total and have["eval"] == 0:
            notes.append(f"{topic}: no eval items (only {total} usable)")

    return {item["filename"]: split_of[groups[item["filename"]]] for item in items}, notes


def verify(items: list[dict], split: dict[str, str]) -> None:
    """Independent check after assignment: nothing in train/val looks like
    any eval item (bytes, near-duplicate, task + target)."""

    evals = [i for i in items if split[i["filename"]] == "eval"]
    train = [i for i in items if split[i["filename"]] != "eval"]
    eval_sha = {i["sha256"] for i in evals}
    eval_key = {(i["task"], dc.normalize_target(i["task"], i["target"])) for i in evals}
    problems = []
    for item in train:
        if item["sha256"] in eval_sha:
            problems.append(f"{item['filename']}: same bytes as an eval item")
        if (item["task"], dc.normalize_target(item["task"], item["target"])) in eval_key:
            problems.append(f"{item['filename']}: same target as an eval item")
        for e in evals:
            if dc.is_near_duplicate(e["dhash"], item["dhash"]):
                problems.append(f"{item['filename']}: near-duplicate of eval item {e['filename']}")
                break
    if problems:
        raise SplitError("leak check failed: " + "; ".join(problems[:5]))


def recognizer_line(item: dict) -> bool:
    target = item["target"].strip()
    return (item["task"] == "text" and item["kind"] in REC_KINDS and "\n" not in target
            and not dc.recognizer_unsupported(target))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--intake", required=True, help="an intake run folder (has items.csv and extracted/)")
    parser.add_argument("--root", help="training root (eval sets)")
    parser.add_argument("--out", help="default <root>/splits")
    parser.add_argument("--registry", help="frozen eval registry (default <root>/splits/frozen_eval.jsonl)")
    parser.add_argument("--eval", type=float, default=0.10)
    parser.add_argument("--val", type=float, default=0.10)
    parser.add_argument("--seed", type=int, default=20261107)
    parser.add_argument("--ignore-given-splits", action="store_true", help="do not keep eval/val from the labels CSV")
    parser.add_argument("--drop-eval-overlap", action="store_true",
                        help="leave out items that match the recognizer's eval sets instead of stopping")
    parser.add_argument("--allow-flagged", action="store_true",
                        help="use items with personal-data / third-party flags (only after checking them)")
    parser.add_argument("--link", action="store_true", help="hard-link images instead of copying")
    args = parser.parse_args()

    root = rec_common.root_dir(args.root)
    intake = Path(args.intake)
    registry = Path(args.registry) if args.registry else dc.registry_path(root)
    out_base = Path(args.out) if args.out else rec_common.Layout(root).splits

    all_items = dc.read_items(intake / "items.csv")
    excluded = {}
    for item in all_items:
        if item["errors"]:
            excluded[item["filename"]] = "intake error: " + item["errors"][0]
        elif not args.allow_flagged and any(not f.startswith("ALREADY IN AN EVAL SET") for f in item["flags"]):
            excluded[item["filename"]] = "flagged (check, then --allow-flagged): " + item["flags"][0]
    items = [i for i in all_items if i["filename"] not in excluded]

    must_eval, blocked = eval_overlap(items, root, registry)
    if blocked and not args.drop_eval_overlap:
        for name, reason in sorted(blocked.items()):
            print(f"LEAK: {name}: {reason}")
        raise SystemExit(f"{len(blocked)} item(s) match an existing eval set; nothing written "
                         "(remove them, or --drop-eval-overlap to leave them out).")
    for name, reason in blocked.items():
        excluded[name] = "matches an existing eval set: " + reason
    items = [i for i in items if i["filename"] not in blocked]
    if not items:
        raise SystemExit("No usable items.")

    groups = build_groups(items)
    split, notes = assign(items, groups, set(must_eval), args.eval, args.val, args.seed, not args.ignore_given_splits)
    verify(items, split)

    split_id = dt.datetime.now().strftime("%Y%m%d_%H%M%S") + f"_s{args.seed}"
    out = out_base / split_id
    images = out / "images"
    extracted = intake / "extracted"
    for item in items:
        target = images / item["relpath"]
        target.parent.mkdir(parents=True, exist_ok=True)
        (os.link if args.link else shutil.copy2)(extracted / item["relpath"], target)

    def path_of(item: dict) -> str:
        return "images/" + item["relpath"]

    with open(out / "labels.csv", "w", encoding="utf-8", newline="") as handle:
        import csv
        writer = csv.DictWriter(handle, fieldnames=["filename", "task", "target", "split"])
        writer.writeheader()
        for item in items:
            writer.writerow({"filename": item["filename"], "task": item["task"], "target": item["target"],
                             "split": split[item["filename"]]})

    lists = Counter()
    for name in SPLITS:
        rec = [(path_of(i), i["target"].strip()) for i in items if split[i["filename"]] == name and recognizer_line(i)]
        rec_common.write_labels(out / f"rec_{name}.txt", rec)
        formulas = [(path_of(i), vl_common.strip_math_delimiters(i["target"]).replace("\n", " "))
                    for i in items if split[i["filename"]] == name and i["task"] == "formula"]
        rec_common.write_labels(out / f"formula_{name}.txt", formulas)
        lists[f"rec_{name}"], lists[f"formula_{name}"] = len(rec), len(formulas)

    registry.parent.mkdir(parents=True, exist_ok=True)
    with open(registry, "a", encoding="utf-8", newline="\n") as handle:
        import json
        for item in items:
            if split[item["filename"]] == "eval":
                handle.write(json.dumps({
                    "split_id": split_id, "filename": item["filename"], "sha256": item["sha256"],
                    "dhash": item["dhash"], "key": f"{item['task']}:{dc.normalize_target(item['task'], item['target'])}",
                }, ensure_ascii=False) + "\n")

    write_report(out, items, split, groups, excluded, must_eval, notes, lists, args, intake, registry)
    print((out / "split_report.md").read_text(encoding="utf-8"))
    print(f"Split: {out}")
    print(f"Next (VL):  python ..\\training_vl\\convert_to_sft.py --data {images} --labels {out / 'labels.csv'} --out {out / 'sft'}")
    print(f"Next (rec): python ..\\training\\train_full.py --split {out}")


def write_report(out, items, split, groups, excluded, must_eval, notes, lists, args, intake, registry) -> None:
    grid = Counter((i["topic"], split[i["filename"]], i["source"]) for i in items)
    topics = sorted({i["topic"] for i in items})
    columns = [(s, src) for s in SPLITS for src in ("ss", "cap")]
    lines = [f"# Split {out.name}", "",
             f"From intake `{intake.name}`; seed {args.seed}; eval {args.eval:.0%}, val {args.val:.0%} (per topic, by group).",
             f"Frozen eval registry: `{registry}`.", "",
             f"- Items: {len(items)} in {len(set(groups.values()))} groups; " +
             ", ".join(f"{s} {sum(1 for i in items if split[i['filename']] == s)}" for s in SPLITS),
             f"- Excluded: {len(excluded)}; kept in eval because an earlier split held them out: {len(must_eval)}",
             "- Leak checks passed: no train/val item has the bytes, a near-duplicate or the target of an eval item,"
             " and none matches the recognizer's eval sets.",
             "- Lists: " + ", ".join(f"{k} {v}" for k, v in lists.items()), "",
             "## Topic x split x source", "",
             "| topic | " + " | ".join(f"{s} {src}" for s, src in columns) + " |",
             "|---|" + "---|" * len(columns)]
    for topic in topics:
        lines.append(f"| {topic} | " + " | ".join(str(grid[(topic, s, src)]) for s, src in columns) + " |")
    by_task = Counter((i["task"], split[i["filename"]]) for i in items)
    lines += ["", "## Task x split", "", "| task | " + " | ".join(SPLITS) + " |", "|---|---|---|---|"]
    for task in sorted({t for t, _ in by_task}):
        lines.append(f"| {task} | " + " | ".join(str(by_task[(task, s)]) for s in SPLITS) + " |")
    if notes:
        lines += ["", "## Notes", ""] + [f"- {n}" for n in notes]
    if excluded:
        lines += ["", f"## Excluded: {len(excluded)}", "", "| file | why |", "|---|---|"]
        lines += [f"| {n} | {r.replace('|', '/')} |" for n, r in sorted(excluded.items())]
    (out / "split_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    dc.write_json(out / "split_report.json", {
        "split_id": out.name, "intake": str(intake), "seed": args.seed, "eval": args.eval, "val": args.val,
        "counts": {s: sum(1 for i in items if split[i["filename"]] == s) for s in SPLITS},
        "by_topic_split_source": {f"{t}|{s}|{src}": n for (t, s, src), n in grid.items()},
        "lists": dict(lists), "excluded": excluded, "kept_in_eval": must_eval, "notes": notes,
        "items": {i["filename"]: split[i["filename"]] for i in items},
    })


if __name__ == "__main__":
    main()
