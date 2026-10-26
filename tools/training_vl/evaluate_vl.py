"""Compare OCR engines on the held-out eval set written by convert_to_sft.py.

Example (from tools/training_vl):
  python evaluate_vl.py --eval D:\\vl_data\\sft --engine local
  python evaluate_vl.py --eval D:\\vl_data\\sft --engine finetuned --model-dir D:\\vl_ft\\export \\
      --vl-model-name PaddleOCR-VL-0.9B --pipeline-version v1
  python evaluate_vl.py --eval D:\\vl_data\\sft --engine hosted --confirm-own-material --max-pages 50

Engines
  local      PaddleOCR-VL-1.6 on this PC (paddleocr_vl_env, used as is).
             Stop the AI service first so the GPU is free.
  finetuned  the same, with the VL model from --model-dir (a model we
             fine-tuned and host ourselves)
  hosted     Baidu's official API, through the AI service's client. The
             client reads PADDLEOCR_ACCESS_TOKEN from the environment;
             this script never reads, prints or stores it. Respects the
             daily page cap and stops there. Images sent are stored by
             Baidu: only your own material, no third-party pages or
             personal data.
  mock       predictions from a JSON file {filename: text} (tests)

--mode prompt (default for local/finetuned) reads the whole image with
the task's prompt; --mode layout runs layout detection as the app does.
The hosted API always runs layout detection (it takes no task prompt).

Metrics per group (all, task, topic, kind, source): count, exact match
after normalisation (LaTeX delimiters and spaces dropped; tables
compared as OTSL), mean normalised edit distance, and how often the
app's formula guard would hold the block (formula and table tasks), for
the prediction and, for reference, the target.

Output: <out-root>/<time>_<engine>_<eval hash>/ with predictions.tsv,
results.csv, results.md and run.json (outside git).
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict
from datetime import datetime
from pathlib import Path

from vl_common import DEFAULT_CONFIG, HERE, REPO, load_config, normalize_for_compare, normalized_edit_distance

DATA_ROOT = Path(r"C:\Projects\Capstone\tactilelens-training")
DEFAULT_OUT_ROOT = DATA_ROOT / "outputs" / "vl_eval"
VL_PYTHON = Path(r"C:\Projects\Capstone\paddleocr_vl_env\Scripts\python.exe")
HOSTED_WARNING = (
    "Images sent to the hosted API are stored by Baidu. Send only your own material: "
    "no third-party or textbook pages, no personal data."
)
FORMULA_LABELS = ("formula", "equation")
TABLE_LABELS = ("table",)
SKIP_LABELS = ("image", "figure", "chart", "seal")
_IMAGE_MARKUP = re.compile(r"<img\b[^>]*>|!\[[^\]]*\]\([^)]*\)", re.IGNORECASE)
_OTSL_SPLIT = re.compile(r"(<fcel>|<ecel>|<lcel>|<ucel>|<xcel>|<nl>)")

sys.path.insert(0, str(REPO / "ai_service"))
try:
    from services.braille.braille_math_normalizer import BrailleMathNormalizer
    from services.braille.formula_braille_guard import review_formula, review_table
    from services.ocr.table_content_parser import TableContentParser
    GUARD_ERROR = None
except Exception as error:  # noqa: BLE001
    GUARD_ERROR = f"{type(error).__name__}: {error}"


# ---------- eval set ----------

def load_eval(sft: Path) -> list[dict]:
    records = [json.loads(l) for l in (sft / "eval.jsonl").read_text(encoding="utf-8").splitlines() if l.strip()]
    metas = [json.loads(l) for l in (sft / "eval_meta.jsonl").read_text(encoding="utf-8").splitlines() if l.strip()]
    if len(records) != len(metas):
        raise SystemExit("eval.jsonl and eval_meta.jsonl have different lengths; run convert_to_sft.py again.")
    items = []
    for rec, meta in zip(records, metas):
        url = Path(rec["image_info"][0]["image_url"])
        items.append({**meta, "image": str(url if url.is_absolute() else (sft / url).resolve()),
                      "target": rec["text_info"][1]["text"]})
    return items


# ---------- engines ----------

def run_mock(items: list[dict], args) -> tuple[dict, dict]:
    answers = json.loads(Path(args.mock_file).read_text(encoding="utf-8")) if args.mock_file else {}
    return {i["filename"]: {"blocks": [{"label": "text", "content": answers.get(i["filename"], "")}]} for i in items}, {}


def run_local(items: list[dict], args, config: dict) -> tuple[dict, dict]:
    if not Path(args.vl_python).exists():
        raise SystemExit(f"{args.vl_python} not found (set --vl-python).")
    if args.engine == "finetuned" and not args.model_dir:
        raise SystemExit("--engine finetuned needs --model-dir.")
    jobs = [{"id": i["filename"], "image": i["image"], "prompt_label": config["tasks"][i["task"]]["local_prompt_label"]}
            for i in items]
    with tempfile.TemporaryDirectory() as tmp:
        jobs_file, out_file = Path(tmp) / "jobs.json", Path(tmp) / "out.json"
        jobs_file.write_text(json.dumps(jobs, ensure_ascii=False), encoding="utf-8")
        command = [args.vl_python, str(HERE / "local_vl_worker.py"), "--jobs", str(jobs_file), "--out", str(out_file),
                   "--mode", args.mode]
        if args.engine == "finetuned":
            command += ["--model-dir", args.model_dir]
        if args.vl_model_name:
            command += ["--model-name", args.vl_model_name]
        if args.pipeline_version:
            command += ["--pipeline-version", args.pipeline_version]
        print("Running the local engine (first run loads the model; this takes a while)...", flush=True)
        if subprocess.run(command).returncode != 0 or not out_file.exists():
            raise SystemExit("The local engine failed (is the GPU free? stop the AI service first).")
        output = json.loads(out_file.read_text(encoding="utf-8"))
    return {p["id"]: p for p in output["predictions"]}, {"load_seconds": output["load_seconds"], "options": output["options"]}


def run_hosted(items: list[dict], args) -> tuple[dict, dict]:
    if not args.confirm_own_material:
        raise SystemExit(HOSTED_WARNING + "\nAdd --confirm-own-material to confirm, then run again.")
    print("WARNING: " + HOSTED_WARNING, flush=True)
    if not os.environ.get("PADDLEOCR_PAGE_COUNT_FILE", "").strip():
        # Keep a count across runs even without the AI service's file.
        os.environ["PADDLEOCR_PAGE_COUNT_FILE"] = str(DEFAULT_OUT_ROOT / "hosted_page_count.json")
        DEFAULT_OUT_ROOT.mkdir(parents=True, exist_ok=True)
    from services.ocr.official_api_client import HostedOcrError, HostedOcrQuotaExceeded, OfficialApiClient

    try:
        client = OfficialApiClient.from_environment()  # the token stays inside the client
    except ValueError as error:
        raise SystemExit(f"Hosted client not configured: {error}")
    print(f"Pages today before this run: {client.page_counter.pages_today} of cap {client.page_counter.daily_cap}")

    predictions, stopped, failures_in_a_row = {}, None, 0
    for n, item in enumerate(items[: args.max_pages], 1):
        try:
            pages = client.parse_document(Path(item["image"]).read_bytes(), item["filename"])
            # Keep only label and content; Baidu's links are never kept.
            blocks = [{"label": b.get("block_label", ""), "content": b.get("block_content", "")}
                      for page in pages for b in page.get("prunedResult", page).get("parsing_res_list", [])]
            predictions[item["filename"]] = {"blocks": blocks}
            failures_in_a_row = 0
        except HostedOcrQuotaExceeded as error:
            stopped = f"page cap: {error}"
            break
        except HostedOcrError as error:  # not resubmitted
            predictions[item["filename"]] = {"blocks": [], "error": type(error).__name__}
            failures_in_a_row += 1
            if failures_in_a_row >= 3:
                stopped = f"3 failures in a row ({type(error).__name__})"
                break
        print(f"{n}/{min(len(items), args.max_pages)} {item['filename']}", flush=True)
    if len(items) > args.max_pages and not stopped:
        stopped = f"--max-pages {args.max_pages}"
    if stopped:
        print(f"Stopped: {stopped}. Only the images sent are scored.")
    return predictions, {"stopped": stopped, "pages_today_after": client.page_counter.pages_today,
                         "daily_cap": client.page_counter.daily_cap}


# ---------- scoring ----------

def prediction_text(task: str, blocks: list[dict]) -> str:
    """The part of the engine's output that answers the task."""

    blocks = [b for b in blocks if not any(s in b["label"].lower() for s in SKIP_LABELS)]
    if task == "formula":
        chosen = [b for b in blocks if any(s in b["label"].lower() for s in FORMULA_LABELS)]
    elif task == "table":
        chosen = [b for b in blocks if any(s in b["label"].lower() for s in TABLE_LABELS) or "<table" in b["content"].lower()][:1]
    else:
        chosen = [b for b in blocks if not any(s in b["label"].lower() for s in TABLE_LABELS)]
    text = "\n".join(b["content"] for b in (chosen or blocks))
    return _IMAGE_MARKUP.sub("", text).strip()


