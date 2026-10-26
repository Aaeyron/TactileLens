"""Printable A4 worksheets with known lines, for real photos.

Each sheet is one A4 page (PDF, 300 dpi) of generated lines in one
printed style, with a header naming the sheet. Its known lines are saved
next to it as <sheet>.json, which pair_photos.py uses to label the crops
cut from your photos. A sheet is for eval OR for training, never both.

Examples (from tools/training):
  python worksheets.py --split eval  --count 4 --start 1
  python worksheets.py --split train --count 8 --start 101

Sheet ids are W<number> (W001 ...). Eval and training sheets must use
different numbers; the script refuses to overwrite an existing sheet.
Seeds come from the sheet number, so a sheet can always be regenerated.
"""

from __future__ import annotations

import argparse
import csv
import json
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from common import Layout, load_character_list, root_dir, unsupported_characters
from render import FONT_FILES, draw_segments, fonts_for
from textgen import FIXED_CASES, fixed_line, make_line

HERE = Path(__file__).resolve().parent
DPI = 300
A4 = (2480, 3508)  # pixels at 300 dpi
MARGIN = 200
LINES_PER_SHEET = 16

# A few printed styles: (font, size in points, exponent style). One per
# sheet, like a real worksheet.
STYLES = [
    ("LiberationSerif", 14, "typeset"),
    ("LiberationSans", 13, "typeset"),
    ("TeXGyreTermes", 15, "typeset"),
    ("LatinModern", 15, "typeset"),
    ("DejaVuSans", 12, "glyph"),
    ("DejaVuSerif", 13, "typeset"),
    ("LiberationSerif-Italic", 16, "typeset"),
    ("STIXGeneral", 14, "typeset"),
]


def read_topics(path: Path) -> list[dict]:
    with open(path, encoding="utf-8", newline="") as handle:
        return [row for row in csv.DictReader(handle) if row.get("topic")]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--split", choices=["eval", "train"], required=True)
    parser.add_argument("--count", type=int, default=4)
    parser.add_argument("--start", type=int, required=True, help="first sheet number")
    parser.add_argument("--root")
    parser.add_argument("--topics", default=str(HERE / "topics.csv"))
    args = parser.parse_args()

    layout = Layout(root_dir(args.root))
    layout.make_dirs()
    characters = load_character_list()
    topics = read_topics(Path(args.topics))
    header_font = ImageFont.truetype(str(layout.fonts / FONT_FILES["DejaVuSans"][0]), 40)

    for number in range(args.start, args.start + args.count):
        sheet = f"W{number:03d}"
        pdf_path = layout.worksheets / f"{sheet}.pdf"
        if pdf_path.exists() or (layout.worksheets / f"{sheet}.json").exists():
            raise SystemExit(f"{sheet} already exists; use another --start")

        rng = random.Random(10_000 + number)
        font_name, points, style = STYLES[number % len(STYLES)]
        size_px = round(points * DPI / 72)

        # The seven fixed cases appear on every eval sheet, never on a
        # training sheet, so training photos never show the exact lines the
        # eval measures. The rest come from the topic templates.
        planned = [fixed_line(t, s, text) for t, s, text in FIXED_CASES] if args.split == "eval" else []
        # Topic first, then sub-case, so topics with few sub-cases
        # (fractions, roots) still get their share of lines.
        by_topic: dict[str, list[dict]] = {}
        for row in topics:
            by_topic.setdefault(row["topic"], []).append(row)
        while len(planned) < LINES_PER_SHEET:
            row = rng.choice(by_topic[rng.choice(sorted(by_topic))])
            planned.append(make_line(row["topic"], row["subcase"], row["example"], rng))
        rng.shuffle(planned)

        page = Image.new("RGB", A4, (255, 255, 255))
        draw = ImageDraw.Draw(page)
        draw.text((MARGIN, MARGIN - 80), f"TactileLens worksheet {sheet} ({args.split})", font=header_font, fill=(0, 0, 0))

        y = MARGIN + 60
        step = int(size_px * 2.6)
        lines = []
        for index, line in enumerate(planned):
            label = line.label
            bad = unsupported_characters(label, characters)
            if bad:
                raise SystemExit(f"{label!r} has characters the recognizer lacks: {bad}")
            line_style = style
            font_path = layout.fonts / FONT_FILES[font_name][0]
            needed = label if line_style == "glyph" else "".join(t for t, _ in line.segments)
            if not any(f.name == font_name for f in fonts_for(needed, layout.fonts)):
                # This font lacks a glyph the line needs: fall back to DejaVu.
                font_name_used = "DejaVuSerif" if "Serif" in font_name or "Termes" in font_name else "DejaVuSans"
                font_path = layout.fonts / FONT_FILES[font_name_used][0]
            else:
                font_name_used = font_name
            text_img, info = draw_segments(line.segments, font_path, size_px, line_style, rng)
            page.paste(text_img, (MARGIN, y))
            lines.append({
                "index": index,
                "label": label,
                "topic": line.topic,
                "subcase": line.subcase,
                "fixed_case": line.fixed,
                "font": font_name_used,
                "size_pt": points,
                "style": line_style,
                "top_px": y,
                "height_px": text_img.height,
            })
            y += step

        page.save(pdf_path, "PDF", resolution=DPI)
        page.save(layout.worksheets / f"{sheet}.png")
        (layout.worksheets / f"{sheet}.json").write_text(
            json.dumps({"sheet": sheet, "split": args.split, "seed": 10_000 + number, "font": font_name,
                        "size_pt": points, "style": style, "lines": lines}, ensure_ascii=False, indent=1),
            encoding="utf-8",
        )
        print(f"{sheet} ({args.split}): {pdf_path}  [{font_name} {points} pt, {style}]")


if __name__ == "__main__":
    main()
