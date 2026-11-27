"""Simple slide charts with Pillow only (no matplotlib in our environments).

line_chart: one or more series over steps (loss curve, validation history).
bar_chart:  grouped horizontal bars with the count written on each bar.
Both write a 1600 x 900 PNG with a white background.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 1600, 900
COLORS = ["#2563eb", "#ea580c", "#16a34a", "#9333ea", "#dc2626", "#0891b2"]
FONT_FILES = [r"C:\Windows\Fonts\segoeui.ttf", r"C:\Windows\Fonts\arial.ttf", "DejaVuSans.ttf"]


def font(size: int) -> ImageFont.ImageFont:
    for f in FONT_FILES:
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            continue
    return ImageFont.load_default()


def nice_ticks(lo: float, hi: float, n: int = 5) -> list[float]:
    if hi <= lo:
        hi = lo + 1
    raw = (hi - lo) / n
    mag = 10 ** math.floor(math.log10(raw))
    step = min((m * mag for m in (1, 2, 2.5, 5, 10) if m * mag >= raw), default=raw)
    start = math.floor(lo / step) * step
    ticks, t = [], start
    while t <= hi + step * 0.001:
        ticks.append(round(t, 10))
        t += step
    if ticks[-1] < hi:
        ticks.append(round(ticks[-1] + step, 10))
    return ticks


def fmt(v: float) -> str:
    return f"{v:.0f}" if abs(v) >= 100 or v == int(v) else f"{v:.3g}"


def line_chart(series: dict[str, list[tuple[float, float]]], title: str, xlabel: str, ylabel: str, path: Path,
               note: str = "", y_range: tuple[float, float] | None = None, markers: bool = False,
               point_labels: dict[str, list[str]] | None = None) -> None:
    """point_labels: series name -> one text per point, drawn above it (e.g. "45/104")."""

    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    left, right, top, bottom = 140, W - 60, 130, H - 170
    d.text((left, 30), title, fill="#111827", font=font(40))
    pts = [p for s in series.values() for p in s]
    xs, ys = [p[0] for p in pts] or [0, 1], [p[1] for p in pts] or [0, 1]
    x0, x1 = min(xs), max(xs) if max(xs) > min(xs) else min(xs) + 1
    y0, y1 = y_range or (min(0.0, min(ys)), max(ys) * 1.08 if max(ys) > 0 else 1)
    yt = nice_ticks(y0, y1)
    y0, y1 = yt[0], yt[-1]
    X = lambda x: left + (x - x0) / (x1 - x0) * (right - left)  # noqa: E731
    Y = lambda y: bottom - (y - y0) / (y1 - y0 or 1) * (bottom - top)  # noqa: E731
    for t in yt:
        d.line([(left, Y(t)), (right, Y(t))], fill="#e5e7eb", width=2)
        d.text((left - 15, Y(t)), fmt(t), fill="#374151", font=font(26), anchor="rm")
    for t in nice_ticks(x0, x1, 6):
        if x0 <= t <= x1:
            d.text((X(t), bottom + 15), fmt(t), fill="#374151", font=font(26), anchor="ma")
    d.line([(left, bottom), (right, bottom)], fill="#111827", width=3)
    d.line([(left, top), (left, bottom)], fill="#111827", width=3)
    d.text(((left + right) / 2, bottom + 60), xlabel, fill="#111827", font=font(30), anchor="ma")
    label_img = Image.new("RGBA", (500, 50), (255, 255, 255, 0))
    ImageDraw.Draw(label_img).text((250, 25), ylabel, fill="#111827", font=font(30), anchor="mm")
    img.paste(label_img.rotate(90, expand=True), (15, (top + bottom) // 2 - 250), label_img.rotate(90, expand=True))
    lx = right
    for i, (name, s) in enumerate(series.items()):
        c = COLORS[i % len(COLORS)]
        line = [(X(x), Y(y)) for x, y in s]
        if len(line) > 1:
            d.line(line, fill=c, width=4, joint="curve")
        if markers or len(line) == 1:
            for x, y in line:
                d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=c)
        labels = (point_labels or {}).get(name)
        if labels and len(labels) <= 25:
            for (x, y), text in zip(line, labels):
                d.text((x, y - 14), text, fill="#111827", font=font(20), anchor="md")
        lx -= d.textlength(name, font=font(28)) + 70
        d.rectangle([lx, 52, lx + 30, 70], fill=c)
        d.text((lx + 40, 61), name, fill="#111827", font=font(28), anchor="lm")
    if note:
        d.text((left, H - 30), note, fill="#6b7280", font=font(22), anchor="lm")
    img.save(path)


def bar_chart(rows: list[str], groups: dict[str, list[int]], title: str, path: Path, note: str = "") -> None:
    """rows: category labels; groups: series name -> one count per row."""

    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    d.text((60, 30), title, fill="#111827", font=font(40))
    left, right, top, bottom = 380, W - 140, 120, H - 80
    vmax = max((v for g in groups.values() for v in g), default=1) or 1
    band = (bottom - top) / max(len(rows), 1)
    bar = min(40, band * 0.8 / max(len(groups), 1))
    for r, label in enumerate(rows):
        yc = top + band * (r + 0.5)
        d.text((left - 20, yc), label, fill="#111827", font=font(28), anchor="rm")
        for g, (name, values) in enumerate(groups.items()):
            y = yc - bar * len(groups) / 2 + g * bar
            x = left + values[r] / vmax * (right - left)
            d.rectangle([left, y, max(x, left + 2), y + bar - 4], fill=COLORS[g % len(COLORS)])
            d.text((max(x, left + 2) + 10, y + (bar - 4) / 2), f"{values[r]:,}", fill="#111827", font=font(22),
                   anchor="lm")
    lx = W - 60
    for g, name in reversed(list(enumerate(groups))):
        lx -= d.textlength(name, font=font(28)) + 70
        d.rectangle([lx, 92, lx + 30, 110], fill=COLORS[g % len(COLORS)])
        d.text((lx + 40, 101), name, fill="#111827", font=font(28), anchor="lm")
    if note:
        d.text((60, H - 35), note, fill="#6b7280", font=font(22), anchor="lm")
    img.save(path)
