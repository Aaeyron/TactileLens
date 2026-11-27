"""The formula-crop training list for version 3 (pseudo-labels, nobody checked them).

Input: filter_crop_labels.py's decisions (kept crops, offline reading with
confidence) and PaddleOCR-VL's readings of the crops it reached
(suggest_vl_resumable.py). Per crop:

  agreed        PaddleOCR-VL and the offline model read it the same way
  teacher       they differ; PaddleOCR-VL's reading passes the checks (it is the label)
  offline only  PaddleOCR-VL did not reach it; the offline reading is the label, only
                when its weakest-symbol confidence is at least --threshold
  rejected      PaddleOCR-VL's reading fails the basic checks or does not render

Crops whose offline reading failed (filter_crop_labels.py: "PaddleOCR-VL only")
can only get a teacher label (and are dropped if it is trivial). --analyse
prints, per confidence threshold, how often the offline reading equals
PaddleOCR-VL's on the crops it read, and how many unread crops pass.

Checks as build_pseudo_labels.py (and its leak guard against eval and validation
labels), at most 3 copies of a reading per topic. Selection: at most --cap crops,
spread evenly over topic x kind (a group's unused share goes to the others),
PaddleOCR-VL labels first, offline-only crops at most --offline-share of the
selection (0 = none).

  python build_crop_train.py --working <working folder> --threshold 0.9 [--cap 8000 --offline-share 0.4]

Writes <working>/train_sets/crops_v3: train.txt (LF), images (a folder junction),
manifest.csv, report.json, report.md. Python: paddle_onnx_env (rendering is
checked with paddle_formula_env).
"""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "data_preparation"))

from build_pseudo_labels import choose, junction, read_list  # noqa: E402
from compare_formula import notation_key  # noqa: E402
from evaluate_formula import TOKEN  # noqa: E402
from filter_crop_labels import FORMULA_PYTHON, NEAR_DUPLICATE_COPIES, trivial  # noqa: E402

V2_ITEMS = 2284
MAX_CROPS_PER_V2_ITEM = 3
VL_ONLY = "PaddleOCR-VL only"
THRESHOLDS = (0.5, 0.6, 0.7, 0.8, 0.85, 0.9, 0.95, 0.97, 0.99)


def threshold_table(rows: list[dict], vl: dict, held: set[str]) -> dict:
    """How often the offline reading equals PaddleOCR-VL's (notation-normalized) at or above
    each weakest-symbol confidence, on the filtered crops PaddleOCR-VL read with a usable
    reading; and how many unread filtered crops pass each threshold."""

    read, unread = [], []
    for r in rows:
        if r["decision"] == VL_ONLY:
            continue
        p = vl.get(r["crop"])
        if p is None:
            unread.append(float(r["weakest"]))
            continue
        if p.get("error"):
            continue
        d = choose(r["crop"], r["label"], p["blocks"], held)
        if d["group"] in ("agreed", "teacher"):
            read.append((float(r["weakest"]), d["group"] == "agreed"))
    table = []
    for t in THRESHOLDS:
        above = [ok for w, ok in read if w >= t]
        table.append({"threshold": t, "read_at_or_above": len(above), "agree": sum(above),
                      "agree_pct": round(100 * sum(above) / len(above), 1) if above else None,
                      "unread_passing": sum(w >= t for w in unread)})
    return {"read_usable": len(read), "agree_all": sum(ok for _, ok in read), "unread": len(unread), "table": table}


