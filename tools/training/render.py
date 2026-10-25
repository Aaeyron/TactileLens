"""Draw a generated line as an image, and make it look like a phone photo.

Two ways of drawing raised characters (the label is the same):
  typeset  smaller normal glyphs, raised above the baseline, the way
           printed worksheets set exponents
  glyph    the font's own Unicode superscript glyphs (only with fonts that
           have every one the line needs)

Crops get a margin like the app's detector boxes (DB unclip 1.5), then
augmentations: paper and ink colour, uneven light, blur, noise, small
rotation and perspective, low resolution and JPEG compression. Each
choice is returned so it can be written to the manifest.
"""

from __future__ import annotations

import random
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

from common import SUPERSCRIPT

# Font files under <root>/fonts (see FONTS.md). Weight is how often a face
# is picked.
FONT_FILES = {
    "DejaVuSans": ("dejavu/DejaVuSans.ttf", 2),
    "DejaVuSans-Oblique": ("dejavu/DejaVuSans-Oblique.ttf", 1),
    "DejaVuSerif": ("dejavu/DejaVuSerif.ttf", 2),
    "DejaVuSerif-Italic": ("dejavu/DejaVuSerif-Italic.ttf", 1),
    "DejaVuSansMono": ("dejavu/DejaVuSansMono.ttf", 1),
    "STIXGeneral": ("stix/STIXGeneral.ttf", 2),
    "STIXGeneral-Italic": ("stix/STIXGeneralItalic.ttf", 2),
    "LiberationSans": ("liberation/LiberationSans-Regular.ttf", 3),
    "LiberationSans-Italic": ("liberation/LiberationSans-Italic.ttf", 1),
    "LiberationSerif": ("liberation/LiberationSerif-Regular.ttf", 3),
    "LiberationSerif-Italic": ("liberation/LiberationSerif-Italic.ttf", 2),
    "TeXGyreTermes": ("texgyre/texgyretermes-regular.otf", 3),
    "TeXGyreTermes-Italic": ("texgyre/texgyretermes-italic.otf", 2),
    "TeXGyreHeros": ("texgyre/texgyreheros-regular.otf", 2),
    "LatinModern": ("latinmodern/lmroman10-regular.otf", 3),
    "LatinModern-Italic": ("latinmodern/lmroman10-italic.otf", 2),
}

_MISSING_PROBE = ""  # private use: renders as the font's .notdef


@dataclass(frozen=True)
class FontChoice:
    name: str
    path: Path


@lru_cache(maxsize=None)
def _font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


@lru_cache(maxsize=None)
def _notdef_mask(path: str) -> bytes:
    font = _font(path, 48)
    return bytes(font.getmask(_MISSING_PROBE))


@lru_cache(maxsize=None)
def has_glyph(path: str, char: str) -> bool:
    if char == " ":
        return True
    font = _font(path, 48)
    mask = font.getmask(char)
    if mask.getbbox() is None:
        return False
    return bytes(mask) != _notdef_mask(path)


def fonts_for(text: str, fonts_dir: Path) -> list[FontChoice]:
    """Fonts that can draw every character of [text]."""

    out = []
    for name, (relative, _) in FONT_FILES.items():
        path = fonts_dir / relative
        if path.exists() and all(has_glyph(str(path), c) for c in set(text)):
            out.append(FontChoice(name, path))
    return out


def pick_font(choices: list[FontChoice], rng: random.Random) -> FontChoice:
    weights = [FONT_FILES[c.name][1] for c in choices]
    return rng.choices(choices, weights=weights, k=1)[0]


# ------------------------------------------------------------- drawing


