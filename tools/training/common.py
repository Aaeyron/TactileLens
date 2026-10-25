"""Shared paths, charset, label/manifest files and the eval/training guard.

Data never goes into git. It lives under the training root:

    <root>/fonts/                 open fonts + licences (FONTS.md)
    <root>/data/synthetic/        images/ + train.txt, val.txt
    <root>/data/real/             images/ + train.txt
    <root>/eval/synthetic/        images/ + labels.txt
    <root>/eval/real/             images/ + labels.txt  (held out, never trained on)
    <root>/worksheets/            printable PDFs + <sheet>.json (known lines)
    <root>/review/                crops that could not be paired confidently
    <root>/manifests/<set>.jsonl  one row per image
    <root>/outputs/               baseline and later results

The root is --root, else the TL_TRAIN_ROOT environment variable, else
C:\\Projects\\Capstone\\tactilelens-training. Every path written into a
label file or manifest is relative and ASCII, so the folder can be
copied to Google Drive or Colab as is.
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator

DEFAULT_ROOT = Path(r"C:\Projects\Capstone\tactilelens-training")

# Labels contain superscripts and math signs; print them as UTF-8.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

REPO = Path(__file__).resolve().parents[2]
ASSETS = REPO / "frontend" / "android" / "app" / "src" / "main" / "assets" / "paddle_onnx"
DET_MODEL = ASSETS / "PP-OCRv6-tiny-det-onnx" / "inference.onnx"
REC_MODEL = ASSETS / "PP-OCRv6-small-rec-onnx" / "inference.onnx"
REC_CONFIG = ASSETS / "PP-OCRv6-small-rec-onnx" / "inference.yml"

# Superscripts the recognizer's dictionary has (checked with charset.py):
# digits, + - = ( ) and n. Exponents in labels use only these.
SUPERSCRIPT = {
    "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
    "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
    "+": "⁺", "-": "⁻", "−": "⁻", "=": "⁼", "(": "⁽", ")": "⁾", "n": "ⁿ",
}
SUPERSCRIPT_CHARS = frozenset("⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿ")
PLAIN_OF_SUPERSCRIPT = {
    "⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4", "⁵": "5", "⁶": "6",
    "⁷": "7", "⁸": "8", "⁹": "9", "⁺": "+", "⁻": "-", "⁼": "=", "⁽": "(",
    "⁾": ")", "ⁿ": "n",
}


def root_dir(cli_root: str | None = None) -> Path:
    if cli_root:
        return Path(cli_root)
    env = os.environ.get("TL_TRAIN_ROOT")
    return Path(env) if env else DEFAULT_ROOT


@dataclass(frozen=True)
class Layout:
    root: Path

    @property
    def fonts(self) -> Path:
        return self.root / "fonts"

    def set_dir(self, name: str) -> Path:
        """name: synthetic-train, synthetic-val, synthetic-eval, real-train, real-eval."""
        return {
            "synthetic-train": self.root / "data" / "synthetic",
            "synthetic-val": self.root / "data" / "synthetic",
            "synthetic-eval": self.root / "eval" / "synthetic",
            "real-train": self.root / "data" / "real",
            "real-eval": self.root / "eval" / "real",
        }[name]

    def label_file(self, name: str) -> Path:
        return self.set_dir(name) / {
            "synthetic-train": "train.txt",
            "synthetic-val": "val.txt",
            "synthetic-eval": "labels.txt",
            "real-train": "train.txt",
            "real-eval": "labels.txt",
        }[name]

    def manifest(self, name: str) -> Path:
        return self.root / "manifests" / f"{name}.jsonl"

    @property
    def worksheets(self) -> Path:
        return self.root / "worksheets"

    @property
    def review(self) -> Path:
        return self.root / "review"

    @property
    def outputs(self) -> Path:
        return self.root / "outputs"

    def make_dirs(self) -> None:
        for name in ("synthetic-train", "synthetic-eval", "real-train", "real-eval"):
            (self.set_dir(name) / "images").mkdir(parents=True, exist_ok=True)
        for path in (self.root / "manifests", self.worksheets, self.review, self.outputs):
            path.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------- charset


def load_character_list(config_path: Path = REC_CONFIG) -> list[str]:
    """The recognizer's characters, exactly as ppocr-sdk ModelConfig.kt
    builds them: PostProcess.character_dict entries, then " " appended
    if the last entry is not already a space."""

    lines = config_path.read_text(encoding="utf-8").split("\n")

    def indent(line: str) -> int:
        return len(line) - len(line.lstrip(" "))

    post = next(i for i, line in enumerate(lines) if line.strip() == "PostProcess:")
    start = None
    for i in range(post + 1, len(lines)):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith("#"):
            continue
        if indent(lines[i]) <= indent(lines[post]):
            break
        if stripped == "character_dict:":
            start = i
            break
    if start is None:
        raise ValueError(f"No character_dict in {config_path}")

    characters = []
    for line in lines[start + 1 :]:
        content = line[indent(line) :]
        if not content.strip() or content.strip().startswith("#"):
            continue
        if not content.startswith("-"):
            if indent(line) <= indent(lines[start]):
                break
            continue
        value = content[1:].lstrip(" ")
        if len(value) >= 2 and value[0] == "'" and value[-1] == "'":
            value = value[1:-1].replace("''", "'")
        characters.append(value)

    if characters[-1] != " ":
        characters.append(" ")
    return characters


def unsupported_characters(text: str, characters: Iterable[str]) -> set[str]:
    allowed = set(characters)
    return {c for c in text if c not in allowed}


# ---------------------------------------------------------------- files


def sha256_of(path: Path, length: int | None = None) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    value = digest.hexdigest()
    return value[:length] if length else value


def write_labels(path: Path, rows: Iterable[tuple[str, str]]) -> None:
    """PaddleOCR recognizer label file: relative image path, tab, text."""

    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        for image, text in rows:
            if "\t" in text or "\n" in text:
                raise ValueError(f"Label for {image} contains a tab or newline")
            handle.write(f"{image}\t{text}\n")


def read_labels(path: Path) -> list[tuple[str, str]]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            image, text = line.split("\t", 1)
            rows.append((image, text))
    return rows


def write_manifest(path: Path, rows: Iterable[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")


def append_manifest(path: Path, rows: Iterable[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "a", encoding="utf-8", newline="\n") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")


def read_manifest(path: Path) -> Iterator[dict]:
    if not path.exists():
        return iter(())
    return (json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip())


# ---------------------------------------------------------------- guard

TRAINING_SETS = ("synthetic-train", "synthetic-val", "real-train")
EVAL_SETS = ("synthetic-eval", "real-eval")


class EvalLeakError(RuntimeError):
    pass


def check_no_eval_in_training(layout: Layout) -> None:
    """Refuse to continue if any eval image, or any photographed sheet used
    for eval, also appears in a training list."""

    def images_of(names):
        found = {}
        for name in names:
            base = layout.set_dir(name)
            for image, _ in read_labels(layout.label_file(name)):
                found[(base / image).resolve()] = name
        return found

    def sheets_of(names):
        sheets = set()
        for name in names:
            for row in read_manifest(layout.manifest(name)):
                if row.get("sheet"):
                    sheets.add(row["sheet"])
        return sheets

    eval_images = images_of(EVAL_SETS)
    train_images = images_of(TRAINING_SETS)
    shared = set(eval_images) & set(train_images)
    if shared:
        raise EvalLeakError(f"{len(shared)} eval image(s) also in training lists, e.g. {next(iter(shared))}")

    shared_sheets = sheets_of(EVAL_SETS) & sheets_of(TRAINING_SETS)
    if shared_sheets:
        raise EvalLeakError(f"Worksheet(s) used for both eval and training: {sorted(shared_sheets)}")


# ---------------------------------------------------------------- text


def loosen(text: str) -> str:
    """For comparing a reading with a label when superscripts may have been
    read as plain characters: superscripts to plain, any minus to "-",
    spaces removed."""

    plain = "".join(PLAIN_OF_SUPERSCRIPT.get(c, c) for c in text)
    return plain.replace("−", "-").replace(" ", "")


def edit_distance(a: str, b: str) -> int:
    if len(a) < len(b):
        a, b = b, a
    previous = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        current = [i]
        for j, cb in enumerate(b, 1):
            current.append(min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (ca != cb)))
        previous = current
    return previous[-1]
