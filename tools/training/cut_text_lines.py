"""Cut text lines from our own T, W and M images with the app's text detector.

From tools/training, with C:\\Projects\\Capstone\\paddle_onnx_env:
  python cut_text_lines.py --working <root>\\datasets\\own\\working\\20261118_all [--workers 4 --threads 3]
  python cut_text_lines.py --working <...> --report

Per image: the app's PP-OCRv6 tiny detector and crop (app_ocr.py, the
verified port of the app's ppocr-sdk), then the app's original recognizer on
every line (the "offline reading", kept for agreement and ranking later).

Formula regions: like OfflineDocumentPipeline.kt, a line is skipped when at
least half of its area lies inside a display formula or a standalone inline
formula (boxes from tools/dataset/crop_formulas.py, crops_mtw/detections.jsonl;
the app also grows those boxes over nearby math pieces, which is not
repeated here). Lines that only touch an inline formula inside text are kept
and marked (the app reads them with the text model too).

Dropped: lines under 10 px high or 16 px wide, and M lines without a word
(3 or more letters in the offline reading): M images are mostly formulas.

Writes <working>/text_lines_mtw/: images/<image>__l<nnn>.png, lines.jsonl
(one row per image, appended as it goes; a stopped run continues), and with
--report lines.csv and report.md / report.json. Stops cleanly when the disk
has less than --min-free-gb free.
"""

from __future__ import annotations

import argparse
import csv
import json
import multiprocessing as mp
import re
import shutil
import time
from collections import Counter
from pathlib import Path

import numpy as np

KINDS = ("T", "W", "M")
LINE_IN_REGION = 0.5  # OfflineDocumentPipeline.kt
MIN_HEIGHT, MIN_WIDTH = 10, 16
WORD = re.compile(r"[A-Za-z]{3,}")
NAME = re.compile(r"^(?P<topic>.+?)_(?P<source>cap|ss)_(?P<kind>[A-Z])_\d+\.\w+$")

_ocr = None


def axis_box(quad) -> list[float]:
    xs, ys = [p[0] for p in quad], [p[1] for p in quad]
    return [min(xs), min(ys), max(xs), max(ys)]


def area(b) -> float:
    return max(0.0, b[2] - b[0]) * max(0.0, b[3] - b[1])


def overlap(a, b) -> float:
    return area([max(a[0], b[0]), max(a[1], b[1]), min(a[2], b[2]), min(a[3], b[3])])


def formula_share(line_box, formula_boxes) -> float:
    """The largest share of the line's area inside one formula box."""
    line_area = max(area(line_box), 1.0)
    return max((overlap(line_box, f) / line_area for f in formula_boxes), default=0.0)


def keep_line(kind: str, height: float, width: float, reading: str, share: float) -> str | None:
    """None to keep, else the reason for dropping."""
    if share >= LINE_IN_REGION:
        return "inside a formula"
    if height < MIN_HEIGHT or width < MIN_WIDTH:
        return "tiny"
    if kind == "M" and not WORD.search(reading):
        return "M line without a word"
    return None


def formula_boxes(detections: Path) -> tuple[dict[str, list], dict[str, list]]:
    """Per source image: (display + standalone inline boxes, embedded inline boxes)."""
    skip, inline = {}, {}
    if not detections.exists():
        return skip, inline
    for line in detections.read_text(encoding="utf-8").splitlines():
        try:
            row = json.loads(line)
        except ValueError:
            continue
        crops = row.get("crops", [])
        skip[row["source"]] = [c["box"] for c in crops if c["category"] == "formula_display" or c.get("standalone")]
        inline[row["source"]] = [c["box"] for c in crops if c["category"] == "formula_inline" and not c.get("standalone")]
    return skip, inline


def start_worker(threads: int) -> None:
    global _ocr
    from app_ocr import AppOcr
    _ocr = AppOcr(threads=threads)


def process(job: tuple) -> dict:
    from app_ocr import crop_quad, read_image, write_image
    name, path, out_dir, skip_boxes, inline_boxes = job
    started = time.perf_counter()
    match = NAME.match(name)
    kind = match["kind"] if match else "?"
    try:
        bgr = read_image(Path(path))
        lines, dropped = [], Counter()
        for n, quad in enumerate(_ocr.detect(bgr), 1):
            box = axis_box(quad)
            share = formula_share(box, skip_boxes)
            if share >= LINE_IN_REGION:
                dropped["inside a formula"] += 1
                continue
            crop = crop_quad(bgr, quad)
            if crop.size == 0:
                dropped["empty crop"] += 1
                continue
            reading, confidence = _ocr.recognize_line(crop)
            reason = keep_line(kind, crop.shape[0], crop.shape[1], reading, share)
            if reason:
                dropped[reason] += 1
                continue
            line_id = f"{Path(name).stem}__l{n:03d}.png"
            write_image(Path(out_dir) / line_id, crop)
            lines.append({"line": line_id, "box": [round(v, 1) for v in box],
                          "quad": [[round(x, 1), round(y, 1)] for x, y in quad],
                          "height": int(crop.shape[0]), "width": int(crop.shape[1]),
                          "offline": reading, "confidence": round(confidence, 4),
                          "touches_inline_formula": formula_share(box, inline_boxes) > 0})
        return {"source": name, "height": int(bgr.shape[0]), "width": int(bgr.shape[1]),
                "lines": lines, "dropped": dict(dropped), "seconds": round(time.perf_counter() - started, 3)}
    except Exception as error:  # noqa: BLE001  (recorded, retried on the next run)
        return {"source": name, "lines": [], "dropped": {}, "error": f"{type(error).__name__}: {error}"}


