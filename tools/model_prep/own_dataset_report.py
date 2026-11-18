"""The "own dataset" section of the training report, from saved results only.

Nothing is trained or scored here. Reads the chosen run's comparison on the
frozen eval set, both candidates' comparisons on validation, the label table,
the training-set report and the finetune_changes.py analysis (weights.json,
confidence.json). Also measures, from saved readings, two things that limit how
far the result can be trusted: how close the labels and the fine-tuned model
are to PaddleOCR-VL, and whether any training image is a near-duplicate of a
held-out image.

From tools/model_prep, with paddle_onnx_env:

  python own_dataset_report.py --run <chosen run> --other-run <other candidate>
      --working <working folder> --extra-vl <older suggest_vl.json> [--page <html>]

Output: <run>/analysis/finetune_changes_<date>/ (own_dataset.json,
own_dataset_section.html, charts/own_*.png). Images of our data are not put in
the page: the examples show LaTeX only.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter
from pathlib import Path

from build_pseudo_labels import clean_reading, read_list  # also makes tools/dataset importable
from charts import bar_chart
from compare_formula import DECIDING_MODE, MODES, notation_key, notation_scores, read
from finalize_labels import unify_label
from finetune_changes import (EDIT_KINDS, KIND_LABELS, confidence_summary, data_uri, error_table, esc, gallery, habits,
                              pct, put_section, short_label, unchanged_modules)

SECTION_START, SECTION_END = "<!-- own-dataset:start -->", "<!-- own-dataset:end -->"
HEADER_LINK = ("<p class=\"note prose\" id=\"own-dataset-link\">The results on our own dataset are further down: "
               "<a href=\"#own-dataset\">fine-tuning on our own formula images</a>.</p>")
NOT_TOPICS = ("ALL", "labels:", "length", "source:")
MODE_NAMES = {"notation-normalized": "Main score (notation-normalized)", "spacing-normalized": "Spacing-normalized",
              "strict": "Strict"}


def share(right: int, items: int) -> str:
    return f"{right}/{items} ({100 * right / items:.1f}%)" if items else "not measured"


def topics_of(groups: dict) -> list[str]:
    return [g for g in groups if not g.startswith(NOT_TOPICS)]


def vl_agreement(labels: dict[str, str], before: dict[str, str], after: dict[str, str],
                 vl: dict[str, str | None]) -> dict:
    """How close the labels and the fine-tuned model are to PaddleOCR-VL (notation-normalized)."""
    k = notation_key
    have = {n: vl[n] for n in labels if vl.get(n) is not None}
    differs = [n for n, v in have.items() if k(v) != k(labels[n])]
    return {"items": len(labels), "with_vl_reading": len(have),
            "labels_equal_to_vl": len(have) - len(differs),
            "fine_tuned_equal_to_vl": sum(k(v) == k(after[n]) for n, v in have.items()),
            "vl_differs_from_label": len(differs),
            "there_original_right": sum(k(before[n]) == k(labels[n]) for n in differs),
            "there_fine_tuned_right": sum(k(after[n]) == k(labels[n]) for n in differs),
            "there_fine_tuned_equal_to_vl": sum(k(after[n]) == k(have[n]) for n in differs)}


def near_duplicates(held: list[str], train: list[str], items: dict[str, dict]) -> int:
    import dataset_common as dc
    pool = [items[t]["dhash"] for t in train if items[t]["dhash"]]
    return sum(dc.is_near_duplicate(items[n]["dhash"], b) for n in held if items[n]["dhash"] for b in pool)


def read_vl(working: Path, extra: Path | None) -> dict[str, str | None]:
    rows = {}
    if extra:
        rows.update({p["id"]: p for p in json.loads(extra.read_text(encoding="utf-8"))["predictions"]})
    for line in (working / "suggest_vl.jsonl").read_text(encoding="utf-8").splitlines():
        p = json.loads(line)
        rows[p["id"]] = p
    return {n: unify_label(clean_reading(p["blocks"][0].get("content", ""))) if len(p.get("blocks", [])) == 1 else None
            for n, p in rows.items()}


def by_name(rows: dict[str, dict]) -> dict[str, str]:
    return {Path(i).name: r["prediction"] for i, r in rows.items()}


def label_sources(rows: list[dict]) -> dict:
    kept = [r for r in rows if r["status"] == "checked"]
    def count(split, test):
        return sum(r["split"] == split and test(r["provenance"]) for r in kept)
    return {"eval_accepted": count("eval", lambda p: p == "human-verified"),
            "eval_convention": count("eval", lambda p: p.startswith("human-verified,")),
            "eval_approved_fix": count("eval", lambda p: p.startswith("human-approved")),
            "val_human": count("val", lambda p: not p.startswith("AI")),
            "val_ai": count("val", lambda p: p.startswith("AI")),
            "excluded": dict(Counter(r["split"] for r in rows if r["status"] == "exclude"))}


def collect(args) -> dict:
    run, other, w = args.run, args.other_run, args.working
    analysis = sorted((run / "analysis").glob("finetune_changes_*"))[-1]
    final = json.loads((run / "evaluation" / "comparison.json").read_text(encoding="utf-8"))
    val = {r.name: json.loads((r / "evaluation" / "validation" / "comparison.json").read_text(encoding="utf-8"))
           for r in (run, other)}
    before, after = read(Path(final["before"])), read(Path(final["after"]))
    val_before = read(Path(val[run.name]["before"]))
    val_after = read(Path(val[run.name]["after"]))
    vl = read_vl(w, args.extra_vl)
    labels = {n: {Path(i).name: t for i, t in read_list(w / "labels" / f"{n}.txt")} for n in ("eval", "val_all")}
    items = {r["filename"]: r for r in csv.DictReader((w / "items.csv").open(encoding="utf-8"))}
    train = [Path(i).name for i, _ in read_list(w / "train_sets" / "v2" / "train.txt")]
    rows = list(csv.DictReader((w / "labels" / "labels.csv").open(encoding="utf-8")))
    confidence = json.loads((analysis / "confidence.json").read_text(encoding="utf-8"))
    return {
        "analysis": analysis, "run": run, "other": other, "final": final, "val": val,
        "before": before, "after": after, "groups": gallery(before, after, notation_scores),
        "errors": {"original": error_table(before), "fine-tuned": error_table(after)},
        "habits": habits(before, after), "weights": json.loads((analysis / "weights.json").read_text(encoding="utf-8")),
        "unchanged": unchanged_modules(analysis / "weights_per_parameter.csv"),
        "confidence": confidence_summary(confidence, notation_scores),
        "training": json.loads((w / "train_sets" / "report.json").read_text(encoding="utf-8")),
        "meta": json.loads((run / "run.json").read_text(encoding="utf-8")),
        "sources": label_sources(rows),
        "vl_eval": vl_agreement(labels["eval"], by_name(before), by_name(after), vl),
        "vl_val": vl_agreement(labels["val_all"], by_name(val_before), by_name(val_after), vl),
        "near_duplicates": {n: near_duplicates(list(labels[n]), train, items) for n in labels},
    }


def table(head: list[str], rows: list[list], first_is_header: bool = True) -> str:
    cells = "".join("<tr>" + "".join((f"<th scope='row'>{c}</th>" if i == 0 and first_is_header else f"<td>{c}</td>")
                                     for i, c in enumerate(r)) + "</tr>" for r in rows)
    return ("<div class='tablewrap'><table><thead><tr>" + "".join(f"<th>{esc(h)}</th>" for h in head)
            + "</tr></thead><tbody>" + cells + "</tbody></table></div>")


def text_card(item: dict, status: str) -> str:
    def line(label, latex, kind=None):
        pill = "" if label == "Correct" else (f" <span class='pill bad'>{esc(kind)}</span>" if kind
                                              else " <span class='pill ok'>right</span>")
        return f"<div><span class='tag'>{label}</span>{pill}<br><code>{esc(latex)}</code></div>"
    return (f"<figure class='ex {status}'><figcaption><div class='note'>{esc(Path(item['image']).stem)}</div>"
            + line("Correct", item["target"]) + line("Original model", item["original"], item["error_original"])
            + line("Fine-tuned", item["fine-tuned"], item["error_fine-tuned"]) + "</figcaption></figure>")


def cards(items: list[dict], status: str) -> str:
    return "<div class='examples'>" + "".join(text_card(i, status) for i in items) + "</div>"


def regression_table(regressions: list[dict]) -> str:
    if not regressions:
        return "<p class='prose'>None.</p>"
    return table(["Image", "Kind", "Simple?", "Correct", "Original model", "Fine-tuned"],
                 [[esc(Path(r["image"]).stem), esc(r["kind"]), "yes" if r["simple"] else "no", f"<code>{esc(r['target'])}</code>",
                   f"<code>{esc(r['before'])}</code>", f"<code>{esc(r['after'])}</code>"]
                  for r in sorted(regressions, key=lambda r: (r["kind"], r["image"]))])


def make_charts(d: dict) -> Path:
    charts = d["analysis"] / "charts"
    charts.mkdir(exist_ok=True)
    groups = d["final"][DECIDING_MODE]["groups"]
    topics = topics_of(groups)
    bar_chart(topics, {"original": [groups[t]["exact_before"] for t in topics],
                       "fine-tuned": [groups[t]["exact_after"] for t in topics]},
              "Right readings per topic, frozen eval set", charts / "own_topics.png",
              note="main score; " + ", ".join(f"{t} {groups[t]['items']}" for t in topics) + " formulas")
    kinds = list(KIND_LABELS.values()) + EDIT_KINDS
    bar_chart([k.replace("Same meaning, different notation", "Other notation, same") for k in kinds],
              {t: [d["errors"][t]["kinds"].get(k, 0) for k in kinds] for t in d["errors"]},
              f"Strictly wrong readings by kind (of {len(d['before'])})", charts / "own_error_types.png",
              note="frozen eval set; each wrong reading counted once")
    modules = d["weights"]["modules"]
    bar_chart([short_label(m["module"]) for m in modules],
              {"weight change, % of size": [round(100 * m["relative_change"], 2) for m in modules]},
              "How much each part of the model changed", charts / "own_weight_change.png",
              note=f"||after - before|| / ||before||; overall {100 * d['weights']['overall_relative_change']:.2f}%")
    return charts


def section(d: dict, charts: Path) -> str:
    final, val = d["final"], d["val"]
    rule = final[DECIDING_MODE]["rule"]
    main = final[DECIDING_MODE]
    all_main = main["groups"]["ALL"]
    items = all_main["items"]
    objects = main["object_object"]
    train, s, ev, vv = d["training"], d["sources"], d["vl_eval"], d["vl_val"]
    run_args = d["meta"]["args"]
    t = d["meta"]["train"]
    best = max(range(len(t["validations"])), key=lambda i: (t["validations"][i]["exp_rate"], -i))
    n_val = t["val_items"]

    def img(path, alt, caption):
        return (f"<figure><img src='{data_uri(path.read_bytes())}' alt='{esc(alt)}' loading='lazy'>"
                f"<figcaption>{caption}</figcaption></figure>") if path.exists() else ""

    def before_after(group, mode=DECIDING_MODE, source=final):
        g = source[mode]["groups"][group]
        return share(g["exact_before"], g["items"]), share(g["exact_after"], g["items"])

    score_rows = [[esc(MODE_NAMES[m]), *before_after("ALL", m), final[m]["groups"]["ALL"]["got_better"],
                   final[m]["groups"]["ALL"]["got_worse"]] for m in MODES]
    accepted = "labels: human-reviewed, accepted on the page"
    subset_rows = [[f"Labels accepted on the page ({main['groups'][accepted]['items']} of {items})", *before_after(accepted),
                    main["groups"][accepted]["got_better"], main["groups"][accepted]["got_worse"]]]
    topic_rows = [[esc(g), *before_after(g), main["groups"][g]["got_better"], main["groups"][g]["got_worse"]]
                  for g in topics_of(main["groups"])]
    sizes = [main["groups"][g]["items"] for g in topics_of(main["groups"])]
    source_rows = [[{"source: cap": "Phone captures", "source: ss": "Screenshots"}[g], *before_after(g),
                    main["groups"][g]["got_better"], main["groups"][g]["got_worse"]]
                   for g in ("source: cap", "source: ss")]

    chosen, other = val[d["run"].name], val[d["other"].name]
    def val_row(name, group, mode=DECIDING_MODE):
        c, o = chosen[mode]["groups"][group], other[mode]["groups"][group]
        return [name, esc(MODE_NAMES[mode]), share(c["exact_before"], c["items"]), share(o["exact_after"], o["items"]),
                share(c["exact_after"], c["items"])]
    val_rows = [val_row("All 140", "ALL"), val_row("All 140", "ALL", "spacing-normalized"), val_row("All 140", "ALL", "strict"),
                val_row("46 human-reviewed", "labels: human-reviewed"),
                val_row("94 AI-reviewed", "labels: AI-reviewed (Claude)")]

    kinds = list(KIND_LABELS.values()) + EDIT_KINDS
    e = d["errors"]
    error_rows = [[esc(k), e["original"]["kinds"].get(k, 0), e["fine-tuned"]["kinds"].get(k, 0)] for k in kinds]
    habit_rows = [[f"<code>{esc(h['command'])}</code>", h["target"], h["original"], h["fine-tuned"]] for h in d["habits"]]
    w = d["weights"]
    tokens = w["tokens"]
    module_rows = [[esc(m["module"]), f"{m['values']:,}", pct(m["relative_change"], 3)] for m in w["modules"]]
    biggest = max(w["modules"], key=lambda m: m["relative_change"])
    stats = [m["relative_change"] for m in w["statistics"]]
    next_biggest = max(m["relative_change"] for m in w["modules"] if m is not biggest)
    top_seen = sum(x["times_in_training_labels"] > 0 for x in tokens["top"])
    c = d["confidence"]
    onnx_val = chosen[DECIDING_MODE]["groups"]["ALL"]
    def low_high(v):
        low, high = v["bins"]["0.00-0.50"], [sum(x) for x in zip(v["bins"]["0.95-0.99"], v["bins"]["0.99-1.00"])]
        return [f"{low[1]} wrong, {low[0]} right", f"{high[1]} wrong, {high[0]} right"]
    conf_rows = [[esc(tag), share(v["right"], v["items"]), pct(v["weakest_right"], 1), pct(v["weakest_wrong"], 1), *low_high(v)]
                 for tag, v in c.items()]
    g = d["groups"]
    reasons = ", ".join(f"{esc(k)} {v}" for k, v in sorted(train["rejected_reasons"].items(), key=lambda kv: -kv[1]))
    train_rows = [["Both models agree (version 1)", train["groups"].get("agreed", 0)],
                  ["They disagree; PaddleOCR-VL's reading passes the basic checks (added in version 2)", train["groups"].get("teacher", 0)],
                  ["Left out: PaddleOCR-VL's reading fails the basic checks", train["groups"].get("rejected", 0)],
                  ["Left out: label equals an eval or validation label", train["groups"].get("leak guard", 0)]]
    passed = final["passed"]

    return "\n".join([
        "<h2 id='own-dataset'>Fine-tuning on our own formula images</h2>",
        f"<div class='verdict{' ok' if passed else ''}'><strong>{'The fine-tuned model passes' if passed else 'The fine-tuned model does not pass'} "
        f"the adoption rule on the frozen eval set: {all_main['exact_before']} &rarr; {all_main['exact_after']} of {items} "
        f"formulas right.</strong> It has not been put in the app. Its accuracy on the phone and its effect on the Braille "
        "output were not measured.</div>",
        "<div class='facts'>"
        f"<div class='fact'><b>{100 * all_main['exact_before'] / items:.1f}% &rarr; {100 * all_main['exact_after'] / items:.1f}%</b>"
        f"<span>right on the main score, {items} eval formulas</span></div>"
        f"<div class='fact'><b>{all_main['got_better']} / {all_main['got_worse']}</b><span>formulas fixed / broken by fine-tuning</span></div>"
        f"<div class='fact'><b>{rule['simple_regressions']} of {rule['simple_items']}</b><span>simple formulas got worse "
        f"(the rule allows {rule['allowed_simple_regressions']})</span></div>"
        f"<div class='fact'><b>{objects['before']} &rarr; {objects['after']}</b><span>eval readings containing the model's "
        "<code>[object Object]</code> error</span></div></div>",
        "<h3>Results on the frozen eval set</h3>",
        f"<p class='prose'>The original offline model and the chosen fine-tuned model read the same {items} images. These "
        "images and their labels were never used for training or for choosing a model, and the fine-tuned model was scored "
        "on them once. The main score, chosen before any fine-tuned model was scored, counts equivalent notation as equal (for example "
        "<code>\\le</code> and <code>\\leq</code>), because most labels began as PaddleOCR-VL readings and a stricter score "
        "would reward copying its writing style. The other two scores are shown beside it.</p>",
        table(["Score", "Original", "Fine-tuned", "Fixed", "Broken"], score_rows + subset_rows),
        "<h3>Where the labels come from</h3>",
        "<ul class='limits prose'>"
        f"<li><strong>Eval, human-reviewed ({items}):</strong> {s['eval_accepted']} accepted by a team member on the review "
        f"page as they were, {s['eval_convention']} accepted there and then given a writing-convention fix, and "
        f"{s['eval_approved_fix']} corrections proposed by Claude and approved by a team member. "
        f"{s['excluded'].get('eval', 0)} unusable images were excluded.</li>"
        f"<li><strong>Validation, human and AI-reviewed ({s['val_human'] + s['val_ai']}):</strong> {s['val_human']} "
        f"human-reviewed and {s['val_ai']} reviewed by Claude, not checked by a person. "
        f"{s['excluded'].get('val', 0)} unusable images were excluded.</li>"
        f"<li><strong>Training, pseudo-labels ({train['v2_items']:,} images):</strong> machine readings nobody checked, "
        f"plus {train['synthetic_items']:,} synthetic formulas to draw from.</li></ul>",
        "<h3>How far to trust this</h3>",
        "<ul class='limits prose'>"
        f"<li>The eval set is small: {items} formulas, and {min(sizes)} to {max(sizes)} per topic. Treat topic numbers as "
        "low confidence.</li>"
        f"<li>The labels are not independent of PaddleOCR-VL, which also taught this model. {ev['labels_equal_to_vl']} of the "
        f"{items} eval labels equal its reading, and the fine-tuned model equals its reading on {ev['fine_tuned_equal_to_vl']}. "
        "A person accepted those labels, but the score cannot separate &ldquo;reads correctly&rdquo; from &ldquo;reads like "
        f"PaddleOCR-VL&rdquo; on them. On the {ev['vl_differs_from_label']} eval formulas where its reading differs from the "
        f"final label, the original model is right on {ev['there_original_right']}, the fine-tuned model on "
        f"{ev['there_fine_tuned_right']}, and the fine-tuned model repeats PaddleOCR-VL's different reading on "
        f"{ev['there_fine_tuned_equal_to_vl']}.</li>"
        f"<li>No leak found: {train['training_labels_equal_to_held_out']} training labels and "
        f"{train['training_images_equal_to_held_out']} training images equal an eval or validation item, and "
        f"{d['near_duplicates']['eval']} (eval) and {d['near_duplicates']['val_all']} (validation) near-duplicate image pairs "
        "were found against the training images.</li>"
        "<li>Scored on the laptop with the app's preprocessing, on images from this one delivery. New worksheets or "
        "cameras were not tested.</li></ul>",
        "<h3>Results per topic and source</h3>",
        "<p class='prose note'>Main score. Low confidence: each row has few formulas.</p>",
        "<div class='charts'>" + img(charts / "own_topics.png", "Right eval readings per topic, before and after",
                                     "Right readings per topic on the frozen eval set, original vs fine-tuned.") + "</div>",
        table(["Group", "Original", "Fine-tuned", "Fixed", "Broken"], topic_rows + source_rows),
        "<h3>Every regression</h3>",
        f"<p class='prose'>A regression is a formula the original model read correctly and the fine-tuned model does not. "
        f"On the main score there are {len(main['regressions'])}; these decide the rule. All are sorted as meaning-changing "
        "when any symbol differs, which is deliberately conservative.</p>",
        regression_table(main["regressions"]),
        f"<p class='prose'>On the strict score, which also counts spacing and notation differences, there are "
        f"{len(final['strict']['regressions'])}:</p>",
        regression_table(final["strict"]["regressions"]),
        "<h3>How the model was chosen</h3>",
        "<p class='prose'>Two versions were trained, differing only in their pseudo-labels. Version 1 uses images where the "
        "offline model and PaddleOCR-VL read the same formula. Version 2 adds images where they disagree, using "
        "PaddleOCR-VL's reading if it passes basic checks. The rule, written down before training: the higher main score on "
        "all 140 validation formulas wins. Version 2 won. Validation also picked each model's best epoch, so these numbers "
        "are on the kind side; the eval results above are the ones to quote.</p>",
        table(["Validation set", "Score", "Original", "Version 1", "Version 2 (chosen)"], val_rows, first_is_header=True),
        "<div class='charts'>" + img(d["run"] / "charts" / "validation_history.png", "Validation score per epoch",
                                     "Version 2 during training. PaddleOCR's own exact-match score, which is stricter than "
                                     "the main score.") + "</div>",
        "<h3>Training data</h3>",
        table(["Training images (" + f"{train['train_images']:,}" + ")", "Count"], train_rows),
        f"<p class='prose'>Basic-check failures: {reasons}. Settings: batch {run_args['batch_size']}, learning rate "
        f"{run_args['lr']}, up to {run_args['epochs']} epochs with patience {run_args['patience']}, and each epoch "
        f"{t['train_items']:,} real images plus about as many synthetic ones. The best epoch was "
        f"{best + 1} ({round(t['validations'][best]['exp_rate'] * n_val)}/{n_val} on PaddleOCR's score).</p>",
        "<h3>What changed inside the model</h3>",
        f"<p class='prose'>The most change was in <strong>{esc(biggest['module'].lower())}</strong> "
        f"({pct(biggest['relative_change'])} of its size). Every other part moved {pct(next_biggest, 1)} or less. That one "
        f"large layer dominates the overall figure of {pct(w['overall_relative_change'])}. A bigger number shows where "
        "training pushed, not how much that part matters for accuracy."
        + (f" Batch-norm image statistics, which are not learned weights, moved {pct(min(stats), 1)} to {pct(max(stats), 1)}."
           if stats else "") + "</p>",
        "<div class='charts'>" + img(charts / "own_weight_change.png", "Weight change per module",
                                     "Weight change per part of the model.") + "</div>",
        "<details><summary>Weight change per module, with sizes</summary>"
        + table(["Module", "Values", "Change"], module_rows) + "</details>",
        ("<p class='prose'>No weight moved at all in: " + ", ".join(esc(m.lower()) for m in d["unchanged"]) + ".</p>"
         if d["unchanged"] else ""),
        f"<p class='prose'>{tokens['in_training_labels']:,} of the {tokens['vocabulary']:,} tokens the model can write occur "
        f"in the training labels. Their output weights moved a median {pct(tokens['median_change_seen'], 3)}; the tokens that "
        f"never occur moved {pct(tokens['median_change_unseen'], 3)}. So most of the output layer's change is in tokens "
        f"this data never uses: {top_seen} of the {len(tokens['top'])} most-changed tokens occur in the training labels. "
        "The cause was not measured.</p>",
        "<h3>Kinds of mistakes, before and after</h3>",
        f"<p class='prose'>Every eval reading that is not letter-for-letter right, sorted once. Strictly wrong: "
        f"{e['original']['wrong_strict']} &rarr; {e['fine-tuned']['wrong_strict']} of {items}.</p>",
        "<div class='charts'>" + img(charts / "own_error_types.png", "Strictly wrong eval readings by kind",
                                     "Strictly wrong readings by kind (&ldquo;other notation, same&rdquo; is same "
                                     "meaning, different notation).") + "</div>",
        table(["Kind", "Original", "Fine-tuned"], error_rows),
        "<details><summary>Commands in the eval formulas</summary>"
        + table(["Command", "Correct LaTeX", "Original", "Fine-tuned"], habit_rows) + "</details>",
        "<h3>How sure the model is</h3>",
        f"<p class='prose'>Measured on the {c['original']['items']} validation formulas, which also chose the epoch. The "
        "score is the probability of the weakest symbol in a reading. A low score points to a wrong reading; with this few "
        "formulas, a high score is not proof of a right one. This was run in the training framework, while the scores above "
        f"use the exported ONNX models, where the same formulas give {onnx_val['exact_before']} (original) and "
        f"{onnx_val['exact_after']} (fine-tuned) right.</p>",
        table(["Model", "Right (main score)", "Weakest symbol, right", "Weakest symbol, wrong", "Below 0.50", "0.95 or above"],
              conf_rows),
        "<h3>Examples</h3>",
        f"<p class='prose'>From the frozen eval set, on the main score: {len(g.get('fixed', []))} fixed, "
        f"{len(g.get('broken', []))} broken, {len(g.get('both wrong', []))} wrong both times, "
        f"{len(g.get('both right', []))} right both times. LaTeX only: images from our dataset are not published here.</p>",
        "<h3>Broken by fine-tuning</h3>" + cards(g.get("broken", []), "rejected"),
        "<h3>Fixed by fine-tuning</h3>" + cards(g.get("fixed", [])[:6], "kept"),
        f"<details><summary>The other {max(0, len(g.get('fixed', [])) - 6)} fixed</summary>"
        + cards(g.get("fixed", [])[6:], "kept") + "</details>",
        f"<details><summary>Wrong both times ({len(g.get('both wrong', []))})</summary>"
        + cards(g.get("both wrong", []), "rejected") + "</details>",
        f"<p class='note prose'>From run <code>{esc(d['run'].name)}</code> (chosen) and <code>{esc(d['other'].name)}</code>, "
        "by <code>tools/model_prep/own_dataset_report.py</code>.</p>",
    ])


def add_to_page(page: str, text: str) -> str:
    page = put_section(page, text, SECTION_START, SECTION_END)
    if "id=\"own-dataset-link\"" not in page:
        if "</header>" not in page:
            raise SystemExit("the page has no </header>")
        page = page.replace("</header>", f"  {HEADER_LINK}\n</header>", 1)
    return page


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--run", required=True, type=Path, help="the chosen run folder")
    parser.add_argument("--other-run", required=True, type=Path, help="the candidate that was not chosen")
    parser.add_argument("--working", required=True, type=Path)
    parser.add_argument("--extra-vl", type=Path, help="earlier local_vl_worker.py JSON")
    parser.add_argument("--page", type=Path, help="HTML page to put the section into")
    args = parser.parse_args()

    d = collect(args)
    text = section(d, make_charts(d))
    out = d["analysis"]
    (out / "own_dataset_section.html").write_text(text, encoding="utf-8", newline="\n")
    summary = {k: d[k] for k in ("sources", "vl_eval", "vl_val", "near_duplicates", "errors", "habits", "confidence", "unchanged")}
    summary.update(run=d["run"].name, other_run=d["other"].name, gallery_counts={k: len(v) for k, v in d["groups"].items()},
                   rule=d["final"][DECIDING_MODE]["rule"], passed=d["final"]["passed"],
                   object_object=d["final"][DECIDING_MODE]["object_object"])
    (out / "own_dataset.json").write_text(json.dumps(summary, indent=1, ensure_ascii=False), encoding="utf-8", newline="\n")
    if args.page:
        args.page.write_text(add_to_page(args.page.read_text(encoding="utf-8"), text), encoding="utf-8", newline="\n")
        print(f"section written into {args.page}")
    print(f"-> {out}")


if __name__ == "__main__":
    main()
