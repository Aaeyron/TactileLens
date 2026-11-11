"""Offline formula model vs the online VL model on the same formulas, from
saved readings only (nothing is run, nothing is scored again).

  python compare_online_offline.py --offline <evaluate_formula.py folder> --online <evaluate_vl.py folder>
      [--out <folder>] [--page <html>]

Run with paddle_onnx_env (it uses tools/model_prep's scoring). Reports, per
group (all, topic, formula length): strict and spacing-normalized exact
match for both; how each reading differs from the target; time per
formula; and agreement as a review signal: when the two readings agree
(spacing-normalized), how often they are right, and what a "flag when
they disagree" rule would catch and wrongly flag for the offline reading.

Consistency check: the strict score recomputed here from the saved text
must equal each tool's own exact column, or the script stops.

Output: <online folder>/comparison_offline/ (comparison.json, comparison.md,
section.html); --page puts the section into a page between markers
(re-running replaces it).
"""

from __future__ import annotations

import argparse
import csv
import html
import json
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "model_prep"))
sys.path.insert(0, str(HERE.parent / "training"))

import vl_common  # noqa: E402

START, END = "<!-- online-vs-offline:start -->", "<!-- online-vs-offline:end -->"
KINDS = ["right (strict)", "spacing only", "same meaning, other notation", "meaning-changing"]


def read_tsv(path: Path) -> list[dict]:
    with open(path, encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE))


def strict(target: str, prediction: str) -> bool:
    return vl_common.normalize_for_compare("formula", target) == vl_common.normalize_for_compare("formula", prediction)


def agreement(rows: list[tuple[str, str, str]], right, same) -> dict:
    """rows: (target, offline, online). right(target, reading) and
    same(a, b) decide right and agree. The flag rule flags the offline
    reading whenever the two readings differ."""
    n = len(rows)
    agree = [r for r in rows if same(r[1], r[2])]
    differ = [r for r in rows if not same(r[1], r[2])]
    agree_right = sum(right(t, o) for t, o, _ in agree)
    differ_off_wrong = sum(not right(t, o) for t, o, _ in differ)
    differ_online_right = sum(right(t, v) for t, _, v in differ)
    off_wrong = sum(not right(t, o) for t, o, _ in rows)
    return {"items": n, "agree": len(agree), "agree_right": agree_right, "agree_wrong": len(agree) - agree_right,
            "disagree": len(differ), "disagree_offline_wrong": differ_off_wrong,
            "disagree_offline_right": len(differ) - differ_off_wrong, "disagree_online_right": differ_online_right,
            "offline_wrong": off_wrong, "offline_right": n - off_wrong,
            "flag_catches": differ_off_wrong, "flag_misses": off_wrong - differ_off_wrong,
            "flag_false_alarms": len(differ) - differ_off_wrong}


def compare(offline: dict[str, dict], online: dict[str, dict]) -> dict:
    from compare_formula import MEANING, classify, spacing_key, spacing_scores
    from evaluate_formula import length_group, topic_of

    if offline.keys() != online.keys():
        raise SystemExit(f"different images: {len(offline.keys() ^ online.keys())} not in both")
    for image in offline:
        if offline[image]["target"] != online[image]["target"]:
            raise SystemExit(f"{image}: different targets")
    mismatch = {name: sum(strict(r["target"], r["prediction"]) != (r["exact"] == "True") for r in rows.values())
                for name, rows in (("offline", offline), ("online", online))}
    if any(mismatch.values()):
        raise SystemExit(f"recomputed strict score differs from the saved exact column: {mismatch}")

    models = {"offline": offline, "online": online}
    groups = defaultdict(lambda: {m: {"items": 0, "strict": 0, "spacing": 0} for m in models})
    kinds = {m: dict.fromkeys(KINDS, 0) for m in models}
    for image in sorted(offline):
        target = offline[image]["target"]
        for m, rows in models.items():
            p = rows[image]["prediction"]
            s, n = strict(target, p), spacing_scores(target, p)[0]
            for g in ("ALL", topic_of(image), length_group(target)):
                groups[g][m]["items"] += 1
                groups[g][m]["strict"] += s
                groups[g][m]["spacing"] += n
            kinds[m]["right (strict)" if s else "spacing only" if n else
                     "same meaning, other notation" if classify(target, p) != MEANING else "meaning-changing"] += 1
    rows = [(offline[i]["target"], offline[i]["prediction"], online[i]["prediction"]) for i in sorted(offline)]
    signal = agreement(rows, lambda t, p: spacing_scores(t, p)[0], lambda a, b: spacing_key(a) == spacing_key(b))
    return {"items": len(offline), "groups": dict(groups), "kinds": kinds, "agreement": signal}


