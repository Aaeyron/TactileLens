"""Compare two evaluate_formula.py runs on the same formula list and apply
the adoption rule for our own data (docs/training_runbook.md).

  python compare_formula.py --before <results dir> --after <results dir> [--out <dir>]
      [--meta labels.csv]

Reads only the two runs' predictions.tsv (no model is run). Both runs must
have scored the same images with the same targets.

Three scores, applied the same way to both models:
- strict: evaluate_formula.py's comparison (math delimiters and
  whitespace removed);
- spacing-normalized: strict, and in addition these LaTeX spacing
  commands are removed from target and prediction (SPACING_RULE):
  \\, \\: \\; \\! \\  (backslash-space) ~ \\quad \\qquad \\enspace \\thinspace
  \\medspace \\thickspace \\negthinspace \\negmedspace \\negthickspace
  \\hspace{...}. Nothing else changes;
- notation-normalized: spacing-normalized, and in addition the safe rewrites
  in NOTATION_RULES (e.g. \\leq = \\le, \\left( = ( ). This is the main score
  for our own data (decided 2026-11-19, before any model was scored on it:
  most labels started from PaddleOCR-VL's readings, so its notation style
  must not decide which model wins).

Adoption rule (2026-11-11; main score 2026-11-19), on the notation-normalized
score:
- the new model's exact match is higher than the original's, and
- at most allowed_regressions(n) simple formulas (at most 20 LaTeX tokens)
  get worse: 1 per 100 simple formulas, rounded down, minimum 1.
A regression is a formula the original model reads correctly and the new
model does not. Every regression is listed and sorted (classify):
- spacing only: equal to the target once spacing is ignored (only
  possible on the strict score);
- same meaning, different notation: equal to the target after the safe
  rewrites in NOTATION_RULES (e.g. \\leq for \\le, ( for \\left( );
- meaning-changing: everything else. This is deliberately conservative:
  anything not shown to be equal by those rewrites (including a missing
  final comma or full stop) counts as meaning-changing, and these are
  reported separately.
The spacing-normalized and strict scores are always reported next to it.
--meta (finalize_labels.py labels.csv) uses the reviewed topics and adds
groups per source (ss / cap) and per label source. "[object Object]" written
by each model is counted (the model generates that text itself).

Writes comparison.md and comparison.json to --out (default: the --after
folder).
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

from evaluate_formula import length_group

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "training_vl"))
import vl_common  # noqa: E402

SPACING_COMMANDS = ["qquad", "quad", "enspace", "thinspace", "medspace", "thickspace", "negthinspace",
                    "negmedspace", "negthickspace"]
SPACING = re.compile(r"\\hspace\*?\s*\{[^{}]*\}|\\(?:" + "|".join(SPACING_COMMANDS) + r")(?![A-Za-z])"
                     r"|(?<!\\)\\[,:;! ]|~")
SPACING_RULE = ("LaTeX spacing commands are ignored: \\, \\: \\; \\! \\(space) ~ \\quad \\qquad \\enspace "
                "\\thinspace \\medspace \\thickspace \\negthinspace \\negmedspace \\negthickspace \\hspace{...}; "
                "then math delimiters and whitespace are removed as in the strict score. Nothing else changes.")
MODES = ("notation-normalized", "spacing-normalized", "strict")
DECIDING_MODE = "notation-normalized"
OBJECT_OBJECT = re.compile(r"object\s*Object")
SPACING_ONLY, SAME_MEANING, MEANING = "spacing only", "same meaning, different notation", "meaning-changing"
NOTATION_RULES = [
    "\\leq = \\le, \\geq = \\ge, \\neq = \\ne",
    "\\dfrac and \\tfrac = \\frac",
    "\\left( and \\right) = ( and ) (also [ ] | \\{ \\}); \\left. and \\right. dropped",
    "braces around a single token after ^ or _: x^{2} = x^2",
    "braces around a whole group that is not a command argument: {\\frac{a}{b}} = \\frac{a}{b}",
]


def allowed_regressions(simple_items: int) -> int:
    """At most 1 regression per 100 simple formulas, rounded down, minimum 1."""
    return max(1, simple_items // 100)


def drop_spacing(latex: str) -> str:
    return SPACING.sub(" ", latex)


def spacing_key(latex: str) -> str:
    return vl_common.normalize_for_compare("formula", drop_spacing(latex))


def spacing_scores(target: str, prediction: str) -> tuple[bool, float]:
    a, b = spacing_key(target), spacing_key(prediction)
    return a == b, vl_common.normalized_edit_distance(a, b)


def notation_scores(target: str, prediction: str) -> tuple[bool, float]:
    a, b = notation_key(target), notation_key(prediction)
    return a == b, vl_common.normalized_edit_distance(a, b)


def _drop_redundant_braces(s: str) -> str:
    """Remove {...} groups that are not a command argument or a ^/_ operand."""
    changed = True
    while changed:
        changed = False
        for i, c in enumerate(s):
            if c != "{" or (i > 0 and s[i - 1] == "\\"):
                continue
            prev = s[i - 1] if i else ""
            if prev and (prev.isalnum() or prev in "}]^_'"):
                continue  # an argument ({..} after \frac, \sqrt[3], ^, _ or another argument)
            depth = 0
            for j in range(i, len(s)):
                if s[j] == "{" and (j == 0 or s[j - 1] != "\\"):
                    depth += 1
                elif s[j] == "}" and s[j - 1] != "\\":
                    depth -= 1
                    if depth == 0:
                        s = s[:i] + s[i + 1:j] + s[j + 1:]
                        changed = True
                        break
            if changed:
                break
    return s


def notation_key(latex: str) -> str:
    # Command rewrites on the spaced text (removing whitespace first would
    # glue "\ne b" into "\neb"); a space after each rewritten command keeps
    # it separate from a following letter.
    s = drop_spacing(latex)
    s = re.sub(r"\\leq(?![A-Za-z])", r"\\le ", s)
    s = re.sub(r"\\geq(?![A-Za-z])", r"\\ge ", s)
    s = re.sub(r"\\neq(?![A-Za-z])", r"\\ne ", s)
    s = re.sub(r"\\(le|ge|ne)(?![A-Za-z])", r"\\\1 ", s)
    s = re.sub(r"\\[dt]frac(?![A-Za-z])", r"\\frac", s)
    s = re.sub(r"\\(?:left|right)\s*\.", "", s)
    s = re.sub(r"\\(?:left|right)(?![A-Za-z])", "", s)
    s = vl_common.normalize_for_compare("formula", s)
    s = re.sub(r"([\^_])\{(\\[A-Za-z]+|[^{}\\])\}", r"\1\2", s)
    return _drop_redundant_braces(s)


def classify(target: str, prediction: str) -> str:
    """How a wrong reading differs from the target (see the module docstring)."""
    if spacing_key(target) == spacing_key(prediction):
        return SPACING_ONLY
    if notation_key(target) == notation_key(prediction):
        return SAME_MEANING
    return MEANING


def read(folder: Path) -> dict[str, dict]:
    with open(folder / "predictions.tsv", encoding="utf-8", newline="") as handle:
        return {r["image"]: r for r in csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE)}


def read_meta(path: Path) -> dict[str, dict]:
    with open(path, encoding="utf-8", newline="") as handle:
        return {r["filename"]: r for r in csv.DictReader(handle)}


def label_groups(provenance: str) -> list[str]:
    if provenance.startswith("AI"):
        return ["labels: AI-reviewed (Claude)"]
    groups = ["labels: human-reviewed"]
    if provenance.startswith("human-verified"):
        groups.append("labels: human-reviewed, accepted on the page")
    return groups


def extra_groups(image: str, meta: dict[str, dict]) -> tuple[str | None, list[str]]:
    row = meta.get(Path(image).name)
    if not row:
        return None, []
    return row["topic"], [f"source: {row['source']}", *label_groups(row["provenance"])]


def object_object_count(rows: dict[str, dict]) -> int:
    return sum(bool(OBJECT_OBJECT.search(r["prediction"])) for r in rows.values())


def compare(before: dict[str, dict], after: dict[str, dict], mode: str = "strict",
            meta: dict[str, dict] | None = None) -> dict:
    if before.keys() != after.keys():
        raise SystemExit(f"different images: {len(before.keys() ^ after.keys())} not in both runs")
    for image in before:
        if before[image]["target"] != after[image]["target"]:
            raise SystemExit(f"different target for {image}")
    groups = defaultdict(list)
    for image, b in before.items():
        a = after[image]
        if mode == "strict":
            eb, nb = b["exact"] == "True", float(b["ned"])
            ea, na = a["exact"] == "True", float(a["ned"])
        else:
            score = notation_scores if mode == "notation-normalized" else spacing_scores
            eb, nb = score(b["target"], b["prediction"])
            ea, na = score(a["target"], a["prediction"])
        item = {"image": image, "target": b["target"], "before": b["prediction"], "after": a["prediction"],
                "exact_before": eb, "exact_after": ea, "ned_before": nb, "ned_after": na,
                "simple": length_group(b["target"]).endswith("(simple)")}
        topic, extra = extra_groups(image, meta or {})
        for group in ("ALL", topic or b["topic"], length_group(b["target"]), *extra):
            groups[group].append(item)

    def summary(items: list[dict]) -> dict:
        n = len(items)
        return {"items": n,
                "exact_before": sum(i["exact_before"] for i in items),
                "exact_after": sum(i["exact_after"] for i in items),
                "exact_before_pct": round(100 * sum(i["exact_before"] for i in items) / n, 1),
                "exact_after_pct": round(100 * sum(i["exact_after"] for i in items) / n, 1),
                "ned_before": round(sum(i["ned_before"] for i in items) / n, 4),
                "ned_after": round(sum(i["ned_after"] for i in items) / n, 4),
                "got_worse": sum(i["exact_before"] and not i["exact_after"] for i in items),
                "got_better": sum(i["exact_after"] and not i["exact_before"] for i in items)}

    special = ("length", "source:", "labels:")
    order = ["ALL"] + sorted(g for g in groups if g != "ALL" and not g.startswith(special)) + sorted(
        g for g in groups if g.startswith(special))
    regressions = []
    for i in groups["ALL"]:
        if i["exact_before"] and not i["exact_after"]:
            regressions.append({**i, "kind": classify(i["target"], i["after"])})
    regressions.sort(key=lambda i: (not i["simple"], i["image"]))
    table = {g: summary(groups[g]) for g in order}
    simple_items = sum(1 for i in groups["ALL"] if i["simple"])
    simple_regressions = sum(1 for r in regressions if r["simple"])
    rule = {"simple_items": simple_items, "simple_regressions": simple_regressions,
            "allowed_simple_regressions": allowed_regressions(simple_items),
            "exact_before": table["ALL"]["exact_before"], "exact_after": table["ALL"]["exact_after"],
            "meaning_changing_regressions": sum(1 for r in regressions if r["kind"] == MEANING),
            "meaning_changing_simple_regressions": sum(1 for r in regressions if r["kind"] == MEANING and r["simple"])}
    rule["simple_rule_met"] = simple_regressions <= rule["allowed_simple_regressions"]
    rule["higher_exact"] = rule["exact_after"] > rule["exact_before"]
    rule["passed"] = rule["simple_rule_met"] and rule["higher_exact"]
    return {"mode": mode, "groups": table, "regressions": regressions, "rule": rule,
            "object_object": {"before": object_object_count(before), "after": object_object_count(after)}}


def regression_lines(regressions: list[dict]) -> list[str]:
    lines = []
    for r in regressions:
        lines.append(f"- `{Path(r['image']).name}` ({'simple' if r['simple'] else length_group(r['target'])}): "
                     f"target `{r['target']}`; original `{r['before']}`; new `{r['after']}`")
    return lines or ["- none"]


def section(result: dict) -> list[str]:
    mode, rule = result["mode"], result["rule"]
    lines = [f"## {mode.capitalize()} score" + (" (decides)" if mode == DECIDING_MODE else " (reported alongside)"), ""]
    if mode != "strict":
        lines += [f"Rule: {SPACING_RULE}", ""]
    if mode == "notation-normalized":
        lines += ["Also treated as equal: " + "; ".join(NOTATION_RULES) + ".", ""]
    lines += ["| group | items | exact before | exact after | NED before | NED after | got worse | got better |",
              "|---|---|---|---|---|---|---|---|"]
    for g, s in result["groups"].items():
        lines.append(f"| {g} | {s['items']} | {s['exact_before_pct']}% ({s['exact_before']}/{s['items']})"
                     f" | {s['exact_after_pct']}% ({s['exact_after']}/{s['items']}) | {s['ned_before']}"
                     f" | {s['ned_after']} | {s['got_worse']} | {s['got_better']} |")
    lines += ["", f"Simple-formula regressions: {rule['simple_regressions']} of {rule['simple_items']} "
              f"(allowed {rule['allowed_simple_regressions']}: 1 per 100, minimum 1) -> "
              f"**{'within the rule' if rule['simple_rule_met'] else 'over the limit'}**; overall exact "
              f"{rule['exact_before']} -> {rule['exact_after']}.", ""]
    regs = result["regressions"]
    for kind in (MEANING, SAME_MEANING, SPACING_ONLY):
        chosen = [r for r in regs if r["kind"] == kind]
        if mode == DECIDING_MODE and kind != MEANING and not chosen:
            continue  # cannot happen on this score
        lines += [f"### Regressions, {kind} ({mode}): {len(chosen)}", ""] + regression_lines(chosen) + [""]
    return lines


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--before", required=True, help="evaluate_formula.py output folder (original model)")
    parser.add_argument("--after", required=True, help="evaluate_formula.py output folder (fine-tuned model)")
    parser.add_argument("--out")
    parser.add_argument("--meta", help="finalize_labels.py labels.csv: reviewed topics, source and label-source groups")
    args = parser.parse_args()

    before, after = read(Path(args.before)), read(Path(args.after))
    meta = read_meta(Path(args.meta)) if args.meta else None
    results = {mode: compare(before, after, mode, meta) for mode in MODES}
    decide = results[DECIDING_MODE]["rule"]
    out = Path(args.out or args.after)
    out.mkdir(parents=True, exist_ok=True)
    (out / "comparison.json").write_text(json.dumps(
        {"before": args.before, "after": args.after, "spacing_rule": SPACING_RULE, "notation_rules": NOTATION_RULES,
         "decision": f"adoption rule on the {DECIDING_MODE} score", "passed": decide["passed"],
         **results}, indent=1, ensure_ascii=False), encoding="utf-8")
    meaning = [r for r in results[DECIDING_MODE]["regressions"] if r["kind"] == MEANING]
    lines = ["# Formula model: before vs after", "", f"- Before: `{args.before}`", f"- After: `{args.after}`", "",
             f"## Decision (adoption rule, {DECIDING_MODE} score)", "",
             f"- Exact match higher than the original: {decide['exact_before']} -> {decide['exact_after']} -> "
             f"**{'yes' if decide['higher_exact'] else 'no'}**",
             f"- Simple-formula regressions: {decide['simple_regressions']} of {decide['simple_items']}, allowed "
             f"{decide['allowed_simple_regressions']} -> **{'within the rule' if decide['simple_rule_met'] else 'over the limit'}**",
             f"- **Rule {'met' if decide['passed'] else 'not met'}.** Spacing-normalized and strict scores are "
             "reported below; they do not decide.",
             f"- `[object Object]` written by the model: {results[DECIDING_MODE]['object_object']['before']} readings "
             f"before, {results[DECIDING_MODE]['object_object']['after']} after.",
             "", f"### Meaning-changing regressions (reported separately): {len(meaning)} "
             f"({decide['meaning_changing_simple_regressions']} simple)", ""]
    lines += regression_lines(meaning)
    lines += ["", "\"Meaning-changing\" is conservative: any difference from the target not removed by the spacing "
              "rule or these notation rewrites counts: " + "; ".join(NOTATION_RULES) + ".", ""]
    for mode in MODES:
        lines += section(results[mode])
    (out / "comparison.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
