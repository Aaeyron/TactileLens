"""Synthetic worksheet-level algebra formulas for Track A (training only).

With C:\\Projects\\Capstone\\paddle_formula_env (matplotlib, Pillow, OpenCV):
  python make_synthetic_formulas.py --out <new folder> [--per-topic 300] [--workers 8] [--seed 2026]

For each of the 8 topics (fractions, exponents, radicals,
linear_equations, quadratic_equations, inequalities, polynomials,
function_notation) the templates below draw random worksheet-level
formulas (e.g. \\frac{3x+1}{4}=2, \\sqrt{x+9}=5, -3<2x+1\\leq 7). Each is
rendered with matplotlib's mathtext in one of 10 font styles (5 built-in
math font sets + Latin Modern, TeX Gyre Termes / Pagella, Liberation
Serif / Sans from <root>/fonts) and put on paper with Track B's
backgrounds (tools/training/render.py: _background, _ink) and phone-photo
effects of the same kinds as Track B's augment_v2 with formula-safe ranges
(formula_effects); about 15% are left clean.

Label = the rendered LaTeX in im2latex's style (a space between tokens,
\\leq / \\geq / \\neq always written the same way, so one image never has
two labels). The formula a template writes is exactly what is drawn.

Leak guard (training only): a formula is dropped when its LaTeX (spaces
removed) equals an im2latex-100k val or test formula of --im2latex, or a
formula target in the frozen eval registry (<root>/splits/frozen_eval.jsonl,
when it exists), or an earlier synthetic formula (no duplicates).

Writes <out>/images/<topic>_syn_<n>.png, <out>/train.txt (LF line ends,
images/<name><TAB><label>), <out>/manifest.jsonl (template, font, effects,
seed per image) and <out>/report.md (counts per topic, drops, timing).
There is no val or test file: synthetic data is never used to evaluate.
"""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import sys
import time
from multiprocessing import Pool
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "training"))

TOPICS = ["fractions", "exponents", "radicals", "linear_equations", "quadratic_equations", "inequalities",
          "polynomials", "function_notation"]
TOKEN = re.compile(r"\\[A-Za-z]+|\\.|[{}^_]|[A-Za-z]|\d|[^\sA-Za-z\d]")  # algebra_filter.py's
VARS = ["x", "x", "x", "y", "a", "n", "m", "t", "b", "k"]
ROOT = Path(os.environ.get("TL_TRAIN_ROOT", r"C:\Projects\Capstone\tactilelens-training"))


# ------------------------------------------------------------- templates

def n(r: random.Random, lo: int = 1, hi: int = 12) -> int:
    return r.randint(lo, hi)


def coef(r: random.Random, c: int, v: str) -> str:
    """2x, x, -x, -3x."""
    if c == 1:
        return v
    if c == -1:
        return "-" + v
    return f"{c}{v}"


def signed(c: int, first: bool = False) -> str:
    c = c or 1  # never "+0"
    if first:
        return str(c)
    return f"+{c}" if c >= 0 else f"-{-c}"


def fractions(r: random.Random) -> str:
    v = r.choice(VARS)
    k = r.randrange(6)
    if k == 0:
        return rf"\frac{{{n(r)}}}{{{n(r, 2)}}}{r.choice(['+', '-'])}\frac{{{n(r)}}}{{{n(r, 2)}}}"
    if k == 1:
        return rf"\frac{{{coef(r, n(r), v)}{signed(n(r, -9, 9))}}}{{{n(r, 2)}}}={n(r, -9, 12)}"
    if k == 2:
        return rf"\frac{{{v}}}{{{n(r, 2)}}}+\frac{{{v}}}{{{n(r, 2)}}}={n(r)}"
    if k == 3:
        op = r.choice([r"\cdot", r"\times", r"\div"])
        return rf"\frac{{{n(r)}}}{{{n(r, 2)}}}{op}\frac{{{n(r)}}}{{{n(r, 2)}}}"
    if k == 4:
        return rf"\frac{{{n(r)}}}{{{v}{signed(n(r, -9, 9))}}}=\frac{{{n(r)}}}{{{n(r, 2)}}}"
    return rf"{v}=\frac{{{n(r)}}}{{{n(r, 2)}}}"