def even_quotas(available: dict, cap: int) -> dict:
    """Split `cap` evenly over the groups; a group's unused share goes to the others."""

    quota = {k: 0 for k in available}
    left, open_groups = cap, [k for k in available if available[k] > 0]
    while left > 0 and open_groups:
        share = max(left // len(open_groups), 1)
        for k in list(open_groups):
            take = min(share, available[k] - quota[k], left)
            quota[k] += take
            left -= take
            if quota[k] >= available[k]:
                open_groups.remove(k)
            if left == 0:
                break
    return quota


def select(rows: list[dict], cap: int, offline_share: float) -> list[dict]:
    """VL-labelled crops first in every topic x kind group; offline-only ones fill up to their share."""

    groups: dict = defaultdict(list)
    for r in rows:
        groups[(r["topic"], r["kind"])].append(r)
    for g in groups.values():
        g.sort(key=lambda r: (r["group"] == "offline only", r["source"] != "cap", r["vl_rank"]))
    quota = even_quotas({k: len(v) for k, v in groups.items()}, cap)
    picked = [r for k, g in groups.items() for r in g[: quota[k]]]
    vl = [r for r in picked if r["group"] != "offline only"]
    offline = [r for r in picked if r["group"] == "offline only"]
    allowed = int(offline_share * len(vl) / (1 - offline_share)) if offline_share < 1 else len(offline)
    if len(offline) > allowed:  # keep the offline-only crops spread over the groups
        by_group: dict = defaultdict(list)
        for r in offline:
            by_group[(r["topic"], r["kind"])].append(r)
        keep = even_quotas({k: len(v) for k, v in by_group.items()}, allowed)
        offline = [r for k, v in by_group.items() for r in v[: keep[k]]]
    return vl + offline


def render_ok(labels: list[str], folder: Path) -> list[bool]:
    (folder / "render_in.json").write_text(json.dumps(labels), encoding="utf-8")
    subprocess.run([str(FORMULA_PYTHON), str(HERE / "filter_crop_labels.py"), "--render-check",
                    str(folder / "render_in.json"), str(folder / "render_out.json")], check=True)
    return json.loads((folder / "render_out.json").read_text(encoding="utf-8"))


def main() -> None:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", required=True, type=Path)
    parser.add_argument("--threshold", type=float, help="weakest-symbol confidence for offline-only labels")
    parser.add_argument("--analyse", action="store_true",
                        help="only print how often offline and PaddleOCR-VL agree per confidence threshold")
    parser.add_argument("--cap", type=int, default=8000)
    parser.add_argument("--offline-share", type=float, default=0.4, help="largest share of offline-only crops; 0 = none")
    args = parser.parse_args()
    if not args.analyse and args.threshold is None:
        parser.error("--threshold is needed to build the list (run --analyse first)")
    crops = args.working / "crops_mtw"
    out = args.working / "train_sets" / "crops_v3"
    out.mkdir(parents=True, exist_ok=True)

    with (crops / "filter" / "decisions.csv").open(encoding="utf-8", newline="") as handle:
        kept = [r for r in csv.DictReader(handle) if r["decision"] in ("kept", VL_ONLY)]
    vl = {}
    vl_path = crops / "suggest_vl.jsonl"
    for line in vl_path.read_text(encoding="utf-8").splitlines() if vl_path.exists() else []:
        p = json.loads(line)
        vl[p["id"]] = p
    held = {notation_key(l) for n in ("eval.txt", "val_all.txt") for _, l in read_list(args.working / "labels" / n)}

    if args.analyse:
        print(json.dumps(threshold_table(kept, vl, held), indent=1))
        return

    rows = []
    for r in kept:
        failure = r["decision"] == VL_ONLY
        r = dict(r, weakest=float(r["weakest"]), vl_rank=int(r["vl_rank"]),
                 origin="offline failure" if failure else "filtered")
        p = vl.get(r["crop"])
        if failure:  # the offline reading failed: a teacher label or nothing
            if p is None or p.get("error"):
                r.update(group="not used", offline=r["label"], label="", reason="offline failure, no PaddleOCR-VL reading")
            else:
                decision = choose(r["crop"], "", p["blocks"], held)
                r.update(offline=r["label"], group=decision["group"], label=decision["label"], reason=decision["reason"])
                if r["group"] == "teacher" and trivial(r["label"], TOKEN.findall(r["label"])):
                    r.update(group="rejected", reason="trivial")
        elif p is None:
            ok = r["weakest"] >= args.threshold
            r.update(group="offline only" if ok else "not used", offline=r["label"],
                     reason="" if ok else f"offline confidence below {args.threshold}")
        elif p.get("error"):
            r.update(group="rejected", offline=r["label"], label="", reason=f"PaddleOCR-VL error: {p['error'][:80]}")
        else:
            decision = choose(r["crop"], r["label"], p["blocks"], held)
            r.update(offline=r["label"], group=decision["group"], label=decision["label"], reason=decision["reason"])
        rows.append(r)
    teacher = [r for r in rows if r["group"] == "teacher"]
    for r, ok in zip(teacher, render_ok([r["label"] for r in teacher], out)):
        if not ok:
            r.update(group="rejected", reason="PaddleOCR-VL reading does not render")

    usable = [r for r in rows if r["group"] in ("agreed", "teacher", "offline only")]
    seen: Counter = Counter()
    for r in sorted(usable, key=lambda r: (r["group"] == "offline only", r["source"] != "cap", r["vl_rank"])):
        key = (r["topic"], notation_key(r["label"]))
        seen[key] += 1
        if seen[key] > NEAR_DUPLICATE_COPIES:
            r.update(group="not used", reason=f"more than {NEAR_DUPLICATE_COPIES} copies of the label in the topic")
    usable = [r for r in usable if r["group"] != "not used"]
    chosen = select(usable, args.cap, args.offline_share)
    chosen_names = {r["crop"] for r in chosen}
    for r in usable:
        if r["crop"] not in chosen_names:
            r.update(group="not used", reason="over the cap or the offline-only share")

    junction(out / "images", crops / "images")
    chosen.sort(key=lambda r: r["crop"])
    (out / "train.txt").write_bytes("".join(f"images/{r['crop']}\t{r['label']}\n" for r in chosen).encode("utf-8"))
    with (out / "manifest.csv").open("w", encoding="utf-8", newline="") as handle:
        fields = ["crop", "source_image", "topic", "source", "kind", "category", "origin", "group", "label", "offline",
                  "weakest", "vl_rank", "reason"]
        writer = csv.DictWriter(handle, fields, extrasaction="ignore", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    ratio = min(1.0, round(MAX_CROPS_PER_V2_ITEM * V2_ITEMS / len(chosen), 4)) if chosen else 0.0
    groups = Counter(r["group"] for r in chosen)
    report = {
        "kept_after_filter": len(rows), "read_by_paddleocr_vl": sum(r["crop"] in vl for r in rows),
        "groups_all": dict(Counter(r["group"] for r in rows)),
        "rejected_reasons": dict(Counter(r["reason"] for r in rows if r["group"] == "rejected")),
        "selected": len(chosen), "selected_groups": dict(groups),
        "offline_only_share": round(groups["offline only"] / len(chosen), 4) if chosen else 0.0,
        "threshold": args.threshold, "offline_share_limit": args.offline_share, "cap": args.cap,
        "offline_only_candidates": sum(r["origin"] == "filtered" and r["crop"] not in vl for r in rows),
        "offline_only_passing_threshold": sum(r["origin"] == "filtered" and r["crop"] not in vl
                                              and r["weakest"] >= args.threshold for r in rows),
        "offline_failures_read_by_paddleocr_vl": sum(r["origin"] == "offline failure" and r["crop"] in vl for r in rows),
        "offline_failures_teacher_labels": sum(r["origin"] == "offline failure" and r["group"] == "teacher" for r in rows),
        "offline_failures_selected": sum(r["origin"] == "offline failure" for r in chosen),
        "selected_by_origin_and_group": {f"{o}/{g}": n for (o, g), n in
                                         sorted(Counter((r["origin"], r["group"]) for r in chosen).items())},
        "selected_by_topic": dict(sorted(Counter(r["topic"] for r in chosen).items())),
        "selected_by_kind": dict(sorted(Counter(r["kind"] for r in chosen).items())),
        "selected_by_source": dict(sorted(Counter(r["source"] for r in chosen).items())),
        "selected_by_topic_and_kind": {f"{t}/{k}": n for (t, k), n in
                                       sorted(Counter((r["topic"], r["kind"]) for r in chosen).items())},
        "ratio_per_epoch": ratio, "crops_per_epoch": round(len(chosen) * ratio),
        "selected_labels_equal_to_held_out": sum(notation_key(r["label"]) in held for r in chosen),
    }
    (out / "report.json").write_text(json.dumps(report, indent=1) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
