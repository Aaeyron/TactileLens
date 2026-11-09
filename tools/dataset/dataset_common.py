"""Shared code for the dataset intake and split tools.

Plain Python + Pillow (any of our environments). Reuses the VL tools'
naming, LaTeX and OTSL checks (tools/training_vl/vl_common.py) and the
recognizer's charset and eval sets (tools/training/common.py).

Nothing here changes the app, and no data goes into git: everything is
read from and written under the training root
(C:\\Projects\\Capstone\\tactilelens-training, --root or TL_TRAIN_ROOT).
"""

from __future__ import annotations

import csv
import json
import re
import sys
import unicodedata
from pathlib import Path

from PIL import Image, ImageOps

HERE = Path(__file__).resolve().parent
TOOLS = HERE.parent
sys.path.insert(0, str(TOOLS / "training_vl"))
sys.path.insert(0, str(TOOLS / "training"))

import common as rec_common  # noqa: E402  (tools/training)
import vl_common  # noqa: E402  (tools/training_vl)

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ITEM_FIELDS = [
    "filename", "relpath", "topic", "source", "kind", "number", "task", "target",
    "split_given", "sha256", "dhash", "width", "height", "group",
    "errors", "warnings", "flags",
]

# ---------------------------------------------------------------- images


HASH_SIZE = 16  # 16 x 16 = 256 bits


def dhash(path: Path, size: int = HASH_SIZE) -> str:
    """Difference hash of the upright grayscale image, followed by
    ":<aspect ratio>". Equal or close hashes mean the same picture, even
    re-saved, slightly resized or recompressed. Not for telling a photo
    from a screenshot of the same page (those differ too much); that is
    done with the labels."""

    with Image.open(path) as image:
        upright = ImageOps.exif_transpose(image)
        aspect = upright.width / max(upright.height, 1)
        gray = upright.convert("L").resize((size + 1, size), Image.Resampling.LANCZOS)
        pixels = gray.tobytes()  # one byte per pixel, row by row
    bits = 0
    for row in range(size):
        for col in range(size):
            left = pixels[row * (size + 1) + col]
            right = pixels[row * (size + 1) + col + 1]
            bits = (bits << 1) | (left > right)
    return f"{bits:0{size * size // 4}x}:{aspect:.3f}"


def _split(value: str) -> tuple[int, float]:
    bits, _, aspect = value.partition(":")
    return int(bits, 16), float(aspect or 0)


def hamming(a: str, b: str) -> int:
    return (_split(a)[0] ^ _split(b)[0]).bit_count()


# Measured on the fake dry run (generated text strips, 256-bit hash):
# byte copies 0 bits, a resized JPEG re-save 5 bits; different formulas of
# similar length 21 bits and more. 12 sits in that gap. Not measured on
# real photos yet: check the near-duplicate list of the first real intake.
NEAR_DUPLICATE_BITS = 12
# Aspect ratios further apart than this are never near-duplicates.
NEAR_DUPLICATE_ASPECT = 0.15


def is_near_duplicate(a: str, b: str, limit: int = NEAR_DUPLICATE_BITS) -> bool:
    (bits_a, aspect_a), (bits_b, aspect_b) = _split(a), _split(b)
    if aspect_a and aspect_b and abs(aspect_a - aspect_b) / max(aspect_a, aspect_b) > NEAR_DUPLICATE_ASPECT:
        return False
    return (bits_a ^ bits_b).bit_count() <= limit


