"""Text-line test sets and training labels from our own T/W/M lines (Track B).

From tools/offline_text_model, with C:\\Projects\\Capstone\\paddle_onnx_env:

  python text_sets.py --working <...> select-test
      From the lines of the test images (pick_text_test_images.py), draws
      candidates per topic x ss/cap stratum (fixed seed, at most 3 lines per
      image, at least 2 characters read), about 30% more than needed, and
      writes PaddleOCR-VL jobs (text_lines_mtw/test/vl_jobs.json).

  python text_sets.py --working <...> finalize-test
      Converts the PaddleOCR-VL readings to the recognizer's characters
      (to_charset), drops the ones it cannot convert, and keeps --eval /
      --val lines spread over the strata in the drawn order. Writes
      test/eval_suggested.txt and test/val_suggested.txt (labels still to be
      reviewed) and test/report.json. Refuses to overwrite.

  python text_sets.py --working <...> select-train
      Every line of a non-test image, minus: images that are near-duplicates
      (dhash) of a test image, lines read as fewer than 2 characters, and
      lines whose offline reading equals a test label. PaddleOCR-VL order:
      cap first, lowest offline confidence first, in turn over topic x kind
      (train/vl_jobs.json).

  python text_sets.py --working <...> build-train
      From train/suggest_vl.jsonl: converted labels; drops non-convertible
      readings, labels equal to a test label, images with a test image's
      bytes, and more than 3 copies of a label per topic. Groups: agreed
      (offline reading = label) and teacher. Writes train_sets/text_v1/
      rec_train.txt and rec_val.txt (no rec_eval.txt: the eval set is scored
      once, by hand, after review).

Label convention (the recognizer's dictionary, common.py): exponents as
Unicode superscripts (x², 10⁻³), √ ≤ ≥ ≠ ± × ÷ · as characters, no LaTeX.
A reading with a fraction, a subscript, a letter exponent other than n, or a
character outside the dictionary cannot be written for this model and is
dropped (counted).
"""

from __future__ import annotations

import argparse
import json
import random
import re
from collections import Counter, defaultdict
from pathlib import Path

from common import SUPERSCRIPT, load_character_list

SEED = 20261119
MAX_PER_IMAGE = 3
OVERSAMPLE = 1.3
COMMANDS = {r"\leq": "≤", r"\le": "≤", r"\geq": "≥", r"\ge": "≥", r"\neq": "≠", r"\ne": "≠", r"\pm": "±",
            r"\times": "×", r"\div": "÷", r"\cdot": "·", r"\sqrt": "√", r"\%": "%", r"\$": "$", r"\&": "&",
            r"\ldots": "...", r"\dots": "...", r"\cdots": "...", r"\,": " ", r"\;": " ", r"\quad": " ", r"\ ": " ",
            r"\{": "{", r"\}": "}", r"\infty": "∞", r"\pi": "π", r"\theta": "θ", r"\alpha": "α", r"\beta": "β"}
TEXT_WRAPPERS = re.compile(r"\\(?:text|mathrm|textbf|mathbf|textit|mathit|operatorname)\{([^{}]*)\}")
SUP = re.compile(r"\^\{([^{}]*)\}|\^(.)")
INLINE_MATH = re.compile(r"\\\(|\\\)|\\\[|\\\]")
# PaddleOCR-VL writes inline math as "$ ... $" (spaces inside); a lone "$" is a dollar sign.
DOLLAR_MATH = re.compile(r"\$\s(.*?)\s\$|\$(\S(?:.*?\S)?)\$(?!\d)")