def exponents(r: random.Random) -> str:
    v = r.choice(VARS)
    a, b = n(r, 2, 9), n(r, 2, 9)
    k = r.randrange(6)
    if k == 0:
        return rf"{v}^{{{a}}}\cdot {v}^{{{b}}}={v}^{{{a + b}}}"
    if k == 1:
        return rf"({v}^{{{a}}})^{{{b}}}"
    if k == 2:
        return rf"{v}^{{-{a}}}=\frac{{1}}{{{v}^{{{a}}}}}"
    if k == 3:
        base = n(r, 2, 5)
        return rf"{base}^{{{a % 5 + 1}}}={base ** (a % 5 + 1)}"
    if k == 4:
        return rf"\frac{{{v}^{{{a + b}}}}}{{{v}^{{{b}}}}}"
    return rf"{n(r, 2, 9)}{v}^{{{a}}}{r.choice(['', 'y^{' + str(b) + '}'])}"


def radicals(r: random.Random) -> str:
    v = r.choice(VARS)
    k = r.randrange(6)
    if k == 0:
        m = n(r, 2, 15)
        return rf"\sqrt{{{m * m}}}={m}"
    if k == 1:
        return rf"{n(r, 2, 9)}\sqrt{{{r.choice([2, 3, 5, 6, 7, 10, 11])}}}"
    if k == 2:
        return rf"\sqrt{{{v}{signed(n(r, -9, 12))}}}={n(r, 2, 9)}"
    if k == 3:
        m = n(r, 2, 6)
        return rf"\sqrt[3]{{{m ** 3}}}={m}"
    if k == 4:
        return rf"\sqrt{{{v}^{{2}}+{n(r, 1, 16)}}}"
    return rf"\sqrt{{{n(r, 2, 50)}}}{r.choice(['+', '-'])}\sqrt{{{n(r, 2, 50)}}}"


def linear_equations(r: random.Random) -> str:
    v = r.choice(VARS)
    k = r.randrange(4)
    if k == 0:
        return rf"{coef(r, n(r, -9, 12) or 2, v)}{signed(n(r, -15, 15))}={n(r, -20, 30)}"
    if k == 1:
        return rf"{n(r, 2, 9)}({v}{signed(n(r, -9, 9))})={n(r, -20, 30)}"
    if k == 2:
        return rf"{coef(r, n(r, 2, 9), v)}{signed(n(r, -9, 9))}={coef(r, n(r, 1, 9), v)}{signed(n(r, -9, 9))}"
    return rf"{v}={n(r, -20, 20)}"


def quadratic_equations(r: random.Random) -> str:
    v = r.choice(["x", "x", "y", "t"])
    k = r.randrange(5)
    if k == 0:
        return rf"{v}^{{2}}{signed(n(r, -12, 12))}{v}{signed(n(r, -20, 20))}=0"
    if k == 1:
        return rf"{n(r, 2, 9)}{v}^{{2}}-{n(r, 1, 50)}=0"
    if k == 2:
        return rf"({v}{signed(n(r, -9, 9))})({v}{signed(n(r, -9, 9))})=0"
    if k == 3:
        return rf"{v}=\frac{{-b\pm\sqrt{{b^{{2}}-4ac}}}}{{2a}}"
    return rf"{coef(r, n(r, 1, 5), v + '^{2}')}={n(r, 1, 81)}"


