"""Cut the lines out of photos of printed worksheets and label them.

Example (from tools/training):
  python pair_photos.py --sheet W001 photos/W001_a.jpg photos/W001_b.jpg

For each photo: the app's detector (ported, app_ocr.py) finds the text
boxes; boxes on the same printed row are joined; each row is read with the
current recognizer; the rows are lined up, top to bottom, with the sheet's
known lines (worksheets/<sheet>.json). A row is labelled automatically only
when it matches one known line clearly (similarity with superscripts read
as plain characters >= --min-similarity, and clearly better than the next
candidate). Everything else goes to <root>/review/<sheet>/ with a
review.tsv line, never into a label file.

Labelled crops go to eval/real (sheets made with --split eval) or
data/real (--split train), with the label file and manifest updated.
Running a photo again replaces its earlier crops.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageOps

from app_ocr import AppOcr, crop_quad, write_image
from common import (
    Layout,
    append_manifest,
    check_no_eval_in_training,
    edit_distance,
    loosen,
    read_labels,
    read_manifest,
    root_dir,
    write_labels,
    write_manifest,
)

HEADER = "tactilelensworksheet"


def load_photo(path: Path) -> np.ndarray:
    """Upright BGR image (EXIF rotation applied, like the app's upright copy)."""

    with Image.open(path) as image:
        upright = ImageOps.exif_transpose(image).convert("RGB")
    return cv2.cvtColor(np.asarray(upright), cv2.COLOR_RGB2BGR)


def group_rows(boxes) -> list[list]:
    """Boxes whose vertical extents overlap by half belong to one row."""

    def span(box):
        ys = [p[1] for p in box]
        return min(ys), max(ys)

    rows: list[list] = []
    for box in sorted(boxes, key=lambda b: span(b)[0]):
        top, bottom = span(box)
        for row in rows:
            r_top = min(span(b)[0] for b in row)
            r_bottom = max(span(b)[1] for b in row)
            overlap = min(bottom, r_bottom) - max(top, r_top)
            if overlap > 0.5 * min(bottom - top, r_bottom - r_top):
                row.append(box)
                break
        else:
            rows.append([box])
    for row in rows:
        row.sort(key=lambda b: min(p[0] for p in b))
    return rows


def row_crop(image: np.ndarray, row: list) -> np.ndarray:
    if len(row) == 1:
        return crop_quad(image, row[0])  # exactly the app's crop
    points = [p for box in row for p in box]
    rect = cv2.minAreaRect(np.array(points, dtype=np.float32))
    return crop_quad(image, [tuple(p) for p in cv2.boxPoints(rect)])


def similarity(a: str, b: str) -> float:
    x, y = loosen(a), loosen(b)
    if not x and not y:
        return 1.0
    return 1.0 - edit_distance(x, y) / max(len(x), len(y), 1)


def align(readings: list[str], labels: list[str]) -> list[tuple[int, int]]:
    """Order-preserving best alignment of rows to known lines (DP)."""

    n, m = len(readings), len(labels)
    score = np.zeros((n + 1, m + 1))
    move = np.zeros((n + 1, m + 1), dtype=np.int8)
    for i in range(1, n + 1):
        move[i, 0] = 1
    for j in range(1, m + 1):
        move[0, j] = 2
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            options = (
                score[i - 1, j - 1] + similarity(readings[i - 1], labels[j - 1]),
                score[i - 1, j],
                score[i, j - 1],
            )
            best = int(np.argmax(options))
            score[i, j] = options[best]
            move[i, j] = best
    pairs, i, j = [], n, m
    while i > 0 or j > 0:
        if i > 0 and j > 0 and move[i, j] == 0:
            pairs.append((i - 1, j - 1))
            i, j = i - 1, j - 1
        elif i > 0 and (j == 0 or move[i, j] == 1):
            i -= 1
        else:
            j -= 1
    return pairs[::-1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("photos", nargs="+")
    parser.add_argument("--sheet", required=True, help="sheet id, e.g. W001")
    parser.add_argument("--root")
    parser.add_argument("--min-similarity", type=float, default=0.75)
    parser.add_argument("--min-margin", type=float, default=0.15, help="best minus second-best similarity")
    parser.add_argument("--val", action="store_true",
                        help="training sheets only: put the crops in data/real/val.txt (real-val), used to pick "
                             "checkpoints during training, instead of train.txt")
    args = parser.parse_args()

    layout = Layout(root_dir(args.root))
    layout.make_dirs()
    sheet = json.loads((layout.worksheets / f"{args.sheet}.json").read_text(encoding="utf-8"))
    known = sheet["lines"]
    labels = [line["label"] for line in known]
    if sheet["split"] == "eval":
        if args.val:
            raise SystemExit(f"{args.sheet} is an eval sheet; --val is only for training sheets.")
        set_name = "real-eval"
    else:
        set_name = "real-val" if args.val else "real-train"
    out_dir = layout.set_dir(set_name)
    review_dir = layout.review / args.sheet
    review_dir.mkdir(parents=True, exist_ok=True)
    ocr = AppOcr()

    for photo_path in map(Path, args.photos):
        photo_id = f"{args.sheet}_{photo_path.stem}"
        image = load_photo(photo_path)
        rows = group_rows(ocr.detect(image))
        crops = [row_crop(image, row) for row in rows]
        readings = [ocr.recognize_line(c)[0] for c in crops]

        keep = [k for k, text in enumerate(readings) if HEADER not in loosen(text).lower()]
        pairs = align([readings[k] for k in keep], labels)

        accepted, review = [], []
        paired_rows = set()
        for r, j in pairs:
            k = keep[r]
            paired_rows.add(k)
            best = similarity(readings[k], labels[j])
            others = [similarity(readings[k], lab) for t, lab in enumerate(labels) if t != j and lab != labels[j]]
            margin = best - max(others, default=0.0)
            if best >= args.min_similarity and margin >= args.min_margin:
                accepted.append((k, j, best))
            else:
                review.append((k, j, best, margin))
        for k in keep:
            if k not in paired_rows:
                review.append((k, None, 0.0, 0.0))

        # Replace this photo's earlier crops, if any. real-train and real-val
        # share the image folder, so a photo moved from one to the other is
        # also removed from the other list.
        prefix = f"images/{photo_id}_"
        for other in {"real-train", "real-val"} - {set_name}:
            write_labels(layout.label_file(other),
                         [(i, t) for i, t in read_labels(layout.label_file(other)) if not i.startswith(prefix)])
            write_manifest(layout.manifest(other),
                           [m for m in read_manifest(layout.manifest(other)) if not m["path"].startswith(prefix)])
        rows_kept = [(img, text) for img, text in read_labels(layout.label_file(set_name)) if not img.startswith(prefix)]
        manifest_kept = [m for m in read_manifest(layout.manifest(set_name)) if not m["path"].startswith(prefix)]
        for old in (out_dir / "images").glob(f"{photo_id}_*"):
            old.unlink()

        new_rows, new_manifest = [], []
        for k, j, best in accepted:
            name = f"{photo_id}_{known[j]['index']:02d}.png"
            write_image(out_dir / "images" / name, crops[k])
            new_rows.append((f"images/{name}", labels[j]))
            new_manifest.append({
                "id": name[:-4], "path": f"images/{name}", "label": labels[j], "source": "real",
                "set": set_name, "sheet": args.sheet, "photo": photo_path.name,
                "topic": known[j]["topic"], "subcase": known[j]["subcase"], "fixed_case": known[j]["fixed_case"],
                "font": known[j]["font"], "style": known[j]["style"], "reading": readings[k],
                "similarity": round(best, 3), "boxes": [[list(map(float, p)) for p in b] for b in rows[k]],
            })
        write_labels(layout.label_file(set_name), rows_kept + new_rows)
        write_manifest(layout.manifest(set_name), manifest_kept + new_manifest)

        with open(review_dir / "review.tsv", "a", encoding="utf-8", newline="\n") as handle:
            for k, j, best, margin in review:
                name = f"{photo_id}_row{k:02d}.png"
                write_image(review_dir / name, crops[k])
                guess = labels[j] if j is not None else ""
                handle.write(f"{name}\t{readings[k]}\t{guess}\t{best:.2f}\t{margin:.2f}\n")

        print(f"{photo_path.name}: {len(rows)} rows, {len(accepted)} labelled -> {set_name}, {len(review)} to review")

    check_no_eval_in_training(layout)
    append_manifest(layout.root / "manifests" / "pairing_runs.jsonl",
                    [{"sheet": args.sheet, "photos": [Path(p).name for p in args.photos],
                      "min_similarity": args.min_similarity, "min_margin": args.min_margin}])


if __name__ == "__main__":
    main()