def to_charset(text: str, characters: set[str]) -> tuple[str | None, str]:
    """(label, "") or (None, reason). Never guesses: anything it cannot map exactly is a reason."""
    s = text.strip()
    if "\n" in s:
        return None, "several lines"
    s = INLINE_MATH.sub("", s)
    s = re.sub(r"\$\$\s*(.*?)\s*\$\$", r"\1", s)
    s = DOLLAR_MATH.sub(lambda m: m.group(1) if m.group(1) is not None else m.group(2), s)
    for _ in range(3):
        s = TEXT_WRAPPERS.sub(r"\1", s)
    if re.search(r"\\(?:d?frac|tfrac|over|binom)", s):
        return None, "fraction"
    if "_" in s:
        return None, "subscript"

    def raise_(match: re.Match) -> str:
        body = match.group(1) if match.group(1) is not None else match.group(2)
        body = body.replace(" ", "")
        if not body or any(c not in SUPERSCRIPT for c in body):
            raise ValueError(body)
        return "".join(SUPERSCRIPT[c] for c in body)

    try:
        s = SUP.sub(raise_, s)
    except ValueError as error:
        return None, f"exponent not in the dictionary ({error})"
    s = re.sub(r"\\sqrt\{(\w)\}", r"√\1", s)
    if re.search(r"\\sqrt\s*\{", s):
        return None, "root over several characters"
    s = s.replace(r"\{", "\x01").replace(r"\}", "\x02")
    for command in sorted(COMMANDS, key=len, reverse=True):
        s = re.sub(re.escape(command) + r"(?![A-Za-z])", lambda _m, c=command: COMMANDS[c], s)
    if "\\" in s or "^" in s or "{" in s or "}" in s:
        return None, "LaTeX left"
    s = s.replace("\x01", "{").replace("\x02", "}")
    s = re.sub(r"\s+", " ", s).strip()
    if not s:
        return None, "empty"
    missing = {c for c in s if c not in characters}
    if missing:
        return None, "character not in the dictionary"
    return s, ""


def stratum(row: dict) -> tuple[str, str]:
    return row["topic"], row["source"]


def draw(rows: list[dict], needed: int, seed: int) -> list[dict]:
    """Up to `needed` lines spread over the strata, at most MAX_PER_IMAGE per image, in a fixed random order."""
    rng = random.Random(seed)
    groups = defaultdict(list)
    for row in sorted(rows, key=lambda r: r["line"]):
        groups[stratum(row)].append(row)
    for group in groups.values():
        rng.shuffle(group)
    per_image, out = Counter(), []
    keys = sorted(groups)
    while len(out) < needed and any(groups.values()):
        for key in keys:
            while groups[key]:
                row = groups[key].pop()
                if per_image[row["source_image"]] < MAX_PER_IMAGE:
                    per_image[row["source_image"]] += 1
                    out.append(row)
                    break
            if len(out) >= needed:
                break
    return out


def lines_of(working: Path) -> list[dict]:
    rows = []
    for line in (working / "text_lines_mtw" / "lines.jsonl").read_text(encoding="utf-8").splitlines():
        try:
            image = json.loads(line)
        except ValueError:
            continue
        m = re.match(r"^(?P<topic>.+?)_(?P<source>cap|ss)_(?P<kind>[A-Z])_", image["source"])
        for item in image.get("lines", []):
            rows.append({**item, "source_image": image["source"], "topic": m["topic"], "source": m["source"],
                         "kind": m["kind"]})
    return rows


def select_test(args) -> None:
    working = Path(args.working)
    out = working / "text_lines_mtw" / "test"
    if (out / "candidates.json").exists():
        raise SystemExit("test candidates exist already")
    chosen = json.loads((working / "text_lines_mtw" / "test_sources.json").read_text(encoding="utf-8"))
    rows = lines_of(working)
    done = set()
    for line in (working / "text_lines_mtw" / "lines.jsonl").read_text(encoding="utf-8").splitlines():
        try:
            row = json.loads(line)
        except ValueError:
            continue
        if "error" not in row:
            done.add(row["source"])  # an image without a text line counts as done
    missing = [n for n in chosen["eval"] + chosen["val"] if n not in done]
    if missing:
        raise SystemExit(f"{len(missing)} test images not cut yet")
    usable = [r for r in rows if len(r["offline"].replace(" ", "")) >= 2]
    candidates = {}
    for split, needed, seed in (("eval", args.eval, SEED), ("val", args.val, SEED + 1)):
        names = set(chosen[split])
        candidates[split] = draw([r for r in usable if r["source_image"] in names], round(needed * OVERSAMPLE), seed)
    out.mkdir(parents=True, exist_ok=True)
    (out / "candidates.json").write_text(json.dumps(candidates, ensure_ascii=False, indent=1), encoding="utf-8")
    images = working / "text_lines_mtw" / "images"
    jobs = [{"id": r["line"], "image": str(images / r["line"]), "prompt_label": "ocr"}
            for split in ("eval", "val") for r in candidates[split]]
    (out / "vl_jobs.json").write_text(json.dumps(jobs, indent=1), encoding="utf-8")
    print({s: len(c) for s, c in candidates.items()}, "candidates;", len(jobs), "PaddleOCR-VL jobs")


