"""Filter the formula crops by their offline reading and order them for PaddleOCR-VL.

Reads <crops>/crops.csv and the original model's readings
(suggest_crop_labels.py --engine paddle, with confidence). For each crop, in order:

  1. no reading, a reading error, or a failed basic check (build_pseudo_labels
     basic_problem: one line, ASCII, balanced braces, no words, at most 80 tokens,
     no runaway repeats, no "[object Object]") -> dropped
  2. does not render with matplotlib's mathtext -> dropped
  3. trivial -> dropped: fewer than 3 LaTeX tokens, or fewer than 5 with no
     operator. Kept even when short: a number followed by letters (3x, 10ab), and
     anything with a superscript, subscript, fraction or root.
  4. label equal to an eval or validation label (notation-normalized) -> dropped
  5. near-duplicate: more than 3 crops with the same notation-normalized reading
     in one topic -> the extra ones dropped (phone captures, then higher
     confidence, kept first)

Valid LaTeX that mathtext cannot draw (\\square, \\boxed, \\big, \\cfrac) is
replaced for the render check only. Crops whose offline reading did not render,
read "[object Object]", had unbalanced braces or a repeated token are the
offline model's own failures: they go to PaddleOCR-VL ("PaddleOCR-VL only",
teacher label only).

PaddleOCR-VL order: the kept crops taken in turn across topic x kind, within
each group phone captures first, then display formulas, then the lowest
weakest-symbol confidence, then the longest reading; the failures, also in turn
across topic x kind, make up 40% of the list until they run out.

  python filter_crop_labels.py --working <working folder>            (paddle_onnx_env)
  python filter_crop_labels.py --render-check <in.json> <out.json>   (paddle_formula_env, matplotlib)

Writes <crops>/filter/: decisions.csv, vl_jobs.json (ordered), report.json,
report.md, examples.md, examples_dropped.png, examples_kept.png.
"""

from __future__ import annotations

import argparse
import csv
import json
import random
import re
import subprocess
import sys
from collections import Counter, defaultdict
from itertools import zip_longest
from pathlib import Path

HERE = Path(__file__).resolve().parent
FORMULA_PYTHON = Path(r"C:\Projects\Capstone\paddle_formula_env\Scripts\python.exe")
NEAR_DUPLICATE_COPIES = 3
OPERATORS = re.compile(r"[=<>+\-/]|\\(?:leq?|geq?|neq?|pm|mp|times|div|cdot|lt|gt)(?![A-Za-z])")
# Valid LaTeX that matplotlib's mathtext cannot draw: replaced for the render check
# only (the saved label stays exactly as read).
RENDER_ONLY = [(re.compile(r"\\square(?![A-Za-z])"), "x"), (re.compile(r"\\boxed(?![A-Za-z])"), ""),
               (re.compile(r"\\[Bb]ig[lr]?(?![A-Za-z])"), ""), (re.compile(r"\\cfrac(?![A-Za-z])"), r"\\frac")]
# Offline readings that failed for these reasons are the model's own failures: the crop
# goes to PaddleOCR-VL (teacher label only), not to the trivial or duplicate filters.
OFFLINE_FAILURES = ("does not render", "basic check: [object Object]", "basic check: unbalanced braces",
                    "basic check: repeated token")
FAILURE_SHARE = 0.4
STRUCTURE = re.compile(r"[\^_]|\\(?:d?frac|tfrac|sqrt)(?![A-Za-z])")
NUMBER_THEN_LETTERS = re.compile(r"^\d+[A-Za-z]+$")


def trivial(label: str, tokens: list[str]) -> bool:
    """True for a crop not worth training on (a single symbol, a bare word)."""

    if STRUCTURE.search(label) or NUMBER_THEN_LETTERS.match(re.sub(r"\s+", "", label)):
        return False
    if len(tokens) < 3:
        return True
    return len(tokens) < 5 and not OPERATORS.search(label)


def render_check(labels: list[str]) -> list[bool]:
    """matplotlib mathtext can draw each label (paddle_formula_env)."""

    import io

    import matplotlib
    matplotlib.use("Agg")
    from matplotlib import mathtext

    out = []
    for label in labels:
        for pattern, replacement in RENDER_ONLY:
            label = pattern.sub(replacement, label)
        try:
            mathtext.math_to_image(f"${label}$", io.BytesIO(), dpi=50, format="png")
            out.append(True)
        except Exception:  # noqa: BLE001  (any parse error means it does not render)
            out.append(False)
    return out