def timing(offline_dir: Path, online: dict[str, dict], online_run: dict) -> dict:
    found = re.search(r"median (\d+) ms per formula", (offline_dir / "results.md").read_text(encoding="utf-8"))
    times = sorted(float(r["seconds"]) for r in online.values() if r.get("seconds"))
    return {"offline_median_ms": int(found.group(1)) if found else None,
            "online_median_ms": round(1000 * statistics.median(times)) if times else None,
            "online_mean_ms": round(1000 * statistics.mean(times)) if times else None,
            "online_p90_ms": round(1000 * times[int(0.9 * (len(times) - 1))]) if times else None,
            "online_load_seconds": online_run.get("load_seconds"),
            "online_errors": sum(bool(r.get("error")) for r in online.values()),
            "online_mode": online_run.get("mode")}


def put_section(page: str, section: str) -> str:
    block = f"{START}\n{section}\n{END}"
    if START in page:
        return page[:page.index(START)] + block + page[page.index(END) + len(END):]
    at = page.find("<footer")
    if at < 0:
        raise SystemExit("the page has no <footer>; nowhere to put the section")
    return page[:at] + block + "\n\n" + page[at:]


def frac(v: dict, key: str) -> str:
    return f"{v[key]}/{v['items']}"


def order(groups: dict) -> list[str]:
    lengths = [g for g in ("length <=20 (simple)", "length 21-40", "length >40") if g in groups]
    return sorted(g for g in groups if g != "ALL" and not g.startswith("length")) + lengths


def markdown(s: dict) -> str:
    g, a, t = s["groups"], s["agreement"], s["timing"]
    lines = [f"# Offline formula model vs online VL model ({s['items']} formulas)", "",
             "| group | offline strict | online strict | offline spacing-norm. | online spacing-norm. |",
             "|---|---|---|---|---|"]
    lines += [f"| {k} | {frac(g[k]['offline'], 'strict')} | {frac(g[k]['online'], 'strict')} | "
              f"{frac(g[k]['offline'], 'spacing')} | {frac(g[k]['online'], 'spacing')} |" for k in ["ALL"] + order(g)]
    lines += ["", "| reading | offline | online |", "|---|---|---|"]
    lines += [f"| {k} | {s['kinds']['offline'][k]} | {s['kinds']['online'][k]} |" for k in KINDS]
    lines += ["", f"Time per formula: offline median {t['offline_median_ms']} ms; online median {t['online_median_ms']} ms, "
              f"mean {t['online_mean_ms']} ms, 90th percentile {t['online_p90_ms']} ms; online model load "
              f"{t['online_load_seconds']} s; online errors {t['online_errors']}.", "",
              "## Agreement as a review signal (spacing-normalized)", "",
              f"- Agree: {a['agree']}/{a['items']}; right when they agree: {a['agree_right']}/{a['agree']}.",
              f"- Disagree: {a['disagree']}; offline reading wrong: {a['disagree_offline_wrong']}/{a['disagree']}; "
              f"online reading right: {a['disagree_online_right']}/{a['disagree']}.",
              f"- Flag when they disagree: catches {a['flag_catches']} of {a['offline_wrong']} offline errors, misses "
              f"{a['flag_misses']}; flags {a['flag_false_alarms']} of {a['offline_right']} right offline readings."]
    return "\n".join(lines) + "\n"