def vl_text(row: dict) -> str:
    return "\n".join(b.get("content", "") for b in row.get("blocks", []) if b.get("content")).strip()


def finalize_test(args) -> None:
    working = Path(args.working)
    out = working / "text_lines_mtw" / "test"
    if (out / "eval_suggested.txt").exists():
        raise SystemExit("suggested test labels exist already")
    characters = set(load_character_list())
    candidates = json.loads((out / "candidates.json").read_text(encoding="utf-8"))
    readings = {}
    for line in (out / "suggest_vl.jsonl").read_text(encoding="utf-8").splitlines():
        row = json.loads(line)
        readings[row["id"]] = row
    report = {}
    for split, needed in (("eval", args.eval), ("val", args.val)):
        kept, reasons = [], Counter()
        for row in candidates[split]:
            reading = readings.get(row["line"])
            if reading is None or "error" in reading:
                reasons["no PaddleOCR-VL reading"] += 1
                continue
            label, reason = to_charset(vl_text(reading), characters)
            if label is None:
                reasons[reason] += 1
                continue
            kept.append({**row, "vl": vl_text(reading), "label": label})
        final = draw(kept, needed, SEED + 7)
        lines = [f"images/{r['line']}\t{r['label']}" for r in sorted(final, key=lambda r: r["line"])]
        (out / f"{split}_suggested.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
        (out / f"{split}_rows.json").write_text(json.dumps(final, ensure_ascii=False, indent=1), encoding="utf-8")
        report[split] = {"candidates": len(candidates[split]), "convertible": len(kept), "chosen": len(final),
                         "dropped": dict(reasons), "images": len({r["source_image"] for r in final}),
                         "by_stratum": dict(Counter("/".join(stratum(r)) for r in final)),
                         "by_kind": dict(Counter(r["kind"] for r in final))}
    (out / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=1))


def text_key(text: str) -> str:
    """Comparison key for "same text": compare_text.main_key, lower case."""
    from compare_text import main_key
    return main_key(text).lower()


def test_labels(out: Path) -> set[str]:
    keys = set()
    for name in ("eval_suggested.txt", "val.txt", "eval.txt"):
        path = out / name
        if path.exists():
            keys |= {text_key(line.split("\t", 1)[1]) for line in path.read_text(encoding="utf-8").splitlines() if "\t" in line}
    return keys


def near_test_sources(working: Path, test_names: set[str], names: set[str]) -> set[str]:
    """Training source images that are near-duplicates (dhash) of a test source image."""
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "data_preparation"))
    import dataset_common as dc
    images = working / "images"
    hashes = {n: dc.dhash(images / n) for n in sorted(test_names | names)}
    near = set()
    for a, b, _bits in dc.near_duplicate_pairs(hashes):
        if (a in test_names) != (b in test_names):
            near.add(b if a in test_names else a)
    return near


def round_robin_by(rows: list[dict], key) -> list[dict]:
    groups = defaultdict(list)
    for row in rows:
        groups[key(row)].append(row)
    out, lists = [], [groups[k] for k in sorted(groups)]
    while any(lists):
        for group in lists:
            if group:
                out.append(group.pop(0))
    return out


def select_train(args) -> None:
    working = Path(args.working)
    base = working / "text_lines_mtw"
    out = base / "train"
    chosen = json.loads((base / "test_sources.json").read_text(encoding="utf-8"))
    test_names = set(chosen["eval"] + chosen["val"])
    rows = [r for r in lines_of(working) if r["source_image"] not in test_names]
    names = {r["source_image"] for r in rows}
    near = near_test_sources(working, test_names, names)
    labels = test_labels(base / "test")
    reasons = Counter()
    kept = []
    for r in rows:
        if r["source_image"] in near:
            reasons["source image near-duplicate of a test image"] += 1
        elif len(r["offline"].replace(" ", "")) < 2:
            reasons["fewer than 2 characters read"] += 1
        elif text_key(r["offline"]) in labels:
            reasons["offline reading equals a test label"] += 1
        else:
            kept.append(r)
    # PaddleOCR-VL order: cap before ss, then the lowest offline confidence first, taken in turn over topic x kind.
    kept.sort(key=lambda r: (r["source"] != "cap", r["confidence"]))
    order = round_robin_by(kept, lambda r: (r["source"] != "cap", r["topic"], r["kind"]))
    order.sort(key=lambda r: r["source"] != "cap")  # stable: cap first, round robin inside
    out.mkdir(parents=True, exist_ok=True)
    images = base / "images"
    jobs = [{"id": r["line"], "image": str(images / r["line"]), "prompt_label": "ocr"} for r in order]
    (out / "vl_jobs.json").write_text(json.dumps(jobs, indent=1), encoding="utf-8")
    report = {"lines_outside_test_images": len(rows), "candidates": len(kept), "dropped": dict(reasons),
              "near_duplicate_source_images": len(near), "test_images": len(test_names),
              "by_source": dict(Counter(r["source"] for r in kept)), "by_kind": dict(Counter(r["kind"] for r in kept))}
    (out / "select_report.json").write_text(json.dumps(report, indent=1), encoding="utf-8")
    print(json.dumps(report, indent=1))