def inequalities(r: random.Random) -> str:
    v = r.choice(VARS)
    # Trailing space: "\leq n" must not become the unknown command "\leqn".
    rel = lambda: r.choice(["<", ">", "\\leq ", "\\geq "])  # noqa: E731
    k = r.randrange(5)
    if k == 0:
        return rf"{coef(r, n(r, 2, 9), v)}{signed(n(r, -9, 9))}{rel()}{n(r, -15, 20)}"
    if k == 1:
        lo = n(r, -9, 5)
        r1, r2 = r.choice(["<", "\\leq "]), r.choice(["<", "\\leq "])
        return rf"{lo}{r1}{v}{r2}{lo + n(r, 1, 9)}"
    if k == 2:
        return rf"-{n(r, 1, 9)}<{coef(r, n(r, 2, 6), v)}{signed(n(r, -9, 9))}\leq {n(r, 5, 20)}"
    if k == 3:
        return rf"{v}{rel()}{n(r, -9, 12)}"
    return rf"{v}\neq {n(r, -9, 9)}"


def polynomials(r: random.Random) -> str:
    v = r.choice(["x", "x", "y", "a"])
    k = r.randrange(4)
    if k == 0:
        return rf"{n(r, 1, 9)}{v}^{{3}}{signed(n(r, -9, 9))}{v}^{{2}}{signed(n(r, -9, 9))}{v}{signed(n(r, -9, 9))}"
    if k == 1:
        return rf"({v}{signed(n(r, -9, 9))})({v}{signed(n(r, -9, 9))})"
    if k == 2:
        return rf"({n(r, 2, 5)}{v}{signed(n(r, -9, 9))})^{{2}}"
    return rf"{coef(r, n(r, 2, 9), v + '^{2}')}{signed(n(r, -12, 12))}{v}{signed(n(r, -12, 12))}"


def function_notation(r: random.Random) -> str:
    f = r.choice(["f", "f", "g", "h"])
    v = r.choice(["x", "x", "t"])
    k = r.randrange(5)
    if k == 0:
        return rf"{f}({v})={coef(r, n(r, 2, 9), v)}{signed(n(r, -9, 9))}"
    if k == 1:
        return rf"{f}({n(r, -5, 9)})={n(r, -20, 40)}"
    if k == 2:
        return rf"{f}({v})={n(r, 1, 5)}{v}^{{2}}{signed(n(r, -9, 9))}{v}{signed(n(r, -9, 9))}"
    if k == 3:
        return rf"f(g({v}))"
    return rf"{f}({v})=\frac{{{n(r, 1, 9)}}}{{{v}{signed(n(r, -9, 9))}}}"


TEMPLATES = {t: globals()[t] for t in TOPICS}


def label_of(latex: str) -> str:
    """im2latex style: a space between tokens."""
    return " ".join(TOKEN.findall(latex))


def key(latex: str) -> str:
    return re.sub(r"\s+", "", latex)


# ------------------------------------------------------------- rendering

BUILTIN = ["cm", "stix", "stixsans", "dejavusans", "dejavuserif"]
CUSTOM = {  # name -> (regular, italic) under <root>/fonts
    "latinmodern": ("latinmodern/lmroman10-regular.otf", "latinmodern/lmroman10-italic.otf"),
    "termes": ("texgyre/texgyretermes-regular.otf", "texgyre/texgyretermes-italic.otf"),
    "pagella": ("texgyre/texgyrepagella-regular.otf", "texgyre/texgyrepagella-italic.otf"),
    "liberation_serif": ("liberation/LiberationSerif-Regular.ttf", "liberation/LiberationSerif-Italic.ttf"),
    "liberation_sans": ("liberation/LiberationSans-Regular.ttf", "liberation/LiberationSans-Italic.ttf"),
}
STYLES = BUILTIN + list(CUSTOM)
_custom_names: dict[str, tuple[str, str]] = {}


def _init_worker() -> None:
    import logging

    import matplotlib
    logging.getLogger("matplotlib.font_manager").setLevel(logging.ERROR)  # no bold faces: regular is used
    matplotlib.use("Agg")
    from matplotlib import font_manager
    for name, files in CUSTOM.items():
        names = []
        for f in files:
            path = ROOT / "fonts" / f
            font_manager.fontManager.addfont(str(path))
            names.append(font_manager.FontProperties(fname=str(path)).get_name())
        _custom_names[name] = (names[0], names[1])