def read_rows(path: Path) -> dict[str, dict]:
    rows = {}
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            try:
                row = json.loads(line)
            except ValueError:
                continue  # a line cut off by an interruption
            rows[row["source"]] = row
    return rows


def run(args) -> None:
    working = Path(args.working)
    out = working / "text_lines_mtw"
    images_out = out / "images"
    images_out.mkdir(parents=True, exist_ok=True)
    record = out / "lines.jsonl"
    done = {s for s, r in read_rows(record).items() if "error" not in r}
    skip, inline = formula_boxes(working / "crops_mtw" / "detections.jsonl")
    names = sorted(p.name for p in (working / "images").iterdir()
                   if (m := NAME.match(p.name)) and m["kind"] in KINDS)
    if args.limit:
        names = names[:: max(1, len(names) // args.limit)][: args.limit]
    first = set(Path(args.first).read_text(encoding="utf-8").split()) if args.first else set()
    todo = sorted((n for n in names if n not in done), key=lambda n: n not in first)  # stable
    print(f"{len(names)} images, {len(todo)} to do", flush=True)
    jobs = [(n, str(working / "images" / n), str(images_out), skip.get(n, []), inline.get(n, [])) for n in todo]
    started = time.time()
    with mp.Pool(args.workers, initializer=start_worker, initargs=(args.threads,)) as pool, \
            record.open("a", encoding="utf-8", newline="\n") as handle:
        for n, row in enumerate(pool.imap_unordered(process, jobs), 1):
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
            handle.flush()
            if n % 50 == 0:
                rate = (time.time() - started) / n
                print(f"{n}/{len(jobs)}  {rate:.2f} s per image  about {rate * (len(jobs) - n) / 60:.0f} min left", flush=True)
            if shutil.disk_usage(out).free < args.min_free_gb * 1024 ** 3:
                print(f"stopping: less than {args.min_free_gb:g} GB free", flush=True)
                pool.terminate()
                break


def report(args) -> None:
    working = Path(args.working)
    out = working / "text_lines_mtw"
    rows = read_rows(out / "lines.jsonl")
    lines, dropped, per = [], Counter(), Counter()
    no_line = Counter()
    errors = [r["source"] for r in rows.values() if "error" in r]
    for source, row in sorted(rows.items()):
        m = NAME.match(source)
        dropped.update(row.get("dropped", {}))
        if not row.get("lines"):
            no_line[f"{m['kind']}/{m['source']}"] += 1
        for line in row.get("lines", []):
            lines.append({"line": line["line"], "source_image": source, "topic": m["topic"], "source": m["source"],
                          "kind": m["kind"], "height": line["height"], "width": line["width"],
                          "offline": line["offline"], "confidence": line["confidence"],
                          "touches_inline_formula": line["touches_inline_formula"],
                          "box": " ".join(str(v) for v in line["box"])})
    with (out / "lines.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(lines[0]) if lines else ["line"])
        writer.writeheader()
        writer.writerows(lines)
    counts = {
        "images": len(rows), "errors": len(errors), "lines": len(lines),
        "by_kind": Counter(r["kind"] for r in lines), "by_source": Counter(r["source"] for r in lines),
        "by_topic": Counter(r["topic"] for r in lines),
        "by_kind_and_source": Counter(f"{r['kind']}/{r['source']}" for r in lines),
        "dropped": dropped, "images_without_a_line": no_line,
        "touching_an_inline_formula": sum(r["touches_inline_formula"] for r in lines),
        "seconds_per_image_median": float(np.median([r["seconds"] for r in rows.values() if "seconds" in r] or [0])),
    }
    (out / "report.json").write_text(json.dumps(counts, indent=1, sort_keys=True), encoding="utf-8")
    print(json.dumps(counts, indent=1, sort_keys=True))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", required=True)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--threads", type=int, default=3)
    parser.add_argument("--limit", type=int, help="only this many images, spread over the list (timing)")
    parser.add_argument("--first", help="file with image names (one per line) to cut before the others")
    parser.add_argument("--min-free-gb", type=float, default=3)
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args()
    report(args) if args.report else run(args)


if __name__ == "__main__":
    main()