def draw_segments(
    segments,
    font_path: Path,
    size: int,
    style: str,
    rng: random.Random,
    ink: tuple[int, int, int] = (0, 0, 0),
    tracking: float = 0.0,
) -> tuple[Image.Image, dict]:
    """Draws the line on a white background, tightly; returns image and
    the drawing choices."""

    font = _font(str(font_path), size)
    ascent, descent = font.getmetrics()
    raise_ratio = rng.uniform(0.33, 0.45)
    small_ratio = rng.uniform(0.58, 0.72)
    small = _font(str(font_path), max(8, int(size * small_ratio)))
    lift = int(size * raise_ratio)

    pieces = []  # (text, font, y_offset)
    for text, raised in segments:
        if raised and style == "glyph":
            pieces.append(("".join(SUPERSCRIPT[c] for c in text), font, 0))
        elif raised:
            pieces.append((text, small, -lift + (ascent - small.getmetrics()[0])))
        else:
            pieces.append((text, font, 0))

    gap = size * tracking
    width = 0.0
    for text, f, _ in pieces:
        for c in text:
            width += f.getlength(c) + gap
    top_room = lift + 2
    height = ascent + descent + top_room + 4
    image = Image.new("RGB", (int(width) + 8, height), (255, 255, 255))
    draw = ImageDraw.Draw(image)
    x = 4.0
    for text, f, y_offset in pieces:
        for c in text:
            draw.text((x, top_room + y_offset), c, font=f, fill=ink)
            x += f.getlength(c) + gap

    # Trim to the ink.
    gray = np.asarray(image.convert("L"))
    ys, xs = np.where(gray < 250)
    if len(xs):
        image = image.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    info = {"style": style, "raise": round(raise_ratio, 3), "small": round(small_ratio, 3), "tracking": round(tracking, 3)}
    return image, info


# ------------------------------------------------------------- photo look


def _paper(rng: random.Random) -> tuple[int, int, int]:
    base = rng.randint(205, 252)
    tint = rng.choice([(0, 0, 0), (0, 4, 10), (8, 4, 0), (3, 3, 3)])
    return tuple(int(min(255, max(0, base - t))) for t in tint)  # BGR-ish tint


def _ink(rng: random.Random) -> tuple[int, int, int]:
    return rng.choice([(0, 0, 0), (25, 25, 25), (40, 40, 45), (20, 25, 70), (60, 60, 60)])


def photo_line(segments, font: FontChoice, rng: random.Random, style: str) -> tuple[np.ndarray, dict]:
    """A line crop that looks like it came from a phone photo through the
    app's detector. Returns BGR uint8 and the choices made."""

    size = rng.randint(36, 72)
    ink = _ink(rng)
    tracking = rng.choice([0.0, 0.0, 0.02, 0.05, -0.01])
    # Drawn in black; the ink colour is blended in below.
    text_img, info = draw_segments(segments, font.path, size, style, rng, tracking=tracking)
    text = cv2.cvtColor(np.asarray(text_img), cv2.COLOR_RGB2BGR).astype(np.float32)

    # Margin like a detector box: DB unclip adds roughly 0.15-0.45 of the
    # line height above/below and a bit more at the ends.
    h, w = text.shape[:2]
    top, bottom = int(h * rng.uniform(0.15, 0.45)), int(h * rng.uniform(0.15, 0.45))
    left, right = int(h * rng.uniform(0.1, 0.6)), int(h * rng.uniform(0.1, 0.6))
    paper = np.array(_paper(rng), dtype=np.float32)
    canvas = np.empty((h + top + bottom, w + left + right, 3), dtype=np.float32)
    canvas[:] = paper
    # Text image is black-on-white: blend ink onto paper.
    alpha = 1.0 - text.mean(axis=2, keepdims=True) / 255.0
    ink_bgr = np.array(ink[::-1], dtype=np.float32)
    region = canvas[top : top + h, left : left + w]
    canvas[top : top + h, left : left + w] = region * (1 - alpha) + ink_bgr * alpha

    choices = {"font": font.name, "size": size, "ink": list(ink), "paper": [int(v) for v in paper], **info}
    image, aug = augment(canvas, rng)
    choices["augment"] = aug
    return image, choices


