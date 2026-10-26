"""Shared code for the PaddleOCR-VL tools: config, filenames, validation,
LaTeX/OTSL checks, HTML->OTSL, metrics and the eval/train leak guard.

Plain Python + Pillow; no Paddle needed.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
import sys
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
DEFAULT_CONFIG = HERE / "config.json"

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


# ---------------------------------------------------------------- config


def load_config(path: Path = DEFAULT_CONFIG) -> dict:
    config = json.loads(Path(path).read_text(encoding="utf-8"))
    sources = "|".join(map(re.escape, config["sources"]))
    kinds = "|".join(map(re.escape, config["kinds"]))
    extensions = "|".join(re.escape(e.lstrip(".")) for e in config["image_extensions"])
    # topic may itself contain underscores ("negative_exponents").
    config["_filename_re"] = re.compile(
        rf"^(?P<topic>[A-Za-z0-9]+(?:_[A-Za-z0-9]+)*?)_(?P<source>{sources})_(?P<kind>{kinds})_(?P<number>\d+)\.(?:{extensions})$",
        re.IGNORECASE,
    )
    return config


@dataclass
class Item:
    filename: str
    task: str
    target: str
    split: str
    topic: str = ""
    source: str = ""
    kind: str = ""
    number: str = ""
    path: Path | None = None
    sha256: str = ""
    size: tuple[int, int] | None = None
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


def parse_filename(name: str, config: dict) -> dict | None:
    match = config["_filename_re"].match(name)
    if not match:
        return None
    parts = match.groupdict()
    parts["source"] = parts["source"].lower()
    parts["kind"] = parts["kind"].upper()
    return parts


def read_labels_csv(path: Path) -> list[dict]:
    with open(path, encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        missing = {"filename", "task", "target", "split"} - set(reader.fieldnames or [])
        if missing:
            raise ValueError(f"{path}: missing columns {sorted(missing)} (need filename,task,target,split)")
        return [row for row in reader if any((v or "").strip() for v in row.values())]


def index_images(root: Path, config: dict) -> dict[str, list[Path]]:
    found: dict[str, list[Path]] = {}
    extensions = {e.lower() for e in config["image_extensions"]}
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in extensions:
            found.setdefault(path.name, []).append(path)
    return found


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


# ---------------------------------------------------------------- LaTeX / OTSL

OTSL_TOKENS = ("<fcel>", "<ecel>", "<lcel>", "<ucel>", "<xcel>", "<nl>")
_OTSL_TOKEN = re.compile(r"<[a-z]+>")
_DELIMITERS = re.compile(r"^\s*(?:\$\$|\$|\\\[|\\\()\s*|\s*(?:\$\$|\$|\\\]|\\\))\s*$")


def strip_math_delimiters(latex: str) -> str:
    previous = None
    text = latex.strip()
    while previous != text:
        previous = text
        text = _DELIMITERS.sub("", text).strip()
    return text


def latex_problems(latex: str) -> list[str]:
    problems = []
    body = strip_math_delimiters(latex)
    if not body:
        return ["empty formula"]
    depth = 0
    i = 0
    while i < len(body):
        c = body[i]
        if c == "\\":
            i += 2
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth < 0:
                problems.append("unbalanced braces: '}' without '{'")
                break
        i += 1
    if depth > 0:
        problems.append(f"unbalanced braces: {depth} '{{' not closed")
    left, right = len(re.findall(r"\\left(?![A-Za-z])", body)), len(re.findall(r"\\right(?![A-Za-z])", body))
    if left != right:
        problems.append(f"\\left x{left} vs \\right x{right}")
    begins = re.findall(r"\\begin\{([^}]*)\}", body)
    ends = re.findall(r"\\end\{([^}]*)\}", body)
    if sorted(begins) != sorted(ends):
        problems.append(f"\\begin/\\end mismatch: {begins} vs {ends}")
    return problems


def otsl_rows(otsl: str) -> list[list[str]]:
    """[["fcel", ...], ...] with the cell texts dropped."""

    rows, current = [], []
    for token in _OTSL_TOKEN.findall(otsl):
        name = token[1:-1]
        if name == "nl":
            rows.append(current)
            current = []
        else:
            current.append(name)
    if current:
        rows.append(current)
    return rows


def otsl_problems(otsl: str) -> list[str]:
    problems = []
    tokens = _OTSL_TOKEN.findall(otsl)
    if not tokens:
        return ["no OTSL tokens"]
    unknown = sorted({t for t in tokens if t not in OTSL_TOKENS})
    if unknown:
        problems.append(f"unknown OTSL tokens: {unknown}")
    if not otsl.rstrip().endswith("<nl>"):
        problems.append("table does not end with <nl>")
    widths = {len(row) for row in otsl_rows(otsl)}
    if len(widths) > 1:
        problems.append(f"rows have different numbers of cells: {sorted(widths)}")
    return problems


class _TableParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.rows: list[list[dict]] = []
        self._cell: dict | None = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "tr":
            self.rows.append([])
        elif tag in ("td", "th"):
            if not self.rows:
                self.rows.append([])
            self._cell = {
                "text": "",
                "colspan": int(attrs.get("colspan") or 1),
                "rowspan": int(attrs.get("rowspan") or 1),
            }

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self._cell is not None:
            self.rows[-1].append(self._cell)
            self._cell = None

    def handle_data(self, data):
        if self._cell is not None:
            self._cell["text"] += data


def html_table_to_otsl(html: str) -> str:
    """HTML <table> (as both engines return tables) to OTSL, so it can be
    compared with OTSL labels. Spans become lcel (left), ucel (up), xcel."""

    parser = _TableParser()
    parser.feed(html)
    grid: dict[tuple[int, int], str] = {}
    for r, row in enumerate(parser.rows):
        c = 0
        for cell in row:
            while (r, c) in grid:
                c += 1
            text = " ".join(cell["text"].split())
            for dr in range(cell["rowspan"]):
                for dc in range(cell["colspan"]):
                    if dr == 0 and dc == 0:
                        token = f"<fcel>{text}" if text else "<ecel>"
                    elif dr == 0:
                        token = "<lcel>"
                    elif dc == 0:
                        token = "<ucel>"
                    else:
                        token = "<xcel>"
                    grid[(r + dr, c + dc)] = token
            c += cell["colspan"]
    if not grid:
        return ""
    rows = max(r for r, _ in grid) + 1
    cols = max(c for _, c in grid) + 1
    out = []
    for r in range(rows):
        out.append("".join(grid.get((r, c), "<ecel>") for c in range(cols)) + "<nl>")
    return "".join(out)


# ---------------------------------------------------------------- metrics


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


def normalize_for_compare(task: str, text: str) -> str:
    """formula: delimiters and spaces removed; table: OTSL, spaces removed
    (HTML converted first); text: runs of whitespace collapsed."""

    if task == "formula":
        return re.sub(r"\s+", "", strip_math_delimiters(text))
    if task == "table":
        otsl = html_table_to_otsl(text) if "<table" in text.lower() or "<td" in text.lower() else text
        return re.sub(r"\s+", "", otsl)
    return " ".join(text.split())


def normalized_edit_distance(a: str, b: str) -> float:
    if not a and not b:
        return 0.0
    return edit_distance(a, b) / max(len(a), len(b))


# ---------------------------------------------------------------- leak guard


class EvalLeakError(RuntimeError):
    pass


def recognizer_eval_hashes() -> set[str]:
    """sha256 of every image in the recognizer tools' eval sets
    (tools/training: eval/real and eval/synthetic)."""

    sys.path.insert(0, str(REPO / "tools" / "training"))
    try:
        from common import Layout, read_labels, root_dir  # type: ignore
    finally:
        sys.path.pop(0)
    layout = Layout(root_dir(None))
    hashes = set()
    for name in ("real-eval", "synthetic-eval"):
        base = layout.set_dir(name)
        for image, _ in read_labels(layout.label_file(name)):
            path = base / image
            if path.exists():
                hashes.add(sha256_file(path))
    return hashes


def check_no_leak(train_hashes: dict[str, str], eval_hashes: set[str], eval_names: set[str] = frozenset()) -> None:
    """train_hashes: filename -> sha256 for train/val images."""

    leaked = sorted(name for name, digest in train_hashes.items() if digest in eval_hashes)
    if leaked:
        raise EvalLeakError(f"{len(leaked)} train/val image(s) have the same bytes as an eval image, e.g. {leaked[:3]}")
    same_name = sorted(set(train_hashes) & set(eval_names))
    if same_name:
        raise EvalLeakError(f"File name(s) in both eval and train/val: {same_name[:3]}")
