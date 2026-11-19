"""Cut every formula out of the M, T and W images with the app's layout model.

PP-DocLayoutV3 (the app's ONNX file) with the steps of the app's
PaddleOnnxLayoutDetector.kt and OfflineDocumentPipeline.kt: power-of-two
reduction while both sides stay at least 800, bilinear resize to 800 x 800, RGB
in [0, 1], sigmoid scores at threshold 0.5, regions overlapping a better one by
IoU 0.8 removed, and the left edge of display formulas widened by 15% of the box
height (inline boxes are not widened: it pulls in the character before them).
The app also grows a box over nearby OCR pieces; OCR is not run here, so that
step is missing.

Dropped: tiny boxes, boxes cut off by the image border (ink on the border), and
inline boxes inside a kept formula box. Images in the eval or validation split,
or with the bytes of one, are refused. After the run, --report checks every crop
and source image against the eval and validation images (near-duplicate hash).

  python crop_formulas.py --working <working folder> [--limit 50]
  python crop_formulas.py --working <working folder> --report

Reads items.csv and split.csv. Writes <working>/crops_mtw: images/,
detections.jsonl (appended per image, so a stopped run continues), and with
--report crops.csv, report.json, report.md. Python: paddle_onnx_env.
"""

from __future__ import annotations

import argparse
import csv
import json
import multiprocessing as mp
import shutil
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageOps

import dataset_common as dc

REPO = Path(__file__).resolve().parents[2]
APP_MODEL = REPO / "frontend/android/app/src/main/assets/paddle_onnx/PP-DocLayoutV3/pp_doclayoutv3_nomask.onnx"

INPUT_SIZE = 800
THRESHOLD = 0.5
NUM_QUERIES = 300
DUPLICATE_IOU = 0.8
LINE_IN_REGION = 0.5
LEFT_WIDEN = 0.15
DISPLAY_ID, INLINE_ID = 5, 15
NON_TEXT_CONTAINERS = {DISPLAY_ID, INLINE_ID}
CATEGORY = {DISPLAY_ID: "formula_display", INLINE_ID: "formula_inline"}

MIN_WIDTH = 24
MIN_HEIGHT = 12
NESTED_SHARE = 0.8
BORDER = 2
INK_BELOW_PAPER = 60
MAX_SAVED_SIDE = 1280

_session = None


def sample_size(width: int, height: int, size: int = INPUT_SIZE) -> int:
    """Android's inSampleSize as the app computes it."""

    sample = 1
    while width // (sample * 2) >= size and height // (sample * 2) >= size:
        sample *= 2
    return sample