def vl_order(rows: list[dict]) -> list[dict]:
    """Round robin over topic x kind; inside a group the likely weakest readings first."""

    groups: dict = defaultdict(list)
    for r in rows:
        groups[(r["topic"], r["kind"])].append(r)
    for group in groups.values():
        group.sort(key=lambda r: (r["source"] != "cap", r["category"] != "formula_display", r["weakest"], -r["tokens"]))
    ordered = []
    for layer in zip_longest(*(groups[k] for k in sorted(groups))):
        ordered += [r for r in layer if r is not None]
    return ordered


def round_robin(rows: list[dict], key) -> list[dict]:
    """Rows taken in turn across topic x kind, each group in `key` order."""

    groups: dict = defaultdict(list)
    for r in rows:
        groups[(r["topic"], r["kind"])].append(r)
    ordered = []
    for layer in zip_longest(*(sorted(groups[k], key=key) for k in sorted(groups))):
        ordered += [r for r in layer if r is not None]
    return ordered


def interleave(planned: list[dict], failures: list[dict], share: float = FAILURE_SHARE) -> list[dict]:
    """Failures make up `share` of every stretch of the list, until one list runs out."""

    out, p, f = [], 0, 0
    while p < len(planned) or f < len(failures):
        take_failure = f < len(failures) and (p >= len(planned) or f < share * (p + f + 1))
        if take_failure:
            out.append(failures[f])
            f += 1
        else:
            out.append(planned[p])
            p += 1
    return out


def keep_near_duplicates(rows: list[dict], key, copies: int = NEAR_DUPLICATE_COPIES) -> set[str]:
    """The crops to drop: beyond `copies` per (topic, reading), cap and higher confidence kept first."""

    seen: Counter = Counter()
    dropped = set()
    for r in sorted(rows, key=lambda r: (r["source"] != "cap", -r["weakest"], r["crop"])):
        k = (r["topic"], key(r["label"]))
        seen[k] += 1
        if seen[k] > copies:
            dropped.add(r["crop"])
    return dropped