def augment(image: np.ndarray, rng: random.Random) -> tuple[np.ndarray, dict]:
    applied = {}
    h, w = image.shape[:2]

    # Paper texture.
    if rng.random() < 0.6:
        sigma = rng.uniform(2, 7)
        noise = cv2.GaussianBlur(np.random.default_rng(rng.randrange(1 << 30)).normal(0, sigma, (h, w)).astype(np.float32), (0, 0), 1.5)
        image = image + noise[:, :, None]
        applied["texture"] = round(sigma, 2)

    # Uneven light / shadow across the line.
    if rng.random() < 0.6:
        strength = rng.uniform(0.1, 0.45)
        angle = rng.uniform(0, 2 * np.pi)
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        ramp = (np.cos(angle) * xx / max(w, 1) + np.sin(angle) * yy / max(h, 1))
        ramp = (ramp - ramp.min()) / max(float(np.ptp(ramp)), 1e-6)
        image = image * (1 - strength * ramp[:, :, None])
        applied["shadow"] = round(strength, 2)

    # Small rotation and perspective (the detector crop straightens most).
    if rng.random() < 0.7:
        angle = rng.uniform(-2.0, 2.0)
        jitter = rng.uniform(0, 0.03)
        src = np.float32([[0, 0], [w, 0], [w, h], [0, h]])
        dst = src + np.float32([[rng.uniform(-1, 1) * jitter * w, rng.uniform(-1, 1) * jitter * h] for _ in range(4)])
        matrix = cv2.getPerspectiveTransform(src, dst)
        rotation = cv2.getRotationMatrix2D((w / 2, h / 2), angle, 1.0)
        matrix = np.vstack([rotation, [0, 0, 1]]).astype(np.float64) @ matrix
        image = cv2.warpPerspective(image, matrix, (w, h), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
        applied["rotate"] = round(angle, 2)
        applied["perspective"] = round(jitter, 3)

    # Lower resolution (distance, phone camera), then back up.
    if rng.random() < 0.7:
        target_h = rng.randint(18, 44)
        scale = target_h / h
        small = cv2.resize(image, (max(1, int(w * scale)), target_h), interpolation=cv2.INTER_AREA)
        image = cv2.resize(small, (w, h), interpolation=cv2.INTER_LINEAR)
        applied["resolution_h"] = target_h

    # Blur: focus or a little motion.
    roll = rng.random()
    if roll < 0.45:
        sigma = rng.uniform(0.3, 1.4)
        image = cv2.GaussianBlur(image, (0, 0), sigma)
        applied["blur"] = round(sigma, 2)
    elif roll < 0.6:
        length = rng.randint(3, 7)
        kernel = np.zeros((length, length), np.float32)
        kernel[length // 2, :] = 1.0 / length
        rotation = cv2.getRotationMatrix2D((length / 2 - 0.5, length / 2 - 0.5), rng.uniform(0, 180), 1.0)
        kernel = cv2.warpAffine(kernel, rotation, (length, length))
        kernel /= max(kernel.sum(), 1e-6)
        image = cv2.filter2D(image, -1, kernel)
        applied["motion_blur"] = length

    # Sensor noise.
    if rng.random() < 0.6:
        sigma = rng.uniform(1, 9)
        image = image + np.random.default_rng(rng.randrange(1 << 30)).normal(0, sigma, image.shape).astype(np.float32)
        applied["noise"] = round(sigma, 2)

    # Contrast / brightness.
    alpha, beta = rng.uniform(0.75, 1.15), rng.uniform(-25, 20)
    image = image * alpha + beta
    applied["contrast"] = [round(alpha, 2), round(beta, 1)]

    image = np.clip(image, 0, 255).astype(np.uint8)

    # JPEG artefacts (re-encoded here; the file is saved as PNG after).
    if rng.random() < 0.85:
        quality = rng.randint(30, 92)
        _, encoded = cv2.imencode(".jpg", image, [cv2.IMWRITE_JPEG_QUALITY, quality])
        image = cv2.imdecode(encoded, cv2.IMREAD_COLOR)
        applied["jpeg"] = quality

    return image, applied
