"""A tiny made-up dataset for dry runs and tests (generated images only).

Example (from tools/training_vl):
  python make_fake_dataset.py --out C:\\temp\\vl_fake            # 12 images + labels.csv
  python make_fake_dataset.py --out C:\\temp\\vl_fake_leak --leak  # + an eval image copied into train

Images are drawn with DejaVu Sans from the training data root (or a
fallback font) and named topic_source_kind_number.png in topic folders;
labels.csv has filename,task,target,split.
"""

from __future__ import annotations

import argparse
import csv
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FONT = Path(r"C:\Projects\Capstone\tactilelens-training\fonts\dejavu\DejaVuSans.ttf")

# (filename, task, drawn text or table rows, target, split)
ITEMS = [
    ("exponents_ss_S_001.png", "formula", "x² + 3x − 5", r"x^{2}+3x-5", "train"),
    ("exponents_ss_S_002.png", "formula", "a²b³ = c²", r"a^{2}b^{3}=c^{2}", "train"),
    ("exponents_cap_S_003.png", "formula", "10⁻³", r"10^{-3}", "eval"),
    ("radicals_ss_S_001.png", "formula", "√(x + 9) = 5", r"\sqrt{x+9}=5", "train"),
    ("radicals_cap_S_002.png", "formula", "∛27 = 3", r"\sqrt[3]{27}=3", "eval"),
    ("fractions_ss_M_001.png", "formula", "(x + 1)/2 = 3   x = 5", r"\frac{x+1}{2}=3 \quad x=5", "val"),
    ("tables_ss_M_001.png", "table", [["x", "y"], ["1", "2"], ["3", "4"]], "<fcel>x<fcel>y<nl><fcel>1<fcel>2<nl><fcel>3<fcel>4<nl>", "train"),
    ("tables_cap_M_002.png", "table", [["n", "n²"], ["2", "4"]], "<fcel>n<fcel>n²<nl><fcel>2<fcel>4<nl>", "eval"),
    ("wordproblems_ss_T_001.png", "text", "Solve for x: 2x + 5 = 11", "Solve for x: 2x + 5 = 11", "train"),
    ("wordproblems_cap_T_002.png", "text", "Find the value of y.", "Find the value of y.", "val"),
    ("worksheets_ss_W_001.png", "text", "Name the exponent in 5³.", "Name the exponent in 5³.", "train"),
    ("negative_exponents_ss_S_001.png", "formula", "y⁻²", r"y^{-2}", "eval"),
]


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT), size) if FONT.exists() else ImageFont.load_default(size)


def draw_text(text: str) -> Image.Image:
    f = font(40)
    width = int(f.getlength(text)) + 60
    image = Image.new("RGB", (width, 90), (255, 255, 255))
    ImageDraw.Draw(image).text((30, 20), text, font=f, fill=(0, 0, 0))
    return image


def draw_table(rows: list[list[str]]) -> Image.Image:
    f = font(32)
    cell_w, cell_h = 120, 60
    image = Image.new("RGB", (cell_w * len(rows[0]) + 40, cell_h * len(rows) + 40), (255, 255, 255))
    draw = ImageDraw.Draw(image)
    for r, row in enumerate(rows):
        for c, text in enumerate(row):
            x, y = 20 + c * cell_w, 20 + r * cell_h
            draw.rectangle([x, y, x + cell_w, y + cell_h], outline=(0, 0, 0), width=2)
            draw.text((x + 20, y + 12), text, font=f, fill=(0, 0, 0))
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", required=True)
    parser.add_argument("--leak", action="store_true", help="also copy an eval image into train under another name")
    args = parser.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    for filename, task, drawn, target, split in ITEMS:
        topic = filename.rsplit("_", 3)[0]
        image = draw_table(drawn) if task == "table" else draw_text(drawn)
        (out / topic).mkdir(exist_ok=True)
        image.save(out / topic / filename)
        rows.append({"filename": filename, "task": task, "target": target, "split": split})

    if args.leak:
        shutil.copy(out / "exponents" / "exponents_cap_S_003.png", out / "exponents" / "exponents_ss_S_099.png")
        rows.append({"filename": "exponents_ss_S_099.png", "task": "formula", "target": r"10^{-3}", "split": "train"})

    with open(out / "labels.csv", "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["filename", "task", "target", "split"])
        writer.writeheader()
        writer.writerows(rows)
    print(f"{len(rows)} images and labels.csv in {out}")


if __name__ == "__main__":
    main()
