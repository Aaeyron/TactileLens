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

# Profile v2 (training/validation only): more faces. v1 (the frozen eval
# set) keeps using FONT_FILES alone, so it regenerates byte for byte.
FONT_FILES_V2 = {
    **FONT_FILES,
    "LiberationMono": ("liberation/LiberationMono-Regular.ttf", 1),
    "TeXGyrePagella": ("texgyre/texgyrepagella-regular.otf", 2),
    "TeXGyrePagella-Italic": ("texgyre/texgyrepagella-italic.otf", 1),
    "TeXGyreSchola": ("texgyre/texgyreschola-regular.otf", 2),
    "TeXGyreBonum": ("texgyre/texgyrebonum-regular.otf", 1),
    "TeXGyreAdventor": ("texgyre/texgyreadventor-regular.otf", 1),
    "TeXGyreCursor": ("texgyre/texgyrecursor-regular.otf", 1),
    "LatinModernSans": ("latinmodern/lmsans10-regular.otf", 2),
    "LatinModernSans-Oblique": ("latinmodern/lmsans10-oblique.otf", 1),
    "LatinModernMono": ("latinmodern/lmmono10-regular.otf", 1),
}

# Faces from math typesetting (LaTeX-like): these print a true minus "−"
# more often; word-processor faces more often a hyphen "-".
MATH_FACES = ("LatinModern", "TeXGyreTermes", "TeXGyrePagella", "TeXGyreSchola", "TeXGyreBonum", "STIX")

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


def fonts_for(text: str, fonts_dir: Path, profile: str = "v1") -> list[FontChoice]:
    """Fonts that can draw every character of [text]."""

    out = []
    for name, (relative, _) in (FONT_FILES if profile == "v1" else FONT_FILES_V2).items():
        path = fonts_dir / relative
        if path.exists() and all(has_glyph(str(path), c) for c in set(text)):
            out.append(FontChoice(name, path))
    return out


def pick_font(choices: list[FontChoice], rng: random.Random) -> FontChoice:
    weights = [FONT_FILES_V2[c.name][1] for c in choices]  # same weights as FONT_FILES for v1 faces
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
    stroke: int = 0,
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
            if stroke:
                draw.text((x, top_room + y_offset), c, font=f, fill=ink, stroke_width=stroke, stroke_fill=ink)
            else:
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


# ===================================================================== v2
# Training/validation only: worksheet-like surroundings and stronger photo
# effects, so the model does not just learn the look of the v1 generator.

_NEIGHBOUR_WORDS = "solve find the value of each expression show your work answer simplify x y 2 3 = + 4 5".split()