def build_train(args) -> None:
    """Training list from the PaddleOCR-VL readings: agreed (offline = PaddleOCR-VL) and teacher (PaddleOCR-VL only)."""
    import hashlib
    working = Path(args.working)
    base = working / "text_lines_mtw"
    characters = set(load_character_list())
    meta = {r["line"]: r for r in lines_of(working)}
    labels = test_labels(base / "test")
    test_hashes = set()
    for name in ("eval_suggested.txt", "val.txt"):
        for line in (base / "test" / name).read_text(encoding="utf-8").splitlines():
            image = line.split("\t", 1)[0]
            test_hashes.add(hashlib.sha256((base / "test" / image).read_bytes()).hexdigest())
    reasons, rows, copies = Counter(), [], Counter()
    for line in (base / "train" / "suggest_vl.jsonl").read_text(encoding="utf-8").splitlines():
        reading = json.loads(line)
        r = meta.get(reading["id"])
        if r is None or "error" in reading:
            reasons["no reading"] += 1
            continue
        label, reason = to_charset(vl_text(reading), characters)
        if label is None:
            reasons[reason] += 1
            continue
        if len(label.replace(" ", "")) < 2:
            reasons["fewer than 2 characters"] += 1
            continue
        if text_key(label) in labels:
            reasons["label equals a test label"] += 1
            continue
        if hashlib.sha256((base / "images" / r["line"]).read_bytes()).hexdigest() in test_hashes:
            reasons["same bytes as a test image"] += 1
            continue
        key = (r["topic"], text_key(label))
        if copies[key] >= 3:
            reasons["more than 3 copies of a label per topic"] += 1
            continue
        copies[key] += 1
        from compare_text import main_key
        group = "agreed" if main_key(r["offline"]) == main_key(label) else "teacher"
        rows.append({**r, "label": label, "group": group})
    out = working / "train_sets" / "text_v1"
    out.mkdir(parents=True, exist_ok=True)
    link = out / "images"
    if not link.exists():
        import subprocess
        subprocess.run(["cmd", "/c", "mklink", "/J", str(link), str(base / "images")], check=True, capture_output=True)
    (out / "rec_train.txt").write_text("".join(f"images/{r['line']}\t{r['label']}\n" for r in rows), encoding="utf-8")
    (out / "rec_val.txt").write_text((base / "test" / "val.txt").read_text(encoding="utf-8"), encoding="utf-8")
    report = {"training_lines": len(rows), "groups": dict(Counter(r["group"] for r in rows)), "dropped": dict(reasons),
              "by_source": dict(Counter(r["source"] for r in rows)), "by_kind": dict(Counter(r["kind"] for r in rows)),
              "by_topic": dict(Counter(r["topic"] for r in rows)),
              "with_superscript": sum(any(c in "⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿ" for c in r["label"]) for r in rows),
              "source_images": len({r["source_image"] for r in rows}),
              "validation_lines": len((base / "test" / "val.txt").read_text(encoding="utf-8").splitlines())}
    (out / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=1))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", required=True)
    parser.add_argument("--eval", type=int, default=100)
    parser.add_argument("--val", type=int, default=150)
    parser.add_argument("step", choices=["select-test", "finalize-test", "select-train", "build-train"])
    args = parser.parse_args()
    {"select-test": select_test, "finalize-test": finalize_test, "select-train": select_train,
     "build-train": build_train}[args.step](args)


if __name__ == "__main__":
    main()