def prepare(rgb: np.ndarray) -> np.ndarray:
    height, width = rgb.shape[:2]
    sample = sample_size(width, height)
    if sample > 1:
        rgb = cv2.resize(rgb, (width // sample, height // sample), interpolation=cv2.INTER_AREA)
    rgb = cv2.resize(rgb, (INPUT_SIZE, INPUT_SIZE), interpolation=cv2.INTER_LINEAR)
    return rgb.astype(np.float32).transpose(2, 0, 1)[None] / 255.0


def regions_from(logits: np.ndarray, boxes: np.ndarray, width: int, height: int,
                 threshold: float = THRESHOLD) -> list[dict]:
    """Regions at or above the threshold, best score first."""

    scores = 1.0 / (1.0 + np.exp(-logits.astype(np.float64)))
    picked = np.argwhere(scores >= threshold)
    order = sorted(picked.tolist(), key=lambda p: -scores[p[0], p[1]])[:NUM_QUERIES]
    out = []
    for query, label in order:
        cx, cy, w, h = boxes[query].tolist()
        out.append({"label_id": label, "score": float(scores[query, label]), "box": [
            min(max((cx - w / 2) * width, 0.0), width), min(max((cy - h / 2) * height, 0.0), height),
            min(max((cx + w / 2) * width, 0.0), width), min(max((cy + h / 2) * height, 0.0), height)]})
    return out


def area(b: list[float]) -> float:
    return max(b[2] - b[0], 0.0) * max(b[3] - b[1], 0.0)


def intersection(a: list[float], b: list[float]) -> float:
    return area([max(a[0], b[0]), max(a[1], b[1]), min(a[2], b[2]), min(a[3], b[3])])


def iou(a: list[float], b: list[float]) -> float:
    shared = intersection(a, b)
    union = area(a) + area(b) - shared
    return shared / union if union > 0 else 0.0


def remove_duplicates(regions: list[dict]) -> list[dict]:
    """The app's removeDuplicates: keep the better of two overlapping regions."""

    kept: list[dict] = []
    for region in sorted(regions, key=lambda r: -r["score"]):
        if not any(iou(other["box"], region["box"]) >= DUPLICATE_IOU for other in kept):
            kept.append(region)
    return kept


def is_cut_off(gray: np.ndarray, box: list[int]) -> bool:
    """True when the box reaches the image border and there is ink on that border."""

    height, width = gray.shape
    left, top, right, bottom = box
    inside = gray[top:bottom, left:right]
    if inside.size == 0:
        return True
    ink = float(np.median(inside)) - INK_BELOW_PAPER
    strips = []
    if left <= BORDER:
        strips.append(gray[top:bottom, 0:BORDER])
    if right >= width - BORDER:
        strips.append(gray[top:bottom, width - BORDER:width])
    if top <= BORDER:
        strips.append(gray[0:BORDER, left:right])
    if bottom >= height - BORDER:
        strips.append(gray[height - BORDER:height, left:right])
    return any(int((strip < ink).sum()) >= 2 for strip in strips)


def select_formulas(regions: list[dict], gray: np.ndarray) -> tuple[list[dict], Counter]:
    """The formula crops of one image, and how many boxes each rule dropped."""

    height, width = gray.shape
    dropped: Counter = Counter()
    unique = remove_duplicates(regions)
    formula_ids = set(CATEGORY)
    dropped["duplicate"] = sum(r["label_id"] in formula_ids for r in regions) - \
        sum(r["label_id"] in formula_ids for r in unique)
    containers = [r for r in unique if r["label_id"] not in NON_TEXT_CONTAINERS]
    formulas = [r for r in unique if r["label_id"] in formula_ids]
    displays = [r for r in formulas if r["label_id"] == DISPLAY_ID]
    crops = []
    for r in formulas:
        box = r["box"]
        if r["label_id"] == INLINE_ID and any(
                intersection(d["box"], box) / max(area(box), 1.0) >= NESTED_SHARE for d in displays):
            dropped["inside a display formula"] += 1
            continue
        widen = (box[3] - box[1]) * LEFT_WIDEN if r["label_id"] == DISPLAY_ID else 0.0
        cut = [max(int(box[0] - widen), 0), max(int(box[1]), 0),
               min(int(np.ceil(box[2])), width), min(int(np.ceil(box[3])), height)]
        if cut[2] - cut[0] < MIN_WIDTH or cut[3] - cut[1] < MIN_HEIGHT:
            dropped["tiny"] += 1
            continue
        if is_cut_off(gray, cut):
            dropped["cut off by the image border"] += 1
            continue
        standalone = not any(
            intersection(c["box"], box) / max(area(box), 1.0) >= LINE_IN_REGION for c in containers)
        crops.append({"category": CATEGORY[r["label_id"]], "score": round(r["score"], 4),
                      "box": [round(v, 1) for v in box], "crop_box": cut, "standalone": standalone})
    crops.sort(key=lambda c: (c["crop_box"][1], c["crop_box"][0]))
    return crops, dropped


def start_worker(model: str, threads: int) -> None:
    global _session
    import onnxruntime as ort

    options = ort.SessionOptions()
    options.intra_op_num_threads = threads
    options.enable_cpu_mem_arena = False  # the arena costs about 1 GB per worker
    _session = ort.InferenceSession(model, options, providers=["CPUExecutionProvider"])


def process(job: tuple[str, str, str]) -> dict:
    name, image_path, out_dir = job
    started = time.perf_counter()
    try:
        with Image.open(image_path) as opened:
            turned = opened.getexif().get(274, 1) not in (0, 1)
            image = ImageOps.exif_transpose(opened).convert("RGB")
        rgb = np.asarray(image)
        height, width = rgb.shape[:2]
        input_name = _session.get_inputs()[0].name
        logits, boxes = _session.run(["logits", "pred_boxes"], {input_name: prepare(rgb)})
        regions = regions_from(logits[0], boxes[0], width, height)
        crops, dropped = select_formulas(regions, cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY))
        stem = Path(name).stem
        for n, crop in enumerate(crops, 1):
            crop["crop"] = f"{stem}__c{n:03d}.png"
            piece = image.crop(crop["crop_box"])
            if max(piece.size) > MAX_SAVED_SIDE:
                piece.thumbnail((MAX_SAVED_SIDE, MAX_SAVED_SIDE), Image.Resampling.LANCZOS)
            target = Path(out_dir) / crop["crop"]
            piece.save(target, optimize=False)
            crop["dhash"] = dc.dhash(target)
        return {"source": name, "width": width, "height": height, "exif_turned": turned,
                "regions": len(regions), "crops": crops, "dropped": dict(dropped),
                "seconds": round(time.perf_counter() - started, 3)}
    except Exception as error:  # noqa: BLE001  (recorded; the image is reported, not retried)
        return {"source": name, "crops": [], "dropped": {}, "error": f"{type(error).__name__}: {error}"}


def read_csv(path: Path) -> list[dict]:
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def held_names(working: Path) -> set[str]:
    return {r["filename"] for r in read_csv(working / "split.csv") if r["split"] in ("eval", "val")}


def read_detections(path: Path) -> list[dict]:
    if not path.exists():
        return []
    data = path.read_bytes()
    if data and not data.endswith(b"\n"):  # a line cut off by an interruption
        path.write_bytes(data[: data.rfind(b"\n") + 1])
    latest = {}  # a later row replaces an earlier one (an image retried after an error)
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            row = json.loads(line)
            latest[row["source"]] = row
    return list(latest.values())


def disk_is_low(folder: Path, minimum_gb: float) -> bool:
    return shutil.disk_usage(folder).free < minimum_gb * 1024 ** 3


def run(args) -> None:
    out = args.working / "crops_mtw"
    (out / "images").mkdir(parents=True, exist_ok=True)
    items = read_csv(args.working / "items.csv")
    held = held_names(args.working)
    held_sha = {r["sha256"] for r in items if r["filename"] in held}
    log = out / "detections.jsonl"
    done = {d["source"] for d in read_detections(log) if not d.get("error")}  # errors are tried again
    jobs, refused = [], 0
    for r in items:
        if r["kind"] not in ("M", "T", "W"):
            continue
        if r["filename"] in held or r["sha256"] in held_sha:
            refused += 1
        elif r["filename"] not in done:
            jobs.append((r["filename"], str(args.working / "images" / r["filename"]), str(out / "images")))
    if args.limit:
        jobs = jobs[:: max(len(jobs) // args.limit, 1)][: args.limit]
    print(f"{len(jobs)} images to read, {len(done)} done, {refused} refused as eval or validation", flush=True)
    started = time.perf_counter()
    context = mp.get_context("spawn")
    with context.Pool(args.workers, start_worker, (str(args.model), args.threads)) as pool, \
            log.open("a", encoding="utf-8", newline="\n") as handle:
        for n, row in enumerate(pool.imap_unordered(process, jobs), 1):
            handle.write(json.dumps(row) + "\n")
            handle.flush()
            if disk_is_low(out, args.min_free_gb):
                pool.terminate()
                raise SystemExit(f"stopped: less than {args.min_free_gb} GB free; run again to continue")
            if n % 100 == 0:
                rate = (time.perf_counter() - started) / n
                print(f"{n}/{len(jobs)}  {rate:.2f} s per image  about {(len(jobs) - n) * rate / 60:.0f} min left", flush=True)
    print("finished", flush=True)


def table(title: str, counts: Counter) -> list[str]:
    lines = [f"## {title}", "", "| Group | Crops |", "|---|---|"]
    lines += [f"| {key} | {value:,} |" for key, value in sorted(counts.items())]
    return lines + [""]


def report(args) -> None:
    out = args.working / "crops_mtw"
    items = {r["filename"]: r for r in read_csv(args.working / "items.csv")}
    held = held_names(args.working)
    held_hash = {n: dc.dhash(args.working / "images" / n) for n in sorted(held)}
    rows, dropped, errors, without = [], Counter(), [], Counter()
    near_crops = near_sources = 0
    detections = read_detections(out / "detections.jsonl")
    for d in detections:
        item = items[d["source"]]
        if d.get("error"):
            errors.append({"source": d["source"], "error": d["error"]})
            continue
        dropped.update(d["dropped"])
        if not d["crops"]:
            without[(item["kind"], item["source"])] += 1
        source_hash = dc.dhash(args.working / "images" / d["source"])
        near_sources += any(dc.is_near_duplicate(source_hash, h) for h in held_hash.values())
        for c in d["crops"]:
            near = [n for n, h in held_hash.items() if dc.is_near_duplicate(c["dhash"], h)]
            near_crops += bool(near)
            rows.append({"crop": c["crop"], "source_image": d["source"], "topic": item["topic"],
                         "source": item["source"], "kind": item["kind"], "category": c["category"],
                         "score": c["score"], "box": " ".join(map(str, c["box"])),
                         "crop_box": " ".join(map(str, c["crop_box"])), "standalone": c["standalone"],
                         "dhash": c["dhash"], "near_eval_or_val": " ".join(near)})
    with (out / "crops.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, list(rows[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    seconds = [d["seconds"] for d in detections if "seconds" in d]
    summary = {
        "images_read": len(detections), "images_with_errors": len(errors), "errors": errors[:20],
        "images_turned_by_exif": sum(bool(d.get("exif_turned")) for d in detections),
        "crops": len(rows), "dropped_boxes": dict(dropped),
        "images_without_a_crop": {f"{k}/{s}": v for (k, s), v in sorted(without.items())},
        "by_topic": dict(sorted(Counter(r["topic"] for r in rows).items())),
        "by_kind": dict(sorted(Counter(r["kind"] for r in rows).items())),
        "by_source": dict(sorted(Counter(r["source"] for r in rows).items())),
        "by_category": dict(sorted(Counter(r["category"] for r in rows).items())),
        "by_kind_and_source": {f"{k}/{s}": v for (k, s), v in sorted(Counter((r["kind"], r["source"]) for r in rows).items())},
        "held_out_images_checked": len(held_hash), "source_images_in_held_out": sum(d["source"] in held for d in detections),
        "source_images_near_held_out": int(near_sources), "crops_near_held_out": near_crops,
        "median_seconds_per_image": sorted(seconds)[len(seconds) // 2] if seconds else None,
    }
    dc.write_json(out / "report.json", summary)
    lines = ["# Formula crops from the M, T and W images", "",
             f"- Images read: {len(detections):,} ({len(errors)} with errors)",
             f"- Crops: {len(rows):,}", f"- Boxes dropped: {dict(dropped)}",
             f"- Images without a crop: {summary['images_without_a_crop']}",
             f"- Leak check against {len(held_hash)} eval and validation images: "
             f"{summary['source_images_in_held_out']} source images in them, "
             f"{near_sources} source images and {near_crops} crops near-duplicate", ""]
    for title, key in (("Per topic", "topic"), ("Per kind", "kind"), ("Per source", "source"), ("Per region type", "category")):
        lines += table(title, Counter(r[key] for r in rows))
    grid: dict = defaultdict(Counter)
    for r in rows:
        grid[r["topic"]][(r["kind"], r["source"])] += 1
    columns = sorted({key for c in grid.values() for key in c})
    lines += ["## Per topic, kind and source", "",
              "| Topic | " + " | ".join(f"{k} {s}" for k, s in columns) + " |", "|---|" + "---|" * len(columns)]
    lines += [f"| {t} | " + " | ".join(f"{grid[t][c]:,}" for c in columns) + " |" for t in sorted(grid)]
    (out / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps(summary, indent=1))


def main() -> None:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", required=True, type=Path)
    parser.add_argument("--model", type=Path, default=APP_MODEL)
    parser.add_argument("--workers", type=int, default=3)
    parser.add_argument("--threads", type=int, default=4)
    parser.add_argument("--min-free-gb", type=float, default=1.5, help="stop cleanly below this much free disk")
    parser.add_argument("--limit", type=int, help="read only this many images, spread over the list")
    parser.add_argument("--report", action="store_true", help="write crops.csv and the report from the saved detections")
    args = parser.parse_args()
    report(args) if args.report else run(args)


if __name__ == "__main__":
    main()