def otsl_to_html(otsl: str) -> str:
    rows = ["".join(f"<td>{c}</td>" for c in row if c is not None) for row in _otsl_cells(otsl)]
    return "<table>" + "".join(f"<tr>{r}</tr>" for r in rows) + "</table>"


def _otsl_cells(otsl: str) -> list[list[str | None]]:
    """Rows of cell texts; "" for an empty cell, None for a merged one."""

    rows, current = [], []
    parts = _OTSL_SPLIT.split(otsl)
    for token, text in zip(parts[1::2], parts[2::2]):
        if token == "<nl>":
            rows.append(current)
            current = []
        elif token == "<fcel>":
            current.append(text.strip())
        elif token == "<ecel>":
            current.append("")
        else:
            current.append(None)
    if current:
        rows.append(current)
    return rows


def guard_holds(task: str, text: str) -> bool | None:
    if GUARD_ERROR or task not in ("formula", "table") or not text.strip():
        return None
    if task == "formula":
        return review_formula(text, BrailleMathNormalizer.normalize(text)).needs_review
    html = text if "<table" in text.lower() else otsl_to_html(text)
    rows = TableContentParser.parse(html)
    return review_table(TableContentParser.to_accessible_text(rows)).needs_review if rows else None


def score(items: list[dict], predictions: dict) -> list[dict]:
    rows = []
    for item in items:
        if item["filename"] not in predictions:
            continue  # not sent (cap or --max-pages)
        p = predictions[item["filename"]]
        pred = prediction_text(item["task"], p.get("blocks", []))
        a, b = normalize_for_compare(item["task"], pred), normalize_for_compare(item["task"], item["target"])
        rows.append({**{k: item[k] for k in ("filename", "task", "topic", "kind", "source")},
                     "exact": a == b, "ned": round(normalized_edit_distance(a, b), 4),
                     "guard_pred": guard_holds(item["task"], pred), "guard_target": guard_holds(item["task"], item["target"]),
                     "error": p.get("error", ""), "seconds": p.get("seconds", ""), "target": item["target"], "prediction": pred})
    return rows


