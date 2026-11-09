"""Filtering report for im2latex-100k (for the panel), plus looser-filter counts.

With C:\\Projects\\Capstone\\paddle_formula_env (pyarrow, Pillow), run with -I:
  python -I im2latex_filter_report.py --src <folder with the .parquet files>
      --subset <prepare_im2latex.py output> --out <new folder>

Reads only; writes nothing to the dataset. Output:
  report.md                  source, licence, rules in plain words, counts
                             after each rule per split, per topic, leak guard,
                             examples, limits, looser-filter counts
  counts.json                every number in the report
  examples/kept_*.png, examples/rejected_*.png   (the published images)
  examples_kept.png, examples_rejected.png       one sheet each, for slides
  chart_funnel.png, chart_topics.png, chart_looser.png

Looser variants (counts only; the training subset is not changed):
  A  current filter
  B  A + subscripts with one letter or digit, or a short braced index
     (x_n, a_i, x_{n+1}, a_{12})
  C  A + more Greek letters (gamma, delta, lambda, mu, sigma, phi, omega,
     epsilon)
  D  B and C together
"""

from __future__ import annotations

import argparse
import json
import random
import re
import sys
from collections import Counter, defaultdict
from io import BytesIO
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "model_prep"))

import algebra_filter as af  # noqa: E402
from prepare_im2latex import SPLITS, key, topic  # noqa: E402

RULES = [
    ("too long", "at most 60 LaTeX tokens"),
    ("command", "only commands from the allowed list (fractions, roots, \\cdot, \\times, \\div, \\pm, comparisons, "
                "\\left/\\right, spacing, \\pi, \\alpha, \\beta, \\theta, \\mathrm, \\text); no environments, sums, "
                "integrals, limits, fonts, accents, matrices"),
    ("subscript beyond x_1", "subscripts only as a letter with a number (x_1, x_{2})"),
    ("deep nesting", "braces nested at most 3 deep"),
    ("words (not a formula)", "no words of 4 or more letters (text, not a formula)"),
    ("no algebra feature", "contains at least one of =, <, >, \\le, \\ge, \\neq, a power, \\frac, \\sqrt, f(x)"),
]
EXTRA_GREEK = {"gamma", "delta", "lambda", "mu", "sigma", "phi", "omega", "epsilon"}
LOOSE_SUB = re.compile(r"_\s*(?:[A-Za-z0-9]|\{\s*[A-Za-z0-9](?:\s*[+-]?\s*[A-Za-z0-9])?\s*\})")


def rule_of(reason: str) -> str:
    if reason in ("empty", "too long"):
        return "too long"
    if reason in ("subscript beyond x_1", "deep nesting", "words (not a formula)", "no algebra feature"):
        return reason
    return "command"


def reason_variant(latex: str, subs: bool, greek: bool) -> str | None:
    """algebra_filter.reason_to_drop with the looser options switched on."""

    saved = set(af.ALLOWED)
    try:
        if greek:
            af.ALLOWED |= EXTRA_GREEK
        why = af.reason_to_drop(latex)
        if why == "subscript beyond x_1" and subs:
            text = latex.strip().strip("$")
            if not re.sub(LOOSE_SUB.pattern, "", text).count("_"):
                rest = re.sub(r"_\s*(\{[^{}]*\}|.)", "", text)  # check the remaining rules without subscripts
                why = af.reason_to_drop(rest) if rest.strip() else "empty"
                if why == "no algebra feature" and af.FEATURE.search(text):
                    why = None
        return why
    finally:
        af.ALLOWED.clear()
        af.ALLOWED.update(saved)