def section_html(s: dict) -> str:
    esc = html.escape
    g, a, t = s["groups"], s["agreement"], s["timing"]
    A = g["ALL"]
    rows = "".join(f"<tr><th scope='row'>{esc(k.replace('_', ' '))}</th><td>{g[k]['offline']['items']}</td>"
                   f"<td>{frac(g[k]['offline'], 'strict')}</td><td>{frac(g[k]['online'], 'strict')}</td>"
                   f"<td>{frac(g[k]['offline'], 'spacing')}</td><td>{frac(g[k]['online'], 'spacing')}</td></tr>"
                   for k in order(g))
    kind_rows = "".join(f"<tr><th scope='row'>{esc(k.capitalize())}</th><td>{s['kinds']['offline'][k]}</td>"
                        f"<td>{s['kinds']['online'][k]}</td></tr>" for k in KINDS)
    pct = lambda x, y: f"{100 * x / y:.0f}%" if y else "n/a"  # noqa: E731
    online_ms = f"{t['online_median_ms']:,} ms" if t["online_median_ms"] is not None else "not measured"
    return f"""<h2 id='online-vs-offline'>Online vs offline model on the same test formulas</h2>
<p class='prose'>The app has two formula readers. <strong>Offline</strong>: PP-FormulaNet_plus-S, the small model that runs on
the phone (the shipped model, not the fine-tuned one). <strong>Online</strong>: PaddleOCR-VL-1.6, the large vision-language
model the online pipeline uses, run here on the laptop's GPU with the formula prompt on each cropped image (no layout
detection). Both read the same {s['items']} im2latex test formulas; the online model was scored on them once. No training,
no app changes.</p>
<div class='facts'>
  <div class='fact'><b>{A['offline']['strict']} &rarr; {A['online']['strict']}</b><span>strictly right of {A['offline']['items']}: offline &rarr; online</span></div>
  <div class='fact'><b>{A['offline']['spacing']} &rarr; {A['online']['spacing']}</b><span>spacing-normalized: offline &rarr; online</span></div>
  <div class='fact'><b>{t['offline_median_ms']} ms</b><span>offline, median per formula (laptop CPU, 4 threads)</span></div>
  <div class='fact'><b>{online_ms}</b><span>online, median per formula (laptop GPU)</span></div>
</div>
<p class='prose'>Spacing-normalized ignores LaTeX spacing commands, as in the runs above. The two times come from
different hardware, so they are not a speed race: the offline time is on the laptop CPU at the phone's thread count
(the phone itself was not timed here), the online time is the laptop GPU and leaves out the {t['online_load_seconds']} s it
took to load the model once, and any network time a real online request would add.</p>
<h3>Per topic and length</h3>
<div class='tablewrap'><table><thead><tr><th>Group</th><th>Items</th><th>Offline, strict</th><th>Online, strict</th>
<th>Offline, spacing-normalized</th><th>Online, spacing-normalized</th></tr></thead><tbody>{rows}</tbody></table></div>
<h3>How the readings differ from the correct LaTeX</h3>
<p class='prose'>Each of the {s['items']} readings counted once.</p>
<div class='tablewrap'><table><thead><tr><th>Reading</th><th>Offline</th><th>Online</th></tr></thead><tbody>{kind_rows}</tbody></table></div>

<h2 id='review-signal'>Agreement as a review signal</h2>
<p class='prose'>Idea: when the phone is online, read each formula with both models; if the two readings agree, trust the
offline reading; if they differ, ask the student to check it. Measured on the same {a['items']} test formulas from the saved
readings (no new runs). Agree and right are both spacing-normalized. Not built in the app.</p>
<div class='facts'>
  <div class='fact'><b>{a['agree']}/{a['items']}</b><span>readings agree ({pct(a['agree'], a['items'])})</span></div>
  <div class='fact'><b>{a['agree_right']}/{a['agree']}</b><span>right when they agree ({pct(a['agree_right'], a['agree'])})</span></div>
  <div class='fact'><b>{a['disagree_offline_wrong']}/{a['disagree']}</b><span>offline reading wrong when they disagree</span></div>
  <div class='fact'><b>{a['flag_catches']} of {a['offline_wrong']}</b><span>offline errors a disagree flag catches</span></div>
</div>
<p class='prose'>A &ldquo;flag when they disagree&rdquo; rule would flag {a['disagree']} of {a['items']} readings. It catches
{a['flag_catches']} of the offline model's {a['offline_wrong']} wrong readings and misses {a['flag_misses']}: those are
cases where both models made the same mistake. It also flags {a['flag_false_alarms']} of the
{a['offline_right']} right offline readings, where the online model was the one that was wrong. When they disagree, the
online reading is right {a['disagree_online_right']} times of {a['disagree']}. These numbers are from im2latex's
physics-paper formulas, not our worksheets.</p>
<p class='note prose'>Offline scores from the run of 2026-11-10 (shipped ONNX, app preprocessing); online run 2026-11-11 with
<code>tools/training_vl/evaluate_vl.py --engine local --mode prompt</code>; comparison from
<code>tools/training_vl/compare_online_offline.py</code>. Errors in the online run: {t['online_errors']}.</p>"""


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--offline", required=True, help="evaluate_formula.py output folder (predictions.tsv, results.md)")
    parser.add_argument("--online", required=True, help="evaluate_vl.py output folder (predictions.tsv, run.json)")
    parser.add_argument("--out", help="default: <online>/comparison_offline")
    parser.add_argument("--page", help="HTML page to put the section into (before <footer>)")
    args = parser.parse_args()
    offline_dir, online_dir = Path(args.offline), Path(args.online)
    offline = {r["image"]: r for r in read_tsv(offline_dir / "predictions.tsv")}
    online = {r["filename"]: r for r in read_tsv(online_dir / "predictions.tsv")}
    summary = compare(offline, online)
    summary["timing"] = timing(offline_dir, online, json.loads((online_dir / "run.json").read_text(encoding="utf-8")))
    summary["sources"] = {"offline": offline_dir.name, "online": online_dir.name}
    out = Path(args.out) if args.out else online_dir / "comparison_offline"
    out.mkdir(parents=True, exist_ok=True)
    (out / "comparison.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    (out / "comparison.md").write_text(markdown(summary), encoding="utf-8")
    section = section_html(summary)
    (out / "section.html").write_text(section, encoding="utf-8")
    print(markdown(summary))
    if args.page:
        page = Path(args.page)
        page.write_text(put_section(page.read_text(encoding="utf-8"), section), encoding="utf-8", newline="\n")
        print(f"section written into {page}")
    print(f"-> {out}")


if __name__ == "__main__":
    main()
