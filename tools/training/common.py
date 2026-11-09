"""Shared paths, charset, label/manifest files and the eval/training guard.

Data never goes into git. It lives under the training root (layout of
2026-11-10; every tool takes its paths from Layout below):

    <root>/datasets/public/im2latex-100k/raw/                       the published Parquet files
    <root>/datasets/public/im2latex-100k/filtered_general_algebra/  prepare_im2latex.py output
    <root>/datasets/public/paddleocr_formula_demo/                  PaddleOCR's formula demo set
    <root>/datasets/own/incoming/  intake/  splits/ (frozen_eval.jsonl)   our dataset
    <root>/datasets/own/text_lines/train_val/  eval/                Track B real photo lines
    <root>/datasets/own/photo_pairs_review/                         crops not paired confidently
    <root>/datasets/synthetic/text_lines/train_val/  eval/  manifests/   Track B synthetic lines
    <root>/datasets/synthetic/worksheets/                           printable worksheets (known lines)
    <root>/datasets/synthetic/formulas_pilot_20261109/              Track A synthetic formulas
    <root>/models/pretrained/                                       official checkpoints and models
    <root>/resources/fonts/                                         open fonts + licences (FONTS.md)
    <root>/runs/<date>-<time>_<track>_<data>_<purpose>/             one training run each:
        run.json, summary.md, config/, logs/, charts/, best_checkpoint/,
        checkpoints/ (others, if kept), onnx/, evaluation/
    <root>/evaluations/<track>/...                                  scores not tied to a run
    <root>/reports/                                                 write-ups and panel pages

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

    # ---- top level
    @property
    def datasets(self) -> Path:
        return self.root / "datasets"

    @property
    def fonts(self) -> Path:
        return self.root / "resources" / "fonts"

    @property
    def pretrained(self) -> Path:
        return self.root / "models" / "pretrained"

    @property
    def runs(self) -> Path:
        return self.root / "runs"

    @property
    def reports(self) -> Path:
        return self.root / "reports"

    def evaluations(self, track: str) -> Path:
        """track: trackA_formula, trackB_recognizer, trackC_vl."""
        return self.root / "evaluations" / track

    def run_dir(self, track: str, data: str, purpose: str, when: str | None = None) -> Path:
        """runs/<date>-<time>_<track>_<data>_<purpose> (track: trackA, trackB, trackC)."""
        import datetime as _dt
        import re as _re

        when = when or _dt.datetime.now().strftime("%Y%m%d-%H%M%S")
        clean = lambda s: _re.sub(r"[^A-Za-z0-9+-]+", "-", s).strip("-")  # noqa: E731
        return self.runs / f"{when}_{track}_{clean(data)}_{clean(purpose)}"

    # ---- datasets
    @property
    def im2latex_raw(self) -> Path:
        return self.datasets / "public" / "im2latex-100k" / "raw"

    @property
    def im2latex_filtered(self) -> Path:
        return self.datasets / "public" / "im2latex-100k" / "filtered_general_algebra"

    @property
    def formula_demo(self) -> Path:
        return self.datasets / "public" / "paddleocr_formula_demo"

    @property
    def synthetic_formulas(self) -> Path:
        return self.datasets / "synthetic" / "formulas_pilot_20261109"

    @property
    def incoming(self) -> Path:
        return self.datasets / "own" / "incoming"

    @property
    def intake(self) -> Path:
        return self.datasets / "own" / "intake"

    @property
    def splits(self) -> Path:
        return self.datasets / "own" / "splits"

    @property
    def registry(self) -> Path:
        """The frozen eval registry: every item ever held out for evaluation."""
        return self.splits / "frozen_eval.jsonl"

    def set_dir(self, name: str) -> Path:
        """name: synthetic-train, synthetic-val, synthetic-eval, real-train, real-eval."""
        synthetic = self.datasets / "synthetic" / "text_lines"
        own = self.datasets / "own" / "text_lines"
        return {
            "synthetic-train": synthetic / "train_val",
            "synthetic-val": synthetic / "train_val",
            "synthetic-eval": synthetic / "eval",
            "real-train": own / "train_val",
            "real-val": own / "train_val",
            "real-eval": own / "eval",
        }[name]

    def label_file(self, name: str) -> Path:
        return self.set_dir(name) / {
            "synthetic-train": "train.txt",
            "synthetic-val": "val.txt",
            "synthetic-eval": "labels.txt",
            "real-train": "train.txt",
            "real-val": "val.txt",
            "real-eval": "labels.txt",
        }[name]

    def manifest(self, name: str) -> Path:
        """synthetic-* manifests with the synthetic lines; others (pairing runs) with our own lines."""
        base = self.datasets / "synthetic" / "text_lines" if name.startswith("synthetic") else self.datasets / "own" / "text_lines"
        return base / "manifests" / f"{name}.jsonl"

    @property
    def worksheets(self) -> Path:
        return self.datasets / "synthetic" / "worksheets"

    @property
    def review(self) -> Path:
        return self.datasets / "own" / "photo_pairs_review"

    def make_dirs(self) -> None:
        for name in ("synthetic-train", "synthetic-eval", "real-train", "real-eval"):
            (self.set_dir(name) / "images").mkdir(parents=True, exist_ok=True)
        for path in (self.manifest("synthetic").parent, self.worksheets, self.review, self.runs):
            path.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------- run folders

ROOT_FILES = {"run.json", "summary.md", "comparison.md", "comparison.json", "comparison.csv", "results.json",
              "results.md", "README.md"}
LIST_FILES = {"train_list.txt", "val_list.txt", "train_subset.txt", "val_subset.txt", "extra_train.txt"}
CHART_DATA = {"loss_curve.csv", "validation_history.csv"}


def tidy_target(rel: str) -> str:
    """Where a file of a finished run belongs (relative path in, relative path out).

    run.json / summary.md / comparison.* / results.* stay at the top;
    *.log and gpu_memory.csv -> logs/; *.yml and train/val lists -> config/;
    *.png and the chart CSVs -> charts/; best_accuracy.* -> best_checkpoint/;
    other checkpoints -> checkpoints/; ONNX and the static export -> onnx/;
    eval/ -> evaluation/. Anything else stays where it is.
    """
    parts = rel.replace("\\", "/").split("/")
    name, folder = parts[-1], parts[0] if len(parts) > 1 else ""
    flat = "_".join(parts)
    if folder in ("config", "logs", "charts", "best_checkpoint", "checkpoints", "onnx", "evaluation"):
        return rel  # already in place
    if len(parts) == 1 and name in ROOT_FILES:
        return rel
    if folder in ("eval",):
        return "/".join(["evaluation"] + parts[1:])
    if folder == "export" and len(parts) > 2 and parts[1] == "onnx":
        return "/".join(["onnx"] + parts[2:])
    if folder == "export" and len(parts) > 2 and parts[1] == "infer":
        return "/".join(["onnx", "paddle_static"] + parts[2:])
    if folder == "infer":
        return "/".join(["onnx", "paddle_static"] + parts[1:])
    if name.endswith(".onnx"):
        return f"onnx/{name}"
    if name == "onnx_check.json":
        return "onnx/onnx_check.json"
    if name.endswith(".log") or name == "gpu_memory.csv":
        return f"logs/{flat}"
    if name.endswith((".yml", ".yaml")) or name in LIST_FILES:
        return f"config/{flat}"
    if name.endswith(".png") or name in CHART_DATA:
        return f"charts/{name}"
    if folder.startswith("model") and name.startswith("best_accuracy."):
        return f"best_checkpoint/{name}"
    if folder.startswith("model") and name.endswith((".pdparams", ".pdopt", ".states")):
        return "/".join(["checkpoints"] + parts[1:])
    return rel


def tidy_run(run_dir: Path, apply: bool = True) -> list[tuple[str, str]]:
    """Sort a finished run into config/ logs/ charts/ best_checkpoint/
    checkpoints/ onnx/ evaluation/ (tidy_target). Returns the moves made
    (relative paths); with apply=False only lists them. Empty folders left
    behind are removed. Path strings inside the run's own JSON / Markdown /
    list files are rewritten to the new places (rewrite_paths)."""
    import shutil

    moves = []
    for path in sorted(p for p in run_dir.rglob("*") if p.is_file()):
        rel = path.relative_to(run_dir).as_posix()
        target = tidy_target(rel)
        if target != rel:
            moves.append((rel, target))
    if apply:
        for rel, target in moves:
            dst = run_dir / target
            if dst.exists():
                raise FileExistsError(f"{dst} exists; not moving {rel}")
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(run_dir / rel), str(dst))
        for folder in sorted((p for p in run_dir.rglob("*") if p.is_dir()), key=lambda p: -len(p.parts)):
            if not any(folder.iterdir()):
                folder.rmdir()
        rewrite_paths(run_dir, run_internal_mapping(run_dir, moves))
    return moves


FOLDER_MOVES = (("eval", "evaluation"), ("export/onnx", "onnx"), ("export/infer", "onnx/paddle_static"),
                ("infer", "onnx/paddle_static"), ("model/best_accuracy", "best_checkpoint/best_accuracy"))


def run_internal_mapping(run_dir: Path, moves: list[tuple[str, str]] | None = None) -> list[tuple[Path, Path]]:
    """Old -> new absolute paths inside one sorted run: the files moved, the
    checkpoint name without extension ("...\\model\\best_accuracy") and the
    folders that moved as a whole. Without moves (a run sorted earlier),
    only the folder and checkpoint mappings."""
    mapping = [(run_dir / a, run_dir / b) for a, b in (moves or [])]
    mapping += [((run_dir / a).with_suffix(""), (run_dir / b).with_suffix(""))
                for a, b in (moves or []) if a.endswith(".pdparams")]
    mapping += [(run_dir / old, run_dir / new) for old, new in FOLDER_MOVES]
    if moves is None:
        # A run sorted earlier: rebuild "old place -> new place" from where
        # each sorted file is now. Old places were the run's top level or a
        # model*/ folder (flattened as model_<...>); names that still exist
        # at the top level are left alone.
        top = {p.name for p in run_dir.iterdir() if p.is_file()}
        for folder in ("logs", "config", "charts", "onnx", "best_checkpoint", "checkpoints"):
            for path in (run_dir / folder).glob("*") if (run_dir / folder).is_dir() else []:
                if not path.is_file() or path.name in top or path.name in ROOT_FILES:
                    continue
                candidates = [path.name] if folder not in ("best_checkpoint", "checkpoints") else []
                if folder in ("best_checkpoint", "checkpoints"):
                    candidates.append(f"model/{path.name}")
                if path.name.startswith("model_") and folder in ("logs", "config"):
                    rest = path.name[len("model_"):]
                    head, _, tail = rest.partition("_")
                    candidates.append(f"model/{rest}")
                    if head.startswith("bs") and tail:
                        candidates.append(f"model_{head}/{tail}")
                for old in candidates:
                    if tidy_target(old) == f"{folder}/{path.name}":
                        mapping.append((run_dir / old, path))
    return mapping


TEXT_SUFFIXES = (".json", ".md", ".txt", ".csv")


def rewrite_paths(folder: Path, mapping: list[tuple[Path, Path]]) -> int:
    """Replace old absolute paths by new ones in the JSON / Markdown / list
    files under folder (not in logs: those stay as they were written).
    Handles plain Windows paths, JSON-escaped ones and forward slashes.
    Longest paths first, so a file's own path wins over its folder's. A
    path only matches as a whole name: "...\\eval" never touches
    "...\\evaluation"."""
    import re

    pairs = []
    for old, new in sorted(mapping, key=lambda m: -len(str(m[0]))):
        o, n = str(old), str(new)
        for a, b in ((o, n), (o.replace("\\", "\\\\"), n.replace("\\", "\\\\")), (o.replace("\\", "/"), n.replace("\\", "/"))):
            pairs.append((re.compile(re.escape(a) + r"(?=[\\/\"'`\s,;:)\]}|]|$)"), b))
    changed = 0
    for path in folder.rglob("*"):
        if not path.is_file() or path.suffix not in TEXT_SUFFIXES or "logs" in path.relative_to(folder).parts:
            continue
        text = path.read_text(encoding="utf-8", errors="strict")
        new_text = text
        for pattern, n in pairs:
            new_text = pattern.sub(lambda _m, n=n: n, new_text)
        if new_text != text:
            with open(path, "w", encoding="utf-8", newline="") as handle:
                handle.write(new_text)
            changed += 1
    return changed


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

# real-val (photos of some training sheets, used to pick checkpoints) is on
# the training side: it must never share an image or a sheet with eval.
TRAINING_SETS = ("synthetic-train", "synthetic-val", "real-train", "real-val")
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