def summarise(rows: list[dict]) -> list[dict]:
    groups = defaultdict(list)
    for row in rows:
        groups[("all", "all")].append(row)
        for key in ("task", "topic", "kind", "source"):
            groups[(key, row[key])].append(row)
    out = []
    for (key, value), members in sorted(groups.items(), key=lambda kv: (kv[0][0] != "all", kv[0])):
        guarded = [r for r in members if r["guard_pred"] is not None]
        guarded_t = [r for r in members if r["guard_target"] is not None]
        out.append({
            "group": key, "value": value, "count": len(members),
            "exact_pct": round(100 * sum(r["exact"] for r in members) / len(members), 1),
            "mean_ned": round(sum(r["ned"] for r in members) / len(members), 4),
            "guard_held_pred_pct": round(100 * sum(r["guard_pred"] for r in guarded) / len(guarded), 1) if guarded else "",
            "guard_held_target_pct": round(100 * sum(r["guard_target"] for r in guarded_t) / len(guarded_t), 1) if guarded_t else "",
            "errors": sum(bool(r["error"]) for r in members),
        })
    return out


# ---------- main ----------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--eval", required=True, help="convert_to_sft.py output folder (eval.jsonl, eval_meta.jsonl)")
    parser.add_argument("--engine", required=True, choices=["local", "finetuned", "hosted", "mock"])
    parser.add_argument("--mode", choices=["prompt", "layout"], default="prompt", help="local/finetuned only")
    parser.add_argument("--model-dir", help="fine-tuned VL model folder (finetuned)")
    parser.add_argument("--vl-model-name", help="local/finetuned: PaddleOCR-VL-1.6-0.9B (v1.6) or PaddleOCR-VL-0.9B (v1)")
    parser.add_argument("--pipeline-version", help="local/finetuned: v1, v1.5 or v1.6 (worker default v1.6)")
    parser.add_argument("--vl-python", default=str(VL_PYTHON))
    parser.add_argument("--max-pages", type=int, default=100, help="hosted: at most this many images this run")
    parser.add_argument("--confirm-own-material", action="store_true",
                        help="hosted: confirm every image is your own material (Baidu stores them)")
    parser.add_argument("--mock-file", help="mock: JSON {filename: prediction}")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG))
    parser.add_argument("--out-root", default=str(DEFAULT_OUT_ROOT))
    args = parser.parse_args()

    config = load_config(Path(args.config))
    sft = Path(args.eval)
    items = load_eval(sft)
    if not items:
        raise SystemExit("The eval set is empty.")
    eval_hash = hashlib.sha256((sft / "eval.jsonl").read_bytes()).hexdigest()[:8]
    if GUARD_ERROR:
        print(f"warning: formula guard not available ({GUARD_ERROR}); guard columns left empty")

    if args.engine == "mock":
        predictions, info = run_mock(items, args)
    elif args.engine == "hosted":
        predictions, info = run_hosted(items, args)
    else:
        predictions, info = run_local(items, args, config)

    rows = score(items, predictions)
    if not rows:
        raise SystemExit("Nothing was scored.")
    summary = summarise(rows)

    out = Path(args.out_root) / f"{datetime.now():%Y%m%d_%H%M%S}_{args.engine}_{eval_hash}"
    out.mkdir(parents=True, exist_ok=True)
    fields = list(rows[0])
    with open(out / "predictions.tsv", "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t")
        writer.writeheader()
        writer.writerows({k: str(v).replace("\t", " ").replace("\n", "\\n") for k, v in r.items()} for r in rows)
    with open(out / "results.csv", "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(summary[0]))
        writer.writeheader()
        writer.writerows(summary)
    run = {"engine": args.engine, "mode": args.mode if args.engine in ("local", "finetuned") else
           ("layout" if args.engine == "hosted" else None), "model_dir": args.model_dir,
           "vl_model_name": args.vl_model_name, "pipeline_version": args.pipeline_version, "eval": str(sft),
           "eval_sha8": eval_hash, "items": len(items), "scored": len(rows), "guard": GUARD_ERROR or "ok", **info}
    (out / "run.json").write_text(json.dumps(run, ensure_ascii=False, indent=1), encoding="utf-8")

    lines = [f"# VL eval: {args.engine}", "", f"Eval set: {sft} (eval.jsonl sha256 {eval_hash}…), "
             f"{len(rows)} of {len(items)} items scored.", ""]
    if info.get("stopped"):
        lines += [f"Stopped early: {info['stopped']}.", ""]
    lines += ["Exact = equal after normalisation. NED = normalised edit distance (0 is identical). "
              "Guard held = the app's formula guard would hold the block (no Braille), for the prediction / the target.", "",
              "| group | value | n | exact % | mean NED | guard held pred % | guard held target % | errors |",
              "|---|---|---|---|---|---|---|---|"]
    lines += [f"| {s['group']} | {s['value']} | {s['count']} | {s['exact_pct']} | {s['mean_ned']} | "
              f"{s['guard_held_pred_pct']} | {s['guard_held_target_pct']} | {s['errors']} |" for s in summary]
    (out / "results.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    overall = summary[0]
    print(f"Scored {len(rows)} of {len(items)}: exact {overall['exact_pct']}%, mean NED {overall['mean_ned']}, "
          f"guard held {overall['guard_held_pred_pct']}%")
    print(f"Results in {out}")


if __name__ == "__main__":
    main()
