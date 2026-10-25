"""Check that app_ocr.py reads a page exactly like the phone does.

How to get the phone's side:
  1. Copy a page image (PNG, so no camera rotation) to the phone, for
     example <root>/worksheets/W001.png.
  2. In TactileLens choose On-device, pick that file from the gallery and
     scan it WITHOUT drawing a selection box (the app then scans the file
     exactly as it is).
  3. On the PC:  adb logcat -d -s TactileLensPipeline > app_log.txt
Then (from tools/training):
  python verify_against_app.py <the same PNG> app_log.txt

The app logs every OCR line as  "text" [left,top,right,bottom]  (the
bounds of the detector's box). This script runs the ported detector and
recognizer on the same file, matches each app line to the port's line
with the most overlap, and compares text and box. The last scan in the
log is used.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from app_ocr import AppOcr, read_image

LINE = re.compile(r'"(.*?)" \[(-?\d+),(-?\d+),(-?\d+),(-?\d+)\]')


def app_lines(log_path: Path) -> list[tuple[str, tuple[int, int, int, int]]]:
    text = log_path.read_text(encoding="utf-8", errors="replace")
    entries = [line for line in text.splitlines() if "OCR lines:" in line]
    if not entries:
        raise SystemExit("No 'OCR lines:' entry in the log (filter: -s TactileLensPipeline).")
    body = entries[-1].split("OCR lines:", 1)[1]
    return [(m.group(1), tuple(int(m.group(i)) for i in range(2, 6))) for m in LINE.finditer(body)]


def bounds(box) -> tuple[int, int, int, int]:
    xs, ys = [p[0] for p in box], [p[1] for p in box]
    return int(min(xs)), int(min(ys)), int(max(xs)), int(max(ys))


def iou(a, b) -> float:
    ix = max(0, min(a[2], b[2]) - max(a[0], b[0]))
    iy = max(0, min(a[3], b[3]) - max(a[1], b[1]))
    inter = ix * iy
    union = (a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - inter
    return inter / union if union else 0.0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("image")
    parser.add_argument("log")
    args = parser.parse_args()

    phone = app_lines(Path(args.log))
    port = [(r.text.strip(), bounds(r.box)) for r in AppOcr().read_page(read_image(Path(args.image)))]

    same_text = same_box = 0
    print(f"Phone lines: {len(phone)}   Port lines: {len(port)}\n")
    print("| # | Phone text | Port text | Same text | Box difference (px) |")
    print("|---|---|---|---|---|")
    for index, (text, box) in enumerate(phone, 1):
        best = max(port, key=lambda p: iou(box, p[1]), default=None)
        if best is None or iou(box, best[1]) < 0.3:
            print(f"| {index} | {text} | (no matching box) | no | - |")
            continue
        difference = max(abs(a - b) for a, b in zip(box, best[1]))
        same_text += text == best[0]
        same_box += difference <= 2
        print(f"| {index} | {text} | {best[0]} | {'yes' if text == best[0] else 'NO'} | {difference} |")

    print(f"\nSame text: {same_text}/{len(phone)}; boxes within 2 px: {same_box}/{len(phone)}")
    verdict = same_text == len(phone) and len(phone) == len(port) and len(phone) >= 3
    print("VERIFIED: the port matches the app on this page." if verdict else "NOT VERIFIED: see the differences above.")


if __name__ == "__main__":
    main()