def ink_mask(latex: str, style: str, size: int, dpi: int):
    """Black-on-white mathtext drawing -> float mask (1 = ink)."""
    import io

    import matplotlib
    import numpy as np
    from matplotlib import mathtext
    from matplotlib.font_manager import FontProperties
    from PIL import Image

    rc = {"mathtext.fontset": style if style in BUILTIN else "custom", "mathtext.fallback": "stix"}
    if style not in BUILTIN:
        rm, it = _custom_names[style]
        rc.update({"mathtext.rm": rm, "mathtext.it": f"{it}:italic", "mathtext.bf": f"{rm}:bold"})
    buf = io.BytesIO()
    with matplotlib.rc_context(rc):
        mathtext.math_to_image(f"${latex}$", buf, prop=FontProperties(size=size), dpi=dpi, format="png")
    # math_to_image draws black on an opaque white background.
    img = Image.open(io.BytesIO(buf.getvalue())).convert("L")
    return 1.0 - np.asarray(img).astype(np.float32) / 255.0


def formula_effects(image, r: random.Random):
    """Phone-photo effects of the same kinds as Track B's augment_v2, with
    ranges that keep a formula readable and inside the crop: Track B shrinks
    a text line to 14-48 px high, which erases fractions and exponents, and
    its perspective (up to 6% of the width) can cut off the ends."""
    import cv2
    import numpy as np

    applied = {}
    h, w = image.shape[:2]
    np_rng = np.random.default_rng(r.randrange(1 << 30))
    image = image.astype(np.float32)
    if r.random() < 0.6:  # paper texture
        sigma = r.uniform(1.0, 5.0)
        image += cv2.GaussianBlur(np_rng.normal(0, sigma, (h, w)).astype(np.float32), (0, 0), 1.0)[..., None]
        applied["texture"] = round(sigma, 2)
    if r.random() < 0.6:  # uneven light (soft gradient)
        strength = r.uniform(0.1, 0.35)
        gx = np.linspace(0, 1, w, dtype=np.float32)[None, :]
        gy = np.linspace(0, 1, h, dtype=np.float32)[:, None]
        a, b = r.uniform(-1, 1), r.uniform(-1, 1)
        shade = 1 - strength * np.clip((a * gx + b * gy + 1) / 2, 0, 1)
        image *= shade[..., None]
        applied["shadow"] = round(strength, 2)
    if r.random() < 0.4:  # colour cast
        cast = np.array([r.uniform(0.9, 1.08) for _ in range(3)], dtype=np.float32)
        image *= cast
        applied["cast"] = [round(float(c), 2) for c in cast]
    if r.random() < 0.7:  # small rotation and perspective
        angle, jitter = r.uniform(-3.0, 3.0), r.uniform(0, 0.03)
        src = np.float32([[0, 0], [w, 0], [w, h], [0, h]])
        dst = src + np.float32([[r.uniform(-1, 1) * jitter * w, r.uniform(-1, 1) * jitter * h] for _ in range(4)])
        m = np.vstack([cv2.getRotationMatrix2D((w / 2, h / 2), angle, 1.0), [0, 0, 1]]) @ cv2.getPerspectiveTransform(src, dst)
        image = cv2.warpPerspective(image, m, (w, h), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
        applied["rotate"], applied["perspective"] = round(angle, 2), round(jitter, 3)
    if r.random() < 0.6:  # lower resolution, never below half the height or 48 px
        target_h = r.randint(max(48, h // 2), max(49, int(h * 0.85)))
        small = cv2.resize(image, (max(1, int(w * target_h / h)), target_h), interpolation=cv2.INTER_AREA)
        image = cv2.resize(small, (w, h), interpolation=r.choice([cv2.INTER_LINEAR, cv2.INTER_CUBIC]))
        applied["resolution_h"] = target_h
    roll = r.random()
    if roll < 0.45:
        sigma = r.uniform(0.3, 1.2)
        image = cv2.GaussianBlur(image, (0, 0), sigma)
        applied["blur"] = round(sigma, 2)
    elif roll < 0.6:
        length = r.randint(3, 5)
        kernel = np.zeros((length, length), np.float32)
        kernel[length // 2, :] = 1.0 / length
        kernel = cv2.warpAffine(kernel, cv2.getRotationMatrix2D((length / 2 - 0.5, length / 2 - 0.5), r.uniform(0, 180), 1.0),
                                (length, length))
        image = cv2.filter2D(image, -1, kernel / max(kernel.sum(), 1e-6))
        applied["motion_blur"] = length
    if r.random() < 0.6:
        sigma = r.uniform(1, 8)
        image = image + np_rng.normal(0, sigma, image.shape).astype(np.float32)
        applied["noise"] = round(sigma, 2)
    if r.random() < 0.15:
        image = image * r.uniform(0.6, 0.8) + r.uniform(5, 20)
        applied["low_light"] = True
    alpha, beta = r.uniform(0.75, 1.15), r.uniform(-25, 20)
    image = np.clip(image * alpha + beta, 0, 255).astype(np.uint8)
    applied["contrast"] = [round(alpha, 2), round(beta, 1)]
    if r.random() < 0.85:
        quality = r.randint(40, 95)
        ok, enc = cv2.imencode(".jpg", image, [cv2.IMWRITE_JPEG_QUALITY, quality])
        image = cv2.imdecode(enc, cv2.IMREAD_COLOR)
        applied["jpeg"] = quality
    return image, applied


def render_one(job: tuple) -> dict:
    index, topic, latex, seed, out = job
    import cv2
    import numpy as np
    import render as tb  # tools/training/render.py

    r = random.Random(seed)
    style = r.choice(STYLES)
    size, dpi = r.randint(22, 34), r.choice([150, 180, 220])
    # Half the fractions in display size (\dfrac); the label stays \frac, as
    # LaTeX display math writes it (same notation, larger drawing).
    display = r.random() < 0.5
    drawn = latex.replace(r"\frac", r"\dfrac") if display else latex
    mask = ink_mask(drawn, style, size, dpi)
    h, w = mask.shape
    top, bottom = int(h * r.uniform(0.15, 0.8)), int(h * r.uniform(0.15, 0.8))
    # Side margins at least 7% of the width, so rotation and perspective never cut the ends.
    left, right = max(int(h * r.uniform(0.1, 1.0)), int(0.07 * w)), max(int(h * r.uniform(0.1, 1.0)), int(0.07 * w))
    # Plain, tinted, lined or grid paper only: the page-edge and table
    # backgrounds can put dark areas under the formula.
    for _ in range(20):
        canvas, background = tb._background(r, h + top + bottom, w + left + right, max(h, 20))
        if background["background"] in ("plain", "tinted", "lined", "grid"):
            break
    ink = np.array(tb._ink(r)[::-1], dtype=np.float32)
    a = mask[..., None]
    region = canvas[top:top + h, left:left + w]
    canvas[top:top + h, left:left + w] = region * (1 - a) + ink * a
    info = {"style": style, "size": size, "dpi": dpi, "display_fractions": display and r"\frac" in latex, **background}
    if r.random() < 0.85:
        image, aug = formula_effects(canvas, r)
        info["augment"] = aug
    else:
        image = np.clip(canvas, 0, 255).astype(np.uint8)
        info["augment"] = "none (clean)"
    name = f"{topic}_syn_{index:05d}.png"
    cv2.imwrite(str(Path(out) / "images" / name), image)
    return {"image": f"images/{name}", "topic": topic, "latex": latex, "label": label_of(latex), "seed": seed,
            "height": int(image.shape[0]), "width": int(image.shape[1]), **info}


# ------------------------------------------------------------- main

def held_out_keys(im2latex: Path | None) -> dict[str, str]:
    keys = {}
    if im2latex:
        for split in ("val", "test"):
            for line in (im2latex / f"{split}.txt").read_text(encoding="utf-8").splitlines():
                if "\t" in line:
                    keys[key(line.split("\t", 1)[1])] = f"im2latex {split}"
    registry = ROOT / "splits" / "frozen_eval.jsonl"
    if registry.exists():
        for line in registry.read_text(encoding="utf-8").splitlines():
            entry = json.loads(line) if line.strip() else {}
            if entry.get("key", "").startswith("formula:"):
                keys[key(entry["key"][len("formula:"):])] = "frozen eval registry"
    return keys


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", required=True)
    parser.add_argument("--per-topic", type=int, default=300)
    parser.add_argument("--workers", type=int, default=8)
    parser.add_argument("--seed", type=int, default=2026)
    parser.add_argument("--im2latex", default=str(ROOT / "data" / "public" / "im2latex_algebra_lf"),
                        help="prepare_im2latex.py output; its val and test formulas are never generated")
    args = parser.parse_args()

    out = Path(args.out)
    if out.exists() and any(out.iterdir()):
        raise SystemExit(f"{out} is not empty")
    (out / "images").mkdir(parents=True, exist_ok=True)
    held = held_out_keys(Path(args.im2latex) if args.im2latex else None)
    print(f"leak guard: {len(held)} held-out formulas "
          f"({'with' if (ROOT / 'splits' / 'frozen_eval.jsonl').exists() else 'no'} frozen eval registry)")

    r = random.Random(args.seed)
    jobs, seen, drops = [], set(), {t: {"duplicate": 0, "held-out formula": 0} for t in TOPICS}
    for topic in TOPICS:
        made, tries = 0, 0
        while made < args.per_topic and tries < args.per_topic * 200:
            tries += 1
            latex = TEMPLATES[topic](r)
            k = key(latex)
            if k in held:
                drops[topic]["held-out formula"] += 1
                continue
            if k in seen:
                drops[topic]["duplicate"] += 1
                continue
            seen.add(k)
            jobs.append((len(jobs), topic, latex, r.randrange(1 << 30), str(out)))
            made += 1
    start = time.time()
    with Pool(args.workers, initializer=_init_worker) as pool:
        rows = pool.map(render_one, jobs, chunksize=8)
    seconds = time.time() - start

    with open(out / "train.txt", "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(f"{row['image']}\t{row['label']}" for row in rows) + "\n")
    with open(out / "manifest.jsonl", "w", encoding="utf-8", newline="\n") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    per_topic = {t: sum(1 for row in rows if row["topic"] == t) for t in TOPICS}
    styles = {s: sum(1 for row in rows if row["style"] == s) for s in STYLES}
    clean = sum(1 for row in rows if row["augment"] == "none (clean)")
    lines = ["# Synthetic algebra formulas (training only)", "",
             f"- Generated {len(rows)} images in {seconds:.0f} s with {args.workers} processes "
             f"({len(rows) / seconds:.1f} images/s); seed {args.seed}.",
             f"- Leak guard: {len(held)} held-out formulas (im2latex val/test"
             f"{', frozen eval registry' if (ROOT / 'splits' / 'frozen_eval.jsonl').exists() else '; no frozen eval registry yet'}).",
             f"- Clean (no photo effects): {clean}; with photo effects (formula_effects): {len(rows) - clean}.", "",
             "| topic | images | dropped: duplicate | dropped: held-out formula |", "|---|---|---|---|"]
    lines += [f"| {t} | {per_topic[t]} | {drops[t]['duplicate']} | {drops[t]['held-out formula']} |" for t in TOPICS]
    lines += ["", "| font style | images |", "|---|---|"] + [f"| {s} | {c} |" for s, c in styles.items()]
    lines += ["", "Training only: there is no val or test file. Labels are exactly what is drawn (mathtext layout, "
              "not LaTeX; simulated photo effects, not phone photos)."]
    (out / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