def _background(rng: random.Random, h: int, w: int, line_h: int) -> tuple[np.ndarray, dict]:
    kind = rng.choices(
        ["plain", "tinted", "lined", "grid", "page_edge", "table"],
        weights=[4, 2, 2, 1, 1, 1],
    )[0]
    paper = np.array(_paper(rng), dtype=np.float32)
    if kind == "tinted":
        paper = np.array(rng.choice([(200, 235, 245), (235, 225, 250), (215, 240, 215), (230, 220, 245), (210, 225, 250)]), dtype=np.float32)
    canvas = np.empty((h, w, 3), dtype=np.float32)
    canvas[:] = paper
    info = {"background": kind}
    if kind == "lined":
        colour = np.array(rng.choice([(200, 160, 120), (210, 180, 150), (180, 180, 220)]), dtype=np.float32)
        spacing = max(8, int(line_h * rng.uniform(1.1, 1.6)))
        offset = rng.randrange(spacing)
        for y in range(offset, h, spacing):
            canvas[y : y + 1, :] = colour
    elif kind == "grid":
        colour = np.array((210, 200, 180), dtype=np.float32)
        spacing = max(8, int(line_h * rng.uniform(0.4, 0.8)))
        canvas[::spacing, :] = colour
        canvas[:, ::spacing] = colour
    elif kind == "page_edge":
        # The page ends inside the crop: dark table on one side.
        table = np.array(rng.choice([(40, 50, 60), (60, 80, 100), (30, 30, 30), (90, 110, 130)]), dtype=np.float32)
        side = rng.choice(["left", "right", "top", "bottom"])
        size = rng.randint(2, max(3, (w if side in ("left", "right") else h) // 8))
        if side == "left":
            canvas[:, :size] = table
        elif side == "right":
            canvas[:, -size:] = table
        elif side == "top":
            canvas[:size, :] = table
        else:
            canvas[-size:, :] = table
        info["edge"] = side
    elif kind == "table":
        # Cell borders of a printed table near the crop edges.
        ink = np.array((40, 40, 40), dtype=np.float32)
        thick = rng.randint(1, 3)
        if rng.random() < 0.7:
            canvas[: thick, :] = ink
            canvas[-thick:, :] = ink
        if rng.random() < 0.5:
            canvas[:, : thick] = ink
        if rng.random() < 0.5:
            canvas[:, -thick:] = ink
    return canvas, info


def photo_line_v2(segments, font: FontChoice, rng: random.Random, style: str) -> tuple[np.ndarray, dict]:
    size = rng.randint(28, 84)
    stroke = rng.choice([0, 0, 0, 1]) if size >= 44 else 0
    ink = _ink(rng)
    tracking = rng.choice([0.0, 0.0, 0.02, 0.05, 0.08, -0.01, -0.02])
    text_img, info = draw_segments(segments, font.path, size, style, rng, tracking=tracking, stroke=stroke)
    text = cv2.cvtColor(np.asarray(text_img), cv2.COLOR_RGB2BGR).astype(np.float32)

    h, w = text.shape[:2]
    top, bottom = int(h * rng.uniform(0.08, 0.6)), int(h * rng.uniform(0.08, 0.6))
    left, right = int(h * rng.uniform(0.05, 0.9)), int(h * rng.uniform(0.05, 0.9))
    context = {}
    # An answer line after the text ("x² + 3 = ______"), drawn, not labelled.
    answer_rule = rng.random() < 0.15
    if answer_rule:
        right += int(h * rng.uniform(1.5, 4.0))
    canvas, background = _background(rng, h + top + bottom, w + left + right, h)

    alpha = 1.0 - text.mean(axis=2, keepdims=True) / 255.0
    ink_bgr = np.array(ink[::-1], dtype=np.float32)
    region = canvas[top : top + h, left : left + w]
    canvas[top : top + h, left : left + w] = region * (1 - alpha) + ink_bgr * alpha

    if answer_rule:
        y = top + h - max(1, h // 12)
        canvas[y : y + max(1, h // 25), left + w + int(h * 0.3) : -max(2, right // 6)] = ink_bgr
        context["answer_rule"] = True

    # A sliver of the line above or below, cut by the crop (dense pages).
    if rng.random() < 0.2:
        words = " ".join(rng.choice(_NEIGHBOUR_WORDS) for _ in range(rng.randint(2, 6)))
        sliver, _ = draw_segments([(words, False)], font.path, size, "typeset", rng)
        s = cv2.cvtColor(np.asarray(sliver), cv2.COLOR_RGB2BGR).astype(np.float32)
        s_alpha = 1.0 - s.mean(axis=2, keepdims=True) / 255.0
        show = rng.randint(2, max(3, min(top, bottom, s.shape[0] // 4) or 3))
        x0 = rng.randint(0, max(0, canvas.shape[1] - s.shape[1])) if canvas.shape[1] > s.shape[1] else 0
        part_w = min(s.shape[1], canvas.shape[1] - x0)
        if rng.random() < 0.5:  # bottom of the line above
            a = s_alpha[-show:, :part_w]
            canvas[:show, x0 : x0 + part_w] = canvas[:show, x0 : x0 + part_w] * (1 - a) + ink_bgr * a
            context["neighbour"] = "above"
        else:  # top of the line below
            a = s_alpha[:show, :part_w]
            canvas[-show:, x0 : x0 + part_w] = canvas[-show:, x0 : x0 + part_w] * (1 - a) + ink_bgr * a
            context["neighbour"] = "below"

    choices = {
        "profile": "v2", "font": font.name, "size": size, "stroke": stroke, "ink": list(ink),
        **background, **context, **info,
    }
    image, aug = augment_v2(canvas, rng)
    choices["augment"] = aug
    return image, choices


def augment_v2(image: np.ndarray, rng: random.Random) -> tuple[np.ndarray, dict]:
    applied = {}
    h, w = image.shape[:2]
    np_rng = np.random.default_rng(rng.randrange(1 << 30))

    # Ink spread or thin print (bleed / worn toner).
    if rng.random() < 0.35:
        darkness = 255.0 - image.mean(axis=2)
        kernel = np.ones((2, 2), np.uint8)
        if rng.random() < 0.5:
            darker = cv2.dilate(darkness, kernel)
            applied["ink"] = "bleed"
        else:
            darker = cv2.erode(darkness, kernel)
            applied["ink"] = "thin"
        image = image + (darkness - darker)[:, :, None]

    if rng.random() < 0.7:
        sigma = rng.uniform(2, 10)
        noise = cv2.GaussianBlur(np_rng.normal(0, sigma, (h, w)).astype(np.float32), (0, 0), rng.uniform(0.8, 2.5))
        image = image + noise[:, :, None]
        applied["texture"] = round(sigma, 2)

    # Uneven light, and sometimes a hard shadow (hand or phone).
    if rng.random() < 0.7:
        strength = rng.uniform(0.1, 0.6)
        angle = rng.uniform(0, 2 * np.pi)
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        ramp = np.cos(angle) * xx / max(w, 1) + np.sin(angle) * yy / max(h, 1)
        ramp = (ramp - ramp.min()) / max(float(np.ptp(ramp)), 1e-6)
        if rng.random() < 0.3:
            ramp = cv2.GaussianBlur((ramp > rng.uniform(0.3, 0.7)).astype(np.float32), (0, 0), rng.uniform(1, 4))
            applied["hard_shadow"] = True
        image = image * (1 - strength * ramp[:, :, None])
        applied["shadow"] = round(strength, 2)

    # Colour cast (indoor light, white balance).
    if rng.random() < 0.5:
        cast = np.array([rng.uniform(0.85, 1.1), rng.uniform(0.9, 1.05), rng.uniform(0.85, 1.15)], dtype=np.float32)
        image = image * cast
        applied["cast"] = [round(float(c), 2) for c in cast]

    if rng.random() < 0.8:
        angle = rng.uniform(-4.0, 4.0)
        jitter = rng.uniform(0, 0.06)
        src = np.float32([[0, 0], [w, 0], [w, h], [0, h]])
        dst = src + np.float32([[rng.uniform(-1, 1) * jitter * w, rng.uniform(-1, 1) * jitter * h] for _ in range(4)])
        matrix = cv2.getPerspectiveTransform(src, dst)
        rotation = cv2.getRotationMatrix2D((w / 2, h / 2), angle, 1.0)
        matrix = np.vstack([rotation, [0, 0, 1]]).astype(np.float64) @ matrix
        image = cv2.warpPerspective(image, matrix, (w, h), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
        applied["rotate"] = round(angle, 2)
        applied["perspective"] = round(jitter, 3)

    if rng.random() < 0.8:
        target_h = rng.randint(14, 48)
        scale = target_h / h
        small = cv2.resize(image, (max(1, int(w * scale)), target_h), interpolation=cv2.INTER_AREA)
        image = cv2.resize(small, (w, h), interpolation=rng.choice([cv2.INTER_LINEAR, cv2.INTER_CUBIC, cv2.INTER_NEAREST]))
        applied["resolution_h"] = target_h

    roll = rng.random()
    if roll < 0.5:
        sigma = rng.uniform(0.3, 2.0)
        image = cv2.GaussianBlur(image, (0, 0), sigma)
        applied["blur"] = round(sigma, 2)
    elif roll < 0.7:
        length = rng.randint(3, 9)
        kernel = np.zeros((length, length), np.float32)
        kernel[length // 2, :] = 1.0 / length
        rotation = cv2.getRotationMatrix2D((length / 2 - 0.5, length / 2 - 0.5), rng.uniform(0, 180), 1.0)
        kernel = cv2.warpAffine(kernel, rotation, (length, length))
        kernel /= max(kernel.sum(), 1e-6)
        image = cv2.filter2D(image, -1, kernel)
        applied["motion_blur"] = length

    if rng.random() < 0.7:
        sigma = rng.uniform(1, 14)
        image = image + np_rng.normal(0, sigma, image.shape).astype(np.float32)
        applied["noise"] = round(sigma, 2)

    # Low light: dim and flat.
    if rng.random() < 0.2:
        image = image * rng.uniform(0.45, 0.75) + rng.uniform(5, 25)
        applied["low_light"] = True

    alpha, beta = rng.uniform(0.65, 1.2), rng.uniform(-35, 25)
    image = image * alpha + beta
    applied["contrast"] = [round(alpha, 2), round(beta, 1)]

    image = np.clip(image, 0, 255).astype(np.uint8)

    if rng.random() < 0.9:
        quality = rng.randint(20, 92)
        _, encoded = cv2.imencode(".jpg", image, [cv2.IMWRITE_JPEG_QUALITY, quality])
        image = cv2.imdecode(encoded, cv2.IMREAD_COLOR)
        applied["jpeg"] = quality

    return image, applied