def sheet(rows: list[dict], images: Path, target: Path) -> None:
    from PIL import Image, ImageDraw

    cw, ch = 300, 96
    canvas = Image.new("RGB", (cw * 4, ch * ((len(rows) + 3) // 4)), "white")
    draw = ImageDraw.Draw(canvas)
    for i, r in enumerate(rows):
        x, y = (i % 4) * cw, (i // 4) * ch
        with Image.open(images / r["crop"]) as im:
            im = im.convert("RGB")
            im.thumbnail((cw - 8, ch - 22))
            canvas.paste(im, (x + 4, y + 18))
        draw.text((x + 4, y + 2), f"{i + 1}. {r['label'][:44]}", fill=(170, 0, 0))
        draw.rectangle((x, y, x + cw - 1, y + ch - 1), outline=(200, 200, 200))
    canvas.save(target)


def main() -> None:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", type=Path)
    parser.add_argument("--render-check", nargs=2, type=Path, metavar=("IN", "OUT"))
    parser.add_argument("--seed", type=int, default=2026)
    args = parser.parse_args()
    if args.render_check:
        labels = json.loads(args.render_check[0].read_text(encoding="utf-8"))
        args.render_check[1].write_text(json.dumps(render_check(labels)), encoding="utf-8")
        return

    sys.path.insert(0, str(HERE.parent / "data_preparation"))
    from build_pseudo_labels import basic_problem, read_list
    from compare_formula import notation_key
    from evaluate_formula import TOKEN
    from finalize_labels import unify_label

    crops = args.working / "crops_mtw"
    out = crops / "filter"
    out.mkdir(exist_ok=True)
    with (crops / "crops.csv").open(encoding="utf-8", newline="") as handle:
        meta = {r["crop"]: r for r in csv.DictReader(handle)}
    readings = {}
    for line in (crops / "offline_paddle.jsonl").read_text(encoding="utf-8").splitlines():
        r = json.loads(line)
        readings[r["crop"]] = r
    held = {notation_key(label) for name in ("eval.txt", "val_all.txt")
            for _, label in read_list(args.working / "labels" / name)}

    rows = []
    for name, m in meta.items():
        r = readings.get(name)
        row = {**{k: m[k] for k in ("crop", "source_image", "topic", "source", "kind", "category")},
               "label": "", "weakest": 0.0, "tokens": 0, "decision": "", "reason": ""}
        if r is None or r.get("error"):
            row.update(decision="dropped", reason="no offline reading")
        else:
            problem = basic_problem([{"label": "formula", "content": r["prediction"]}])
            label = unify_label(" ".join(r["prediction"].split()))
            row.update(label=label, weakest=r["weakest"], tokens=len(TOKEN.findall(label)))
            if problem:
                row.update(decision="dropped", reason=f"basic check: {problem}")
        rows.append(row)

    to_render = [r for r in rows if not r["decision"]]
    (out / "render_in.json").write_text(json.dumps([r["label"] for r in to_render]), encoding="utf-8")
    subprocess.run([str(FORMULA_PYTHON), str(Path(__file__).resolve()), "--render-check",
                    str(out / "render_in.json"), str(out / "render_out.json")], check=True)
    for r, ok in zip(to_render, json.loads((out / "render_out.json").read_text(encoding="utf-8"))):
        if not ok:
            r.update(decision="dropped", reason="does not render")
    for r in rows:
        if r["decision"]:
            continue
        if trivial(r["label"], TOKEN.findall(r["label"])):
            r.update(decision="dropped", reason="trivial")
        elif notation_key(r["label"]) in held:
            r.update(decision="dropped", reason="label equals an eval or validation label")
    extra = keep_near_duplicates([r for r in rows if not r["decision"]], notation_key)
    for r in rows:
        if not r["decision"]:
            r.update(decision="dropped", reason=f"more than {NEAR_DUPLICATE_COPIES} copies in the topic") \
                if r["crop"] in extra else r.update(decision="kept")

    for r in rows:
        if r["reason"] in OFFLINE_FAILURES:
            r.update(decision="PaddleOCR-VL only", reason=f"offline failure: {r['reason']}")
    kept = [r for r in rows if r["decision"] == "kept"]
    failures = round_robin([r for r in rows if r["decision"] == "PaddleOCR-VL only"],
                           key=lambda r: (r["source"] != "cap", r["category"] != "formula_display", r["crop"]))
    ordered = interleave(vl_order(kept), failures)
    for rank, r in enumerate(ordered, 1):
        r["vl_rank"] = rank
    images = crops / "images"
    (out / "vl_jobs.json").write_text(json.dumps(
        [{"id": r["crop"], "image": str(images / r["crop"]), "prompt_label": "formula"} for r in ordered]),
        encoding="utf-8")
    with (out / "decisions.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, list(rows[0]) + ["vl_rank"], lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)

    rng = random.Random(args.seed)
    trivial_rows = [r for r in rows if r["reason"] == "trivial"]
    dropped_sample = rng.sample(trivial_rows, min(20, len(trivial_rows)))
    kept_sample = rng.sample(kept, min(20, len(kept)))
    short_kept = [r for r in kept if r["tokens"] < 5]
    sheet(dropped_sample, images, out / "examples_dropped.png")
    sheet(kept_sample, images, out / "examples_kept.png")
    weakest = sorted(r["weakest"] for r in kept)
    report = {
        "crops": len(rows), "kept": len(kept), "paddleocr_vl_only_offline_failures": len(failures),
        "paddleocr_vl_jobs": len(ordered),
        "failures_in_first_2000_jobs": sum(r["decision"] != "kept" for r in ordered[:2000]),
        "dropped": dict(Counter(r["reason"] for r in rows if r["decision"] == "dropped")),
        "kept_by_topic": dict(sorted(Counter(r["topic"] for r in kept).items())),
        "kept_by_kind": dict(sorted(Counter(r["kind"] for r in kept).items())),
        "kept_by_source": dict(sorted(Counter(r["source"] for r in kept).items())),
        "kept_by_category": dict(sorted(Counter(r["category"] for r in kept).items())),
        "kept_short_under_5_tokens": len(short_kept),
        "kept_weakest_confidence_quartiles": [weakest[len(weakest) * q // 4] for q in (1, 2, 3)] if weakest else [],
        "held_out_labels": len(held),
    }
    (out / "report.json").write_text(json.dumps(report, indent=1) + "\n", encoding="utf-8")

    def lines_for(title, sample):
        return [f"## {title}", "", "| # | Crop | Reading | Tokens |", "|---|---|---|---|"] + [
            f"| {i} | {r['crop']} | `{r['label']}` | {r['tokens']} |" for i, r in enumerate(sample, 1)] + [""]

    examples = ["# Trivial filter: random examples (seed %d)" % args.seed, ""] + lines_for(
        "20 dropped as trivial (examples_dropped.png)", dropped_sample) + lines_for(
        "20 kept (examples_kept.png)", kept_sample)
    patterns = Counter(r["label"] for r in short_kept)
    examples += ["## Short readings that are kept (under 5 tokens), most frequent", ""] + [
        f"- `{label}`: {n}" for label, n in patterns.most_common(25)]
    (out / "examples.md").write_text("\n".join(examples) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