def sheet(items: list[tuple[bytes, str, str]], path: Path, title: str) -> None:
    from charts import font
    from PIL import Image, ImageDraw

    width, row_h = 1600, 150
    img = Image.new("RGB", (width, 90 + row_h * len(items)), "white")
    d = ImageDraw.Draw(img)
    d.text((40, 25), title, fill="#111827", font=font(36))
    for i, (data, latex, note) in enumerate(items):
        y = 90 + i * row_h
        pic = Image.open(BytesIO(data)).convert("RGB")
        pic.thumbnail((700, row_h - 30))
        img.paste(pic, (40, y + 5))
        d.rectangle([38, y + 3, 42 + pic.width, y + 7 + pic.height], outline="#d1d5db", width=1)
        text = latex if len(latex) <= 70 else latex[:67] + "..."
        d.text((780, y + 20), note, fill="#1d4ed8", font=font(24))
        d.text((780, y + 60), text, fill="#111827", font=font(20))
        d.line([(40, y + row_h - 5), (width - 40, y + row_h - 5)], fill="#e5e7eb", width=1)
    img.save(path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--src", required=True)
    parser.add_argument("--subset", required=True, help="prepare_im2latex.py output (report.json)")
    parser.add_argument("--out", required=True)
    parser.add_argument("--examples", type=int, default=8)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--overwrite", action="store_true", help="write over this script's own files in --out")
    args = parser.parse_args()

    import pyarrow.parquet as pq
    from charts import bar_chart

    src, out = Path(args.src), Path(args.out)
    if out.exists() and any(out.iterdir()) and not args.overwrite:
        raise SystemExit(f"{out} is not empty")
    (out / "examples").mkdir(parents=True, exist_ok=True)
    subset = json.loads((Path(args.subset) / "report.json").read_text(encoding="utf-8"))

    funnel, variants, variant_topics, tables = {}, {}, {}, {}
    rejected_pool, kept_pool = defaultdict(list), []
    for split in SPLITS:
        table = pq.read_table(next(src.glob(f"{split}-*.parquet")))
        tables[split] = table
        formulas = table.column("formula").to_pylist()
        drops = Counter()
        counts = Counter()
        per_topic = {v: Counter() for v in "ABCD"}
        for index, latex in enumerate(formulas):
            latex = latex or ""
            why = af.reason_to_drop(latex)
            if why:
                drops[rule_of(why)] += 1
                if split == "train":
                    rejected_pool[rule_of(why)].append((index, why))
            elif split == "train":
                kept_pool.append(index)
            for name, subs, greek in (("A", False, False), ("B", True, False), ("C", False, True), ("D", True, True)):
                ok = (why is None) if name == "A" else reason_variant(latex, subs, greek) is None
                if ok:
                    counts[name] += 1
                    per_topic[name][topic(latex.strip())] += 1
        remaining, steps = len(formulas), [("published", len(formulas))]
        for rule, _ in RULES:
            remaining -= drops[rule]
            steps.append((rule, remaining))
        funnel[split] = steps
        variants[split] = dict(counts)
        variant_topics[split] = {k: dict(v) for k, v in per_topic.items()}

    # Leak guard result (from prepare_im2latex.py's run) and the removed duplicates.
    guard = {s: subset["splits"][s]["dropped_by_leak_guard"] for s in SPLITS}
    held = {s: {} for s in ("val", "test")}
    for s in held:
        t = tables[s]
        for f, img in zip(t.column("formula").to_pylist(), t.column("image").to_pylist()):
            if af.reason_to_drop(f or "") is None:
                import hashlib
                held[s][hashlib.sha256(img["bytes"]).hexdigest()] = (f.strip(), img["bytes"])
    import hashlib
    duplicates = []
    t = tables["train"]
    for f, img in zip(t.column("formula").to_pylist(), t.column("image").to_pylist()):
        if af.reason_to_drop(f or "") is None:
            sha = hashlib.sha256(img["bytes"]).hexdigest()
            for s in ("test", "val"):
                if sha in held[s]:
                    duplicates.append({"train_latex": f.strip(), "other_split": s, "other_latex": held[s][sha][0],
                                       "same_latex": key(f) == key(held[s][sha][0]), "sha256": sha[:12]})
                    break

    # Examples (train split, fixed seed).
    rng = random.Random(args.seed)
    images = tables["train"].column("image").to_pylist()
    formulas = tables["train"].column("formula").to_pylist()
    by_topic = defaultdict(list)
    for i in kept_pool:
        by_topic[topic(formulas[i].strip())].append(i)
    kept_ix = []
    for t_name in sorted(by_topic):
        if len(kept_ix) < args.examples:
            kept_ix.append(rng.choice(by_topic[t_name]))
    rej = []
    for rule, _ in RULES:
        pool = rejected_pool.get(rule, [])
        if pool:
            rej.append(rng.choice(pool))
    while len(rej) < args.examples:
        rule = rng.choice([r for r, _ in RULES if rejected_pool.get(r)])
        rej.append(rng.choice(rejected_pool[rule]))
    kept_items, rej_items = [], []
    for n, i in enumerate(kept_ix, 1):
        data = images[i]["bytes"]
        (out / "examples" / f"kept_{n}.png").write_bytes(data)
        kept_items.append((data, formulas[i].strip(), f"kept, topic: {topic(formulas[i].strip())}"))
    for n, (i, why) in enumerate(rej[:args.examples], 1):
        data = images[i]["bytes"]
        (out / "examples" / f"rejected_{n}.png").write_bytes(data)
        rej_items.append((data, formulas[i].strip(), f"rejected: {why}"))
    sheet(kept_items, out / "examples_kept.png", "Kept by the algebra filter (im2latex-100k train)")
    sheet(rej_items, out / "examples_rejected.png", "Rejected by the algebra filter, with the reason")

    # Charts.
    labels = ["published"] + [f"after: {r}" for r, _ in RULES]
    bar_chart(labels, {s: [n for _, n in funnel[s]] for s in SPLITS},
              "im2latex-100k: formulas left after each rule", out / "chart_funnel.png",
              note="Rules applied in this order; each bar = formulas still kept after that rule. Leak guard afterwards "
                   "(train -8).")
    topics = sorted({t for s in SPLITS for t in subset["splits"][s]["topics"]},
                    key=lambda t: -subset["splits"]["train"]["topics"].get(t, 0))
    bar_chart(topics, {s: [subset["splits"][s]["topics"].get(t, 0) for t in topics] for s in SPLITS},
              "Algebra subset per topic (after the leak guard)", out / "chart_topics.png",
              note="One topic per formula, assigned by a rule on the LaTeX (not checked by hand).")
    vnames = {"A": "current filter", "B": "+ subscripts (x_n)", "C": "+ Greek letters", "D": "+ both"}
    bar_chart([vnames[v] for v in "ABCD"], {s: [variants[s].get(v, 0) for v in "ABCD"] for s in SPLITS},
              "Looser filters: formulas kept (counts only, before the leak guard)", out / "chart_looser.png",
              note="Greek letters added in C: gamma, delta, lambda, mu, sigma, phi, omega, epsilon.")

    counts = {"funnel": funnel, "leak_guard": guard, "removed_duplicates": duplicates, "variants": variants,
              "variant_topics": variant_topics, "subset": {s: subset["splits"][s] for s in SPLITS}}
    (out / "counts.json").write_text(json.dumps(counts, indent=1, ensure_ascii=False), encoding="utf-8")

    L = ["# im2latex-100k algebra subset: filtering report", "",
         "## Source and licence", "",
         "- im2latex-100k (Deng et al., 2017), Hugging Face copy `yuntian-deng/im2latex-100k`.",
         "- Licence: CC0-1.0 (public domain dedication), as stated in the dataset README.",
         "- Content: formulas taken from arXiv physics papers, rendered to images with LaTeX; published splits "
         "train / val / test.",
         "- Used for: a preliminary fine-tuning of the formula model (Track A) and a public check on its own test "
         "split. Not used to measure the app on real worksheets; our own phone captures are the main evaluation.", "",
         "## Filter rules (in plain words, applied in this order)", ""]
    L += [f"{i}. {text}" for i, (_, text) in enumerate(RULES, 1)]
    L += ["", "Then a leak guard between the splits: a training or validation formula is removed when the same image "
          "(byte-identical) or the same LaTeX (ignoring spaces) is in the test split; a training formula also when it "
          "is in the validation split.", "",
          "## Formulas left after each rule", "", "| step | " + " | ".join(SPLITS) + " |", "|---|---|---|---|"]
    for k in range(len(funnel["train"])):
        name = funnel["train"][k][0]
        cells = []
        for s in SPLITS:
            n, total = funnel[s][k][1], funnel[s][0][1]
            cells.append(f"{n:,} ({100 * n / total:.1f}%)")
        L.append(f"| {'after: ' + name if k else name} | " + " | ".join(cells) + " |")
    L.append("| after the leak guard | " + " | ".join(f"**{subset['splits'][s]['kept']:,}**" for s in SPLITS) + " |")
    L += ["", "Chart: `chart_funnel.png`.", "", "## Per topic (after the leak guard)", "",
          "| topic | " + " | ".join(SPLITS) + " |", "|---|---|---|---|"]
    for t_name in topics:
        L.append(f"| {t_name} | " + " | ".join(str(subset["splits"][s]["topics"].get(t_name, 0)) for s in SPLITS) + " |")
    L += ["", "Topic = the first rule that matches: f(x)/g(x)/h(x) -> function notation; <, >, \\le, \\ge, \\neq -> "
          "inequalities; \\sqrt -> radicals; \\frac -> fractions; = with a power of 2 -> quadratic equations; a power "
          "with + or - and no = -> polynomials; other powers -> exponents; the rest -> linear equations. Chart: "
          "`chart_topics.png`.", "",
          "## Leak guard", "",
          f"Removed {sum(sum(v.values()) for v in guard.values())} training formulas, each byte-identical to an image "
          "in another split: " + "; ".join(f"{s}: {dict(v) or 'none'}" for s, v in guard.items()) + ".", "",
          "| # | same image as | same LaTeX too | training LaTeX |", "|---|---|---|---|"]
    for i, dup in enumerate(duplicates, 1):
        L.append(f"| {i} | {dup['other_split']} | {'yes' if dup['same_latex'] else 'no'} | `{dup['train_latex']}` |")
    L += ["", f"## Examples (training split, fixed seed {args.seed})", "", "Kept (one per topic where possible; "
          "`examples_kept.png`, files `examples/kept_*.png`):", ""]
    for n, (_, latex, note) in enumerate(kept_items, 1):
        L.append(f"{n}. {note}: `{latex}`")
    L += ["", "Rejected, with the reason (`examples_rejected.png`, files `examples/rejected_*.png`):", ""]
    for n, (_, latex, note) in enumerate(rej_items, 1):
        L.append(f"{n}. {note}: `{latex if len(latex) < 160 else latex[:157] + '...'}`")
    L += ["", "## Limits", "",
          "- These are formulas from physics papers that pass the filter on syntax, not worksheet algebra "
          "(for example `F ^ { 2 } - 1 \\le 2 ( N ^ { 2 } - 1 ) + ...`).",
          "- The filter checks syntax only: some kept items are fragments or junk (kept example `T ( z ) =`; "
          "removed duplicate 1 is a row of = signs).",
          "- Printed and rendered cleanly; no phone photos, no handwriting.",
          "- Topics are assigned by a rule on the LaTeX and were not checked by hand; a formula belongs to one "
          "topic only.",
          "- The filter keeps 1.7% of the training split; the subset is small (945 / 104 / 120).",
          "- PP-FormulaNet was very likely trained on data from the same sources, so the test split is not an "
          "unseen test.", "",
          "## Looser filters (counts only; nothing trained on them)", "",
          "| variant | " + " | ".join(SPLITS) + " | train gain |", "|---|---|---|---|---|"]
    for v in "ABCD":
        gain = variants["train"].get(v, 0) - variants["train"].get("A", 0)
        L.append(f"| {v}: {vnames[v]} | " + " | ".join(f"{variants[s].get(v, 0):,}" for s in SPLITS)
                 + f" | {'+' if gain >= 0 else ''}{gain:,} |")
    L += ["", "Per topic, training split:", "", "| topic | A | B | C | D |", "|---|---|---|---|---|"]
    all_topics = sorted({t for v in "ABCD" for t in variant_topics["train"][v]},
                        key=lambda t: -variant_topics["train"]["D"].get(t, 0))
    for t_name in all_topics:
        L.append(f"| {t_name} | " + " | ".join(str(variant_topics["train"][v].get(t_name, 0)) for v in "ABCD") + " |")
    L += ["", "Counts before the leak guard (it removed 8 of 953 for A). B allows x_n, a_i, x_{n+1}, a_{12}; "
          "C adds gamma, delta, lambda, mu, sigma, phi, omega, epsilon. Chart: `chart_looser.png`."]
    (out / "report.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    print("\n".join(L))


if __name__ == "__main__":
    main()
