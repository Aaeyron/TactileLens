"""Text recognizer: before vs after on the same lines, with the adoption rule for text.

From tools/training (paddle_onnx_env):
  python compare_text.py --before <evaluate.py folder> --after <evaluate.py folder> [--meta lines.json] [--out <dir>]

Adoption rule for text (fixed 2026-11-19, before any text model was trained):
  adopt only if the eval CER improves AND at most 1 line in 50 (minimum 1)
  gets worse in a way that changes meaning.

Scores:
  CER (main)   character edit distance / label length, spaces ignored,
               − = – = - (minus, en dash, hyphen), and curly quotes =
               straight quotes
  exact        whole line equal under the same comparison
A line "gets worse" when its edit distance to the label grows. It is
meaning-changing when the distance grows after also removing punctuation
(. , ; : ! ? quotes, brackets, dashes): a wrong letter, word, number,
superscript or math symbol. Otherwise it is spacing/punctuation only
(reported separately; spaces themselves are compared only for that report).
"""

from __future__ import annotations

import argparse
import csv
import json
import re
from collections import defaultdict
from pathlib import Path

from common import edit_distance

PUNCTUATION = re.compile(r"[.,;:!?'\"“”‘’()\[\]{}\-–—…·_]")


QUOTES = str.maketrans({"’": "'", "‘": "'", "“": '"', "”": '"', "−": "-", "–": "-"})


def main_key(text: str) -> str:
    return text.translate(QUOTES).replace(" ", "")


def meaning_key(text: str) -> str:
    # a minus between characters is meaning; keep "-" when it touches a digit or letter on the right
    t = re.sub(r"[−–—]", "-", text)
    t = re.sub(r"-\s*(?=[\w⁰¹²³⁴⁵⁶⁷⁸⁹√(])", "\x01", t)
    t = PUNCTUATION.sub("", t).replace(" ", "")
    return t.replace("\x01", "-")


def spaced_key(text: str) -> str:
    return re.sub(r"\s+", " ", text.replace("−", "-")).strip()


def allowed(n: int) -> int:
    return max(1, n // 50)


def read(folder: Path) -> dict[str, dict]:
    path = next(folder.rglob("predictions.tsv"))
    with path.open(encoding="utf-8", newline="") as handle:
        return {r["image"]: r for r in csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE)}


def braille_kind(label: str, before: str, after: str) -> str:
    """For a spacing/punctuation-only line: does a punctuation mark change (and so the Braille)?
    Compared with spaces removed and no dash or quote folding (UEB writes - – — ' ’ " “ ” differently)."""
    raw = lambda s: s.replace(" ", "")  # noqa: E731
    if edit_distance(raw(label), raw(after)) > edit_distance(raw(label), raw(before)):
        return "punctuation (changes the Braille)"
    return "spacing only"


def classify(label: str, before: str, after: str) -> str:
    d = lambda f, x: edit_distance(f(label), f(x))  # noqa: E731
    if d(meaning_key, after) > d(meaning_key, before):
        return "meaning-changing"
    if d(main_key, after) > d(main_key, before) or d(spaced_key, after) > d(spaced_key, before):
        return "spacing/punctuation only"
    if d(main_key, after) < d(main_key, before):
        return "better"
    return "same"


