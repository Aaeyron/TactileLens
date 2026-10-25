"""Generate synthetic line images with labels and a manifest.

Examples (from tools/training):
  python generate_synthetic.py --set eval --count 200
  python generate_synthetic.py --set train --count 20000
  python generate_synthetic.py --set val --count 1000

Sets and their default seeds (fixed, so runs are reproducible):
  eval   -> <root>/eval/synthetic   seed 20261025   (held out)
  train  -> <root>/data/synthetic   seed 1          train.txt
  val    -> <root>/data/synthetic   seed 2          val.txt

The eval set is: your seven fixed cases x 10 renderings, lines from the
topic templates, and about 20% control lines without superscripts.
Train/val follow the target_synthetic weights in topics.csv.
A set is rewritten from scratch each run (its images, label file and
manifest), so the same seed always gives the same files.
"""

from __future__ import annotations

import argparse
import csv
import random
import shutil
from pathlib import Path

import numpy as np

from app_ocr import write_image
from common import (
    Layout,
    check_no_eval_in_training,
    load_character_list,
    root_dir,
    unsupported_characters,
    write_labels,
    write_manifest,
)
from render import MATH_FACES, fonts_for, photo_line, photo_line_v2, pick_font
from textgen import MINUS, FIXED_CASES, Line, fixed_line, make_line, with_item_label, with_minus

HERE = Path(__file__).resolve().parent
SET_NAMES = {"eval": "synthetic-eval", "train": "synthetic-train", "val": "synthetic-val"}
DEFAULT_SEEDS = {"eval": 20261025, "train": 1, "val": 2}
PREFIX = {"eval": "syn_ev", "train": "syn_tr", "val": "syn_va"}

# topics.csv control rows added after the synthetic eval set was frozen.
ADDED_AFTER_EVAL_FREEZE = {"plain_text", "hyphenated_words", "ranges_and_dates"}


def read_topics(path: Path) -> list[dict]:
    with open(path, encoding="utf-8", newline="") as handle:
        return [row for row in csv.DictReader(handle) if row.get("topic")]


def plan_lines(kind: str, count: int, topics: list[dict], rng: random.Random, min_plain: float) -> list[Line]:
    if kind == "eval":
        lines = [fixed_line(t, s, text) for t, s, text in FIXED_CASES for _ in range(10)]
        # These rows were added after the eval set was frozen; leaving them
        # out keeps the eval set identical to the baseline's.
        controls = [r for r in topics if r["topic"] == "controls" and r["subcase"] not in ADDED_AFTER_EVAL_FREEZE]
        others = [r for r in topics if r["topic"] != "controls"]
        n_controls = round((count - len(lines)) * 0.3)
        for _ in range(n_controls):
            row = rng.choice(controls)
            lines.append(make_line(row["topic"], row["subcase"], row["example"], rng))
        while len(lines) < count:
            row = rng.choice(others)
            lines.append(make_line(row["topic"], row["subcase"], row["example"], rng))
        return lines[:count]

    # At least min_plain of the lines come from the control sub-cases (no
    # superscripts: plain sentences, equations, brackets), so training
    # keeps the model reading ordinary text; the rest follow the
    # target_synthetic weights of the other rows.
    controls = [r for r in topics if r["topic"] == "controls"]
    others = [r for r in topics if r["topic"] != "controls"]
    control_weights = [float(r.get("target_synthetic") or 0) for r in controls]
    other_weights = [float(r.get("target_synthetic") or 0) for r in others]
    lines = []
    for _ in range(count):
        if rng.random() < min_plain:
            row = rng.choices(controls, weights=control_weights, k=1)[0]
        else:
            row = rng.choices(others, weights=other_weights, k=1)[0]
        lines.append(make_line(row["topic"], row["subcase"], row["example"], rng))
    return lines


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--set", choices=sorted(SET_NAMES), required=True)
    parser.add_argument("--count", type=int, required=True)
    parser.add_argument("--seed", type=int)
    parser.add_argument("--root")
    parser.add_argument("--topics", default=str(HERE / "topics.csv"))
    parser.add_argument("--profile", choices=["v1", "v2"], help="default: v1 for eval, v2 for train/val")
    parser.add_argument("--min-plain", type=float, default=0.25,
                        help="train/val: share of lines without superscripts (controls)")
    args = parser.parse_args()

    layout = Layout(root_dir(args.root))
    layout.make_dirs()
    set_name = SET_NAMES[args.set]
    seed = args.seed if args.seed is not None else DEFAULT_SEEDS[args.set]
    rng = random.Random(seed)
    np.random.seed(seed % (1 << 32))

    characters = load_character_list()
    topics = read_topics(Path(args.topics))
    lines = plan_lines(args.set, args.count, topics, rng, args.min_plain)

    out_dir = layout.set_dir(set_name)
    images_dir = out_dir / "images"
    prefix = PREFIX[args.set]
    for old in images_dir.glob(f"{prefix}_*.png"):
        old.unlink()

    # v1: the frozen eval set's look. v2 (train/val): more faces, worksheet
    # surroundings, stronger photo effects, item labels, hyphen or true
    # minus as printed.
    profile = args.profile or ("v1" if args.set == "eval" else "v2")

    labels, manifest = [], []
    for index, line in enumerate(lines):
        if profile == "v2" and rng.random() < 0.2:
            line = with_item_label(line, rng)
        label = line.label
        bad = unsupported_characters(label, characters)
        if bad:
            raise SystemExit(f"Label {label!r} uses characters the recognizer does not have: {bad}")

        # Glyph style only with fonts that have every superscript needed.
        style = "typeset"
        glyph_fonts = fonts_for(label, layout.fonts, profile)
        if line.has_superscript and glyph_fonts and rng.random() < 0.3:
            style = "glyph"
            choices = glyph_fonts
        else:
            plain = "".join(text for text, _ in line.segments)
            choices = fonts_for(plain, layout.fonts, profile)
        if not choices:
            raise SystemExit(f"No font can draw {label!r}")
        font = pick_font(choices, rng)

        if profile == "v2":
            # A true minus is more common in math typesetting, a hyphen in
            # word-processor worksheets. The label follows what is drawn.
            true_minus = rng.random() < (0.8 if font.name.startswith(MATH_FACES) else 0.45)
            line = with_minus(line, MINUS if true_minus else "-")
            label = line.label
            image, drawing = photo_line_v2(line.segments, font, rng, style)
            drawing["minus"] = "−" if true_minus else "-"
            if "item_label" in line.notes:
                drawing["item_label"] = line.notes["item_label"]
        else:
            image, drawing = photo_line(line.segments, font, rng, style)
        name = f"{prefix}_{index:06d}.png"
        write_image(images_dir / name, image)
        relative = f"images/{name}"
        labels.append((relative, label))
        manifest.append({
            "id": name[:-4],
            "path": relative,
            "label": label,
            "source": "synthetic",
            "set": set_name,
            "topic": line.topic,
            "subcase": line.subcase,
            "fixed_case": line.fixed,
            "has_superscript": line.has_superscript,
            "seed": seed,
            **drawing,
        })

    write_labels(layout.label_file(set_name), labels)
    write_manifest(layout.manifest(set_name), manifest)
    check_no_eval_in_training(layout)
    print(f"{set_name}: {len(labels)} images in {images_dir} (seed {seed})")
    print(f"labels:   {layout.label_file(set_name)}")
    print(f"manifest: {layout.manifest(set_name)}")


if __name__ == "__main__":
    main()