def near_duplicate_pairs(hashes: dict[str, str], limit: int = NEAR_DUPLICATE_BITS) -> list[tuple[str, str, int]]:
    """Pairs of keys that are near-duplicates (see is_near_duplicate).
    The 256 bits are split into 32 bands of 8: two hashes within 31 bits
    share at least one band, so only those are compared."""

    bands: dict[tuple[int, str], list[str]] = {}
    for key, value in hashes.items():
        if not value:
            continue
        hexbits = value.partition(":")[0]
        for band in range(len(hexbits) // 2):
            bands.setdefault((band, hexbits[band * 2 : band * 2 + 2]), []).append(key)
    pairs = set()
    for keys in bands.values():
        if len(keys) < 2:
            continue
        for i, a in enumerate(keys):
            for b in keys[i + 1 :]:
                if a != b and is_near_duplicate(hashes[a], hashes[b], limit):
                    pairs.add((min(a, b), max(a, b), hamming(hashes[a], hashes[b])))
    return sorted(pairs)


def exif_flags(path: Path) -> list[str]:
    """Personal data in the photo's metadata."""

    flags = []
    try:
        with Image.open(path) as image:
            exif = image.getexif()
            if exif.get_ifd(0x8825):
                flags.append("photo has GPS location in EXIF")
            if exif.get(0x9286) or exif.get(0x013B) or exif.get(0x8298):
                flags.append("EXIF has a comment, artist or copyright field")
    except Exception:  # noqa: BLE001
        pass
    return flags


# ---------------------------------------------------------------- labels

_PERSONAL = [
    (re.compile(r"[\w.+-]+@[\w-]+\.[\w.]+"), "email address"),
    (re.compile(r"(?<!\d)(?:\+?63|0)9\d{2}[\s-]?\d{3}[\s-]?\d{4}(?!\d)"), "phone number"),
    (re.compile(r"\b(?:name|student|section|grade\s*&\s*section|teacher|lrn|score)\s*:", re.I), "form field for a person (Name:, Section:, LRN: ...)"),
    (re.compile(r"\b(?:Mr|Ms|Mrs|Dr|Sir|Ma'am)\.?\s+[A-Z][a-z]+"), "a person's name"),
]
_THIRD_PARTY = [
    (re.compile(r"©|\(c\)\s*\d{4}|copyright|all rights reserved", re.I), "copyright notice"),
    (re.compile(r"\bISBN\b", re.I), "ISBN"),
    (re.compile(r"\b(?:pearson|mcgraw|cengage|rex book|vibal|diwa|phoenix publishing|sibs|deped|self-learning module|quarter\s*\d+\s*[-–]\s*module)\b", re.I), "publisher or module name"),
    (re.compile(r"\bpage\s+\d+\b|\bp\.\s*\d+\b", re.I), "page number (a page from a book?)"),
]
# Never in fixtures or data (owner's rule): the textbook page 04 sample.
_FORBIDDEN_NAMES = [(re.compile(r"04_dense", re.I), "textbook page 04 sample (not allowed in the dataset)")]


def text_flags(filename: str, target: str) -> list[str]:
    flags = [f"personal data? {why}" for pattern, why in _PERSONAL if pattern.search(target or "")]
    flags += [f"third-party material? {why}" for pattern, why in _THIRD_PARTY if pattern.search(target or "")]
    flags += [why for pattern, why in _FORBIDDEN_NAMES if pattern.search(filename)]
    return flags


def normalize_target(task: str, target: str) -> str:
    """Key for "is this the same item?": the compare form the VL evaluator
    uses, case-folded, NFKC (so x² and x^2 typed differently still differ,
    but spacing and delimiters do not matter)."""

    return unicodedata.normalize("NFKC", vl_common.normalize_for_compare(task, target or "")).casefold()


_recognizer_chars: set[str] | None = None


def recognizer_unsupported(text: str) -> set[str]:
    global _recognizer_chars
    if _recognizer_chars is None:
        _recognizer_chars = set(rec_common.load_character_list())
    return {c for c in text if c not in _recognizer_chars and c not in "\n"}


# ---------------------------------------------------------------- groups


class UnionFind:
    def __init__(self) -> None:
        self.parent: dict[str, str] = {}

    def find(self, key: str) -> str:
        self.parent.setdefault(key, key)
        while self.parent[key] != key:
            self.parent[key] = self.parent[self.parent[key]]
            key = self.parent[key]
        return key

    def union(self, a: str, b: str) -> None:
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[max(ra, rb)] = min(ra, rb)


# ---------------------------------------------------------------- files


def write_items(path: Path, items: list[dict]) -> None:
    with open(path, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=ITEM_FIELDS)
        writer.writeheader()
        for item in items:
            row = dict(item)
            for key in ("errors", "warnings", "flags"):
                row[key] = " | ".join(item.get(key) or [])
            writer.writerow({k: row.get(k, "") for k in ITEM_FIELDS})


def read_items(path: Path) -> list[dict]:
    with open(path, encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    for row in rows:
        for key in ("errors", "warnings", "flags"):
            row[key] = [part for part in (row.get(key) or "").split(" | ") if part]
    return rows


def write_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")


# ---------------------------------------------------------------- eval sets


def existing_eval_images(root: Path, registry: Path | None = None) -> dict[str, dict]:
    """Every image already used for evaluation, by sha256: the recognizer's
    eval sets (eval/real, eval/synthetic) and every dataset item ever put in
    a held-out eval split (the frozen-eval registry). Values: where it is
    from, its dhash and (registry) its normalized target."""

    found: dict[str, dict] = {}
    layout = rec_common.Layout(root)
    for name in rec_common.EVAL_SETS:
        base = layout.set_dir(name)
        for image, label in rec_common.read_labels(layout.label_file(name)):
            path = base / image
            if path.exists():
                found[vl_common.sha256_file(path)] = {"from": name, "dhash": dhash(path), "key": ""}
    for row in read_registry(registry or registry_path(root)):
        found.setdefault(row["sha256"], {"from": f"frozen eval ({row['split_id']})", "dhash": row["dhash"], "key": row["key"]})
    return found


def registry_path(root: Path) -> Path:
    return rec_common.Layout(root).registry


def read_registry(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