def compare(before: dict, after: dict, meta: dict) -> dict:
    if set(before) != set(after):
        raise SystemExit("the two runs did not score the same lines")
    groups = defaultdict(lambda: {"lines": 0, "chars": 0, "err_before": 0, "err_after": 0, "exact_before": 0,
                                  "exact_after": 0, "meaning-changing": 0, "spacing/punctuation only": 0,
                                  "better": 0})
    changes = []
    for image in sorted(before):
        label = before[image]["label"]
        b, a = before[image]["prediction"], after[image]["prediction"]
        kind = classify(label, b, a)
        info = meta.get(Path(image).name, {})
        names = ["ALL", f"topic: {before[image]['topic']}"]
        if info:
            names += [f"source: {info.get('source')}", f"kind: {info.get('kind')}"]
        for name in names:
            g = groups[name]
            g["lines"] += 1
            g["chars"] += max(len(main_key(label)), 1)
            g["err_before"] += edit_distance(main_key(label), main_key(b))
            g["err_after"] += edit_distance(main_key(label), main_key(a))
            g["exact_before"] += main_key(label) == main_key(b)
            g["exact_after"] += main_key(label) == main_key(a)
            if kind in g:
                g[kind] += 1
        if kind in ("meaning-changing", "spacing/punctuation only"):
            change = {"image": image, "kind": kind, "label": label, "before": b, "after": a}
            if kind == "spacing/punctuation only":
                change["braille"] = braille_kind(label, b, a)
            changes.append(change)
    table = []
    for name, g in groups.items():
        table.append({"group": name, **{k: g[k] for k in ("lines", "exact_before", "exact_after")},
                      "cer_before": round(100 * g["err_before"] / g["chars"], 2),
                      "cer_after": round(100 * g["err_after"] / g["chars"], 2),
                      "worse_meaning": g["meaning-changing"], "worse_spacing_punctuation": g["spacing/punctuation only"],
                      "better": g["better"]})
    order = lambda r: (r["group"] != "ALL", r["group"])  # noqa: E731
    table.sort(key=order)
    total = table[0]
    rule = {"cer_improves": total["cer_after"] < total["cer_before"], "meaning_regressions": total["worse_meaning"],
            "allowed": allowed(total["lines"])}
    rule["passed"] = rule["cer_improves"] and rule["meaning_regressions"] <= rule["allowed"]
    return {"rule": rule, "table": table, "changes": changes}


def markdown(result: dict, before: Path, after: Path) -> str:
    r = result["rule"]
    lines = ["# Text recognizer: before vs after", "", f"- Before: `{before}`", f"- After: `{after}`", "",
             "## Decision (adoption rule for text)", "",
             f"- CER lower: {result['table'][0]['cer_before']}% -> {result['table'][0]['cer_after']}% -> "
             f"**{'yes' if r['cer_improves'] else 'no'}**",
             f"- Meaning-changing regressions: {r['meaning_regressions']} of {result['table'][0]['lines']}, "
             f"allowed {r['allowed']} -> **{'within the rule' if r['meaning_regressions'] <= r['allowed'] else 'over the limit'}**",
             f"- **{'Rule met.' if r['passed'] else 'Rule not met.'}**", "",
             "| group | lines | CER before % | CER after % | exact before | exact after | worse (meaning) | "
             "worse (spacing/punctuation) | better |", "|---|---|---|---|---|---|---|---|---|"]
    for t in result["table"]:
        lines.append(f"| {t['group']} | {t['lines']} | {t['cer_before']} | {t['cer_after']} | {t['exact_before']} | "
                     f"{t['exact_after']} | {t['worse_meaning']} | {t['worse_spacing_punctuation']} | {t['better']} |")
    groups = [("meaning-changing", lambda c: c["kind"] == "meaning-changing")]
    for braille in ("punctuation (changes the Braille)", "spacing only"):
        groups.append((f"spacing/punctuation only: {braille}", lambda c, b=braille: c.get("braille") == b))
    for kind, wanted in groups:
        items = [c for c in result["changes"] if wanted(c)]
        lines += ["", f"## Got worse, {kind}: {len(items)}", ""]
        lines += [f"- `{Path(c['image']).name}`: label `{c['label']}`; before `{c['before']}`; after `{c['after']}`"
                  for c in items] or ["- none"]
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--before", required=True)
    parser.add_argument("--after", required=True)
    parser.add_argument("--meta", help="JSON list of rows with line, source, kind (text_sets.py *_rows.json)")
    parser.add_argument("--out")
    args = parser.parse_args()
    meta = {}
    if args.meta:
        meta = {r["line"]: r for r in json.loads(Path(args.meta).read_text(encoding="utf-8"))}
    result = compare(read(Path(args.before)), read(Path(args.after)), meta)
    text = markdown(result, Path(args.before), Path(args.after))
    if args.out:
        out = Path(args.out)
        out.mkdir(parents=True, exist_ok=True)
        (out / "comparison.md").write_text(text, encoding="utf-8")
        (out / "comparison.json").write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
