"""What changed during fine-tuning: one Track A run vs the official checkpoint.

Read-only: nothing is trained, no checkpoint is written, and the test split
is not scored again (the gallery and the error types use the predictions the
run already saved). Three steps, from tools/model_prep:

  1. weights     (paddle_formula_env)   per-layer weight change, grouped by module
  2. confidence  (paddle_formula_env)   both checkpoints on the VALIDATION list;
                                        the probability of every token each picks
  3. report      (paddle_onnx_env)      gallery, error types, charts, report.md,
                                        an HTML section, and optionally that
                                        section put into a page (--page)

  C:\\Projects\\Capstone\\paddle_formula_env\\Scripts\\python finetune_changes.py weights --run <run folder>
  C:\\Projects\\Capstone\\paddle_formula_env\\Scripts\\python finetune_changes.py confidence --run <run folder>
  C:\\Projects\\Capstone\\paddle_onnx_env\\Scripts\\python finetune_changes.py report --run <run folder> [--page <html>]

Output: <run>/analysis/finetune_changes_<date>/ (or --out).

Weight change of a module = ||after - before|| / ||before|| over all its
weights (Frobenius norm), so 1% means the weights moved by 1% of their size.
Batch-norm running averages (_mean, _variance) are statistics of the images
seen, not learned weights; they are reported apart.

Confidence of a reading = the model's softmax probability for each token it
picked (greedy decoding, the app's setting); reported as the weakest token
and the geometric mean over the tokens before the end token.
"""

from __future__ import annotations

import argparse
import base64
import csv
import datetime as dt
import difflib
import html
import io
import json
import math
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "training"))
sys.path.insert(0, str(HERE.parent / "training_vl"))
from common import Layout, read_labels, root_dir  # noqa: E402

PADDLEOCR = Path(r"C:\Projects\Capstone\PaddleOCR-official")
EOS = 2
SECTION_START, SECTION_END = "<!-- finetune-changes:start -->", "<!-- finetune-changes:end -->"
STRUCTURE = {"{", "}", "^", "_", "\\frac", "\\sqrt", "(", ")", "[", "]", "\\{", "\\}"}
CONFIDENCE_BINS = [(0.0, 0.5), (0.5, 0.8), (0.8, 0.9), (0.9, 0.95), (0.95, 0.99), (0.99, 1.0)]

# ---------------------------------------------------------------- modules

def module_of(name: str) -> str:
    """Plain-language module for a parameter name of PP-FormulaNet_plus-S."""
    m = re.match(r"backbone\.pphgnet_b4\.(stem|stages\.(\d+)|last_conv|fc)", name)
    if m:
        if m.group(1) == "stem":
            return "Image encoder: first layers"
        if m.group(2) is not None:
            return f"Image encoder: stage {int(m.group(2)) + 1}"
        return "Image encoder: output layers"
    if name.startswith("head.enc_to_dec_proj"):
        return "Bridge: image features to the decoder"
    m = re.match(r"head\.decoder\.model\.decoder\.layers\.(\d+)\.(\w+)", name)
    if m:
        part = m.group(2)
        what = ("attention to earlier tokens" if part.startswith("self_attn") else
                "attention to the image" if part.startswith("encoder_attn") else "feed-forward")
        return f"Text decoder layer {int(m.group(1)) + 1}: {what}"
    if re.match(r"head\.decoder\.model\.decoder\.(embed_tokens|embed_positions|layernorm_embedding)", name):
        return "Text decoder: token and position inputs"
    if name.startswith("head.decoder.model.decoder.layer_norm"):
        return "Text decoder: final norm"
    if name.startswith("head.decoder.lm_head"):
        return "Output layer: picks the next token"
    return "Other"


def short_label(module: str) -> str:
    """A chart label of at most about 22 characters."""
    m = re.match(r"Text decoder layer (\d+): (.*)", module)
    if m:
        return f"Decoder {m.group(1)}: " + {"attention to earlier tokens": "own tokens",
                                             "attention to the image": "image",
                                             "feed-forward": "feed-forward"}[m.group(2)]
    return {"Image encoder: first layers": "Encoder: first layers", "Image encoder: output layers": "Encoder: output (unused)",
            "Bridge: image features to the decoder": "Bridge to decoder",
            "Text decoder: token and position inputs": "Decoder: inputs", "Text decoder: final norm": "Decoder: final norm",
            "Output layer: picks the next token": "Output layer"}.get(module, module.replace("Image encoder", "Encoder"))


def is_statistic(name: str) -> bool:
    return name.endswith(("._mean", "._variance"))


def module_order(name: str) -> tuple:
    order = ["Image encoder: first layers", "Image encoder: stage", "Image encoder: output layers", "Bridge",
             "Text decoder: token", "Text decoder layer", "Text decoder: final", "Output layer", "Other"]
    return next(i for i, p in enumerate(order) if name.startswith(p) or p == "Other"), name


def relative_change(sum_sq_diff: float, sum_sq_before: float) -> float:
    return math.sqrt(sum_sq_diff) / math.sqrt(sum_sq_before) if sum_sq_before else float("nan")

# ---------------------------------------------------------------- confidence

def trim_at_eos(tokens: list[int], probs: list[float]) -> tuple[list[int], list[float]]:
    """The tokens (and their probabilities) before the first end token."""
    if EOS in tokens:
        end = tokens.index(EOS)
        return tokens[:end], probs[:end]
    return tokens, probs


def sequence_confidence(probs: list[float]) -> dict:
    if not probs:
        return {"weakest": 0.0, "geomean": 0.0, "tokens": 0}
    return {"weakest": min(probs), "geomean": math.exp(sum(math.log(max(p, 1e-12)) for p in probs) / len(probs)),
            "tokens": len(probs)}


def confidence_bin(value: float) -> str:
    for lo, hi in CONFIDENCE_BINS:
        if lo <= value < hi or (hi == 1.0 and value == 1.0):
            return f"{lo:.2f}-{hi:.2f}"
    raise ValueError(value)

# ---------------------------------------------------------------- error types

HABIT_COMMANDS = ["\\,", "\\;", "\\quad", "\\qquad", "\\left", "\\right", "\\mathrm"]


def habits(before: dict, after: dict, commands: list[str] = HABIT_COMMANDS) -> list[dict]:
    """How many formulas contain each command: in the target, in each model's reading."""
    def count(rows, key, command):
        pattern = re.compile(re.escape(command) + ("(?![A-Za-z])" if command[-1].isalpha() else ""))
        return sum(bool(pattern.search(r[key])) for r in rows.values())
    return [{"command": c, "target": count(before, "target", c), "original": count(before, "prediction", c),
             "fine-tuned": count(after, "prediction", c)} for c in commands]


KIND_LABELS = {"spacing only": "Spacing only", "same meaning, different notation": "Same meaning, different notation"}
EDIT_KINDS = ["Symbols left out", "Extra symbols", "Wrong symbols", "Several kinds of mistake"]


def tokens_of(latex: str) -> list[str]:
    from compare_formula import drop_spacing
    from evaluate_formula import TOKEN
    return [t for t in TOKEN.findall(drop_spacing(latex)) if t not in ("\\left", "\\right")]


def error_type(target: str, prediction: str) -> dict:
    """None for a right reading (strict), else its kind; a meaning-changing
    reading is sorted by how its symbols differ."""
    import vl_common
    from compare_formula import MEANING, classify
    if vl_common.normalize_for_compare("formula", target) == vl_common.normalize_for_compare("formula", prediction):
        return {"kind": None, "structure": False}
    kind = classify(target, prediction)
    if kind != MEANING:
        return {"kind": KIND_LABELS.get(kind, kind), "structure": False}
    a, b = tokens_of(target), tokens_of(prediction)
    ops, differing = set(), []
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if tag != "equal":
            ops.add(tag)
            differing += a[i1:i2] + b[j1:j2]
    kind = ("Symbols left out" if ops == {"delete"} else "Extra symbols" if ops == {"insert"} else
            "Wrong symbols" if ops == {"replace"} else "Several kinds of mistake")
    return {"kind": kind, "structure": any(t in STRUCTURE for t in differing)}

# ---------------------------------------------------------------- page

def put_section(page: str, section: str) -> str:
    """Replace the marked section, or insert it before <footer>."""
    block = f"{SECTION_START}\n{section}\n{SECTION_END}"
    if SECTION_START in page:
        start, end = page.index(SECTION_START), page.index(SECTION_END) + len(SECTION_END)
        return page[:start] + block + page[end:]
    at = page.find("<footer")
    if at < 0:
        raise SystemExit("the page has no <footer>; nowhere to put the section")
    return page[:at] + block + "\n\n" + page[at:]

# ---------------------------------------------------------------- paths

def run_paths(run: Path) -> dict:
    meta = json.loads((run / "run.json").read_text(encoding="utf-8"))
    comparison = json.loads((run / "evaluation" / "comparison.json").read_text(encoding="utf-8"))
    return {"before": Path(meta["pretrained"] + ".pdparams"), "after": run / "best_checkpoint" / "best_accuracy.pdparams",
            "config": run / "config" / "model_config.yml", "before_eval": Path(comparison["before"]),
            "after_eval": Path(comparison["after"]), "meta": meta}


def out_dir(args) -> Path:
    out = Path(args.out) if args.out else Path(args.run) / "analysis" / f"finetune_changes_{dt.date.today():%Y%m%d}"
    out.mkdir(parents=True, exist_ok=True)
    return out

# ---------------------------------------------------------------- 1. weights

def cmd_weights(args) -> None:
    import numpy as np
    import paddle

    paths, out = run_paths(Path(args.run)), out_dir(args)
    before, after = paddle.load(str(args.before or paths["before"])), paddle.load(str(paths["after"]))
    if before.keys() != after.keys():
        raise SystemExit(f"the checkpoints have different parameters: {len(before.keys() ^ after.keys())}")
    rows, modules, stats = [], defaultdict(lambda: [0, 0.0, 0.0]), defaultdict(lambda: [0, 0.0, 0.0])
    for name in before:
        w0, w1 = np.asarray(before[name], dtype=np.float64), np.asarray(after[name], dtype=np.float64)
        if w0.shape != w1.shape:
            raise SystemExit(f"{name}: shape {w0.shape} vs {w1.shape}")
        d2, b2 = float(((w1 - w0) ** 2).sum()), float((w0 ** 2).sum())
        group = stats if is_statistic(name) else modules
        acc = group[module_of(name)]
        acc[0] += w0.size; acc[1] += d2; acc[2] += b2
        rows.append({"parameter": name, "module": module_of(name), "statistic": is_statistic(name),
                     "shape": "x".join(map(str, w0.shape)), "values": w0.size,
                     "relative_change": relative_change(d2, b2), "max_abs_change": float(np.abs(w1 - w0).max())})
    with open(out / "weights_per_parameter.csv", "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    def table(group):
        return [{"module": m, "values": n, "relative_change": relative_change(d2, b2)}
                for m, (n, d2, b2) in sorted(group.items(), key=lambda kv: module_order(kv[0]))]

    learned = [r for r in rows if not r["statistic"]]
    total = [sum(r["values"] for r in learned), sum(modules[m][1] for m in modules), sum(modules[m][2] for m in modules)]
    result = {"before": str(args.before or paths["before"]), "after": str(paths["after"]),
              "parameters": len(rows), "values": sum(r["values"] for r in rows),
              "learned_values": total[0], "overall_relative_change": relative_change(total[1], total[2]),
              "modules": table(modules), "statistics": table(stats),
              "top_parameters": sorted(learned, key=lambda r: -r["relative_change"])[:10],
              "tokens": token_changes(before, after, paths)}
    (out / "weights.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    for m in result["modules"]:
        print(f"{100 * m['relative_change']:8.3f}%  {m['values']:>12,}  {m['module']}")
    print(f"overall {100 * result['overall_relative_change']:.3f}% over {total[0]:,} learned values -> {out}")


def token_changes(before, after, paths) -> dict:
    """Which output tokens moved most, and whether tokens that occur in the
    training labels moved more than tokens that never occur."""
    import numpy as np
    from tokenizers import Tokenizer

    tokenizer = Tokenizer.from_file(str(PADDLEOCR / "ppocr" / "utils" / "dict" / "unimernet_tokenizer" / "tokenizer.json"))
    w0 = np.asarray(before["head.decoder.lm_head.weight"], dtype=np.float64)  # [hidden, vocab]
    w1 = np.asarray(after["head.decoder.lm_head.weight"], dtype=np.float64)
    change = np.linalg.norm(w1 - w0, axis=0) / np.maximum(np.linalg.norm(w0, axis=0), 1e-12)
    seen = Counter()
    data = Layout(root_dir(None)).im2latex_filtered
    lists = [data / "train.txt", paths["config"].parent / "extra_train.txt"]
    for path in lists:
        if path.exists():
            for line in path.read_text(encoding="utf-8").splitlines():
                if "\t" in line:
                    seen.update(tokenizer.encode(line.split("\t", 1)[1]).ids)
    used = np.zeros(change.size, dtype=bool)
    used[[i for i in seen if i < change.size]] = True
    tied = bool(np.allclose(w0, np.asarray(before["head.decoder.model.decoder.embed_tokens.weight"]).T))
    top = np.argsort(-change)[:15]
    return {"vocabulary": int(change.size), "in_training_labels": int(used.sum()), "label_files": [str(p) for p in lists],
            "median_change_seen": float(np.median(change[used])), "median_change_unseen": float(np.median(change[~used])),
            "output_layer_tied_to_input_embedding": tied,
            "top": [{"token": tokenizer.decode([int(i)]).strip() or tokenizer.id_to_token(int(i)), "id": int(i),
                     "relative_change": float(change[i]),
                     "times_in_training_labels": int(seen[int(i)])} for i in top]}

# ---------------------------------------------------------------- 2. confidence

def cmd_confidence(args) -> None:
    paths, out = run_paths(Path(args.run)), out_dir(args)
    labels = Path(args.labels) if args.labels else Layout(root_dir(None)).im2latex_filtered / "val.txt"
    if "test" in labels.name:
        raise SystemExit("confidence is measured on the validation list; the test split was scored once already")
    rows = read_labels(labels)
    os.chdir(PADDLEOCR)
    sys.path.insert(0, str(PADDLEOCR))
    import numpy as np
    import paddle
    import ppocr.data.imaug.unimernet_aug as aug
    aug.Snow.apply = lambda self, img, **params: img  # not used at evaluation; ImageMagick not installed
    from ppocr.data import create_operators, transform
    from ppocr.modeling.architectures import build_model
    from ppocr.postprocess import build_post_process
    from tools.program import load_config

    if not args.cpu and paddle.device.cuda.device_count() == 0:
        raise SystemExit("no GPU visible to Paddle (use --cpu to run on the CPU)")
    paddle.set_device("cpu" if args.cpu else "gpu")
    config = load_config(str(paths["config"]))
    ops = [op for op in config["Eval"]["dataset"]["transforms"]
           if not any(k in op for k in ("UniMERNetLabelEncode", "KeepKeys"))] + [{"KeepKeys": {"keep_keys": ["image"]}}]
    ops = create_operators(ops, config["Global"])
    post = build_post_process(config["PostProcess"], config["Global"])
    result = {"labels": str(labels), "items": len(rows), "device": "cpu" if args.cpu else "gpu", "models": {}}
    for tag, weights in (("original", args.before or paths["before"]), ("fine-tuned", paths["after"])):
        model = build_model(config["Architecture"])
        model.set_state_dict(paddle.load(str(weights)))
        model.eval()
        head, steps = model.head, []
        processor = head.logits_processor

        def record(input_ids, scores, _processor=processor):
            scores = _processor(input_ids, scores)
            steps.append(paddle.nn.functional.softmax(scores.astype("float32"), axis=-1).max(axis=-1).numpy())
            return scores

        head.logits_processor = record
        readings = []
        for image, target in rows:
            path = str(labels.parent / image)
            with open(path, "rb") as handle:  # the keys SimpleDataSet sets
                batch = transform({"img_path": path, "filename": path, "label": target, "image": handle.read()}, ops)
            steps.clear()
            with paddle.no_grad():
                ids = model(paddle.to_tensor(np.expand_dims(batch[0], 0)))
            ids = np.array(ids)
            probs = np.concatenate([s.reshape(1, -1) for s in steps], axis=1)[0].tolist()
            tokens = ids[0, -len(probs):].tolist()
            tokens, probs = trim_at_eos(tokens, probs)
            readings.append({"image": image, "target": target, "prediction": post(ids)[0],
                             "token_probs": [round(p, 5) for p in probs], **sequence_confidence(probs)})
        result["models"][tag] = {"weights": str(weights), "readings": readings}
        print(f"{tag}: {len(readings)} readings")
        del model
    (out / "confidence.json").write_text(json.dumps(result, indent=1), encoding="utf-8")
    print(f"-> {out / 'confidence.json'}")

# ---------------------------------------------------------------- 3. report

def thumbnail(path: Path, height: int = 120) -> bytes:
    from PIL import Image, ImageOps
    image = ImageOps.exif_transpose(Image.open(path)).convert("L")
    box = ImageOps.invert(image).point(lambda v: 255 if v > 40 else 0).getbbox()
    if box:
        pad = 10
        image = image.crop((max(box[0] - pad, 0), max(box[1] - pad, 0),
                            min(box[2] + pad, image.width), min(box[3] + pad, image.height)))
    if image.height > height:
        image = image.resize((max(1, round(image.width * height / image.height)), height), Image.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, "PNG", optimize=True)
    return buffer.getvalue()


def data_uri(png: bytes) -> str:
    return "data:image/png;base64," + base64.b64encode(png).decode("ascii")


def gallery(before: dict, after: dict) -> dict[str, list[dict]]:
    """Every test formula sorted by what fine-tuning did to it (spacing-normalized)."""
    from compare_formula import spacing_scores
    groups = defaultdict(list)
    for image in sorted(before):
        target = before[image]["target"]
        b, a = before[image]["prediction"], after[image]["prediction"]
        right_b, right_a = spacing_scores(target, b)[0], spacing_scores(target, a)[0]
        key = ("fixed" if right_a and not right_b else "broken" if right_b and not right_a else
               "both right" if right_a else "both wrong")
        groups[key].append({"image": image, "target": target, "original": b, "fine-tuned": a,
                            "error_original": None if right_b else error_type(target, b)["kind"],
                            "error_fine-tuned": None if right_a else error_type(target, a)["kind"]})
    return groups


def error_table(rows: dict) -> dict:
    counts, structure = Counter(), 0
    for r in rows.values():
        e = error_type(r["target"], r["prediction"])
        if e["kind"]:
            counts[e["kind"]] += 1
            structure += e["structure"]
    return {"items": len(rows), "wrong_strict": sum(r["exact"] != "True" for r in rows.values()),
            "kinds": dict(counts), "meaning_changing_touching_structure": structure}


def recorded_validation(meta: dict) -> dict:
    """Strict validation counts PaddleOCR logged during training: the original
    checkpoint (step 0) and the best epoch (the checkpoint analysed here)."""
    train = meta["train"]
    n = train["val_items"]
    return {"original": round(train["baseline_validation"]["exp_rate"] * n),
            "fine-tuned": round(max(v["exp_rate"] for v in train["validations"]) * n)}


def confidence_summary(confidence: dict) -> dict:
    import vl_common
    from compare_formula import spacing_scores
    summary = {}
    for tag, data in confidence["models"].items():
        bins = {f"{lo:.2f}-{hi:.2f}": [0, 0] for lo, hi in CONFIDENCE_BINS}
        right, wrong = [], []
        for r in data["readings"]:
            ok = spacing_scores(r["target"], r["prediction"])[0]
            (right if ok else wrong).append(r)
            bins[confidence_bin(r["weakest"])][0 if ok else 1] += 1

        def mean(items, key):
            return sum(i[key] for i in items) / len(items) if items else None

        strict = sum(vl_common.normalize_for_compare("formula", r["target"]) ==
                     vl_common.normalize_for_compare("formula", r["prediction"]) for r in data["readings"])
        summary[tag] = {"items": len(data["readings"]), "strict_right": strict, "right": len(right), "wrong": len(wrong),
                        "weakest_right": mean(right, "weakest"), "weakest_wrong": mean(wrong, "weakest"),
                        "geomean_right": mean(right, "geomean"), "geomean_wrong": mean(wrong, "geomean"),
                        "bins": bins}
    return summary


def unchanged_modules(per_parameter_csv: Path) -> list[str]:
    """Modules none of whose learned weights moved at all."""
    moved = defaultdict(bool)
    with open(per_parameter_csv, encoding="utf-8", newline="") as handle:
        for r in csv.DictReader(handle):
            if r["statistic"] == "False":
                moved[r["module"]] |= float(r["max_abs_change"]) > 0
    return [m for m, any_moved in moved.items() if not any_moved]


def top_tokens_written(top: list[dict], before: dict, after: dict) -> int:
    """Readings (either model, test) that contain any of the most-changed tokens."""
    texts = [t["token"] for t in readable(top)]
    return sum(any(x in r["prediction"] for x in texts) for rows in (before, after) for r in rows.values())


def readable(tokens: list[dict]) -> list[dict]:
    """Drop byte fragments (shown as U+FFFD) and empty pieces."""
    return [t for t in tokens if t["token"].strip() and "�" not in t["token"]]


def cmd_report(args) -> None:
    from charts import bar_chart
    from compare_formula import read

    run, out = Path(args.run), out_dir(args)
    paths = run_paths(run)
    weights = json.loads((out / "weights.json").read_text(encoding="utf-8"))
    conf_path = out / "confidence.json"
    confidence = json.loads(conf_path.read_text(encoding="utf-8")) if conf_path.exists() else None
    before, after = read(paths["before_eval"]), read(paths["after_eval"])
    groups = gallery(before, after)
    errors = {"original": error_table(before), "fine-tuned": error_table(after)}
    conf = confidence_summary(confidence) if confidence else None

    charts = out / "charts"
    charts.mkdir(exist_ok=True)
    modules = weights["modules"]
    bar_chart([short_label(m["module"]) for m in modules],
              {"weight change, % of size": [round(100 * m["relative_change"], 2) for m in modules]},
              "How much each part of the model changed", charts / "weight_change.png",
              note=f"||after - before|| / ||before||; overall {100 * weights['overall_relative_change']:.2f}%")
    kinds = list(KIND_LABELS.values()) + EDIT_KINDS
    bar_chart([k.replace("Same meaning, different notation", "Other notation, same") for k in kinds],
              {t: [errors[t]["kinds"].get(k, 0) for k in kinds] for t in errors},
              "Strictly wrong test readings by kind (of 120)", charts / "error_types.png",
              note="saved predictions; each wrong reading counted once")
    if conf:
        bar_chart(list(conf["original"]["bins"]),
                  {f"{t} {s}": [v[i] for v in conf[t]["bins"].values()]
                   for t in conf for i, s in ((0, "right"), (1, "wrong"))},
                  "Validation readings by the model's confidence in its weakest symbol", charts / "confidence.png",
                  note=f"{conf['original']['items']} validation formulas; the checkpoint was chosen on this list")

    summary = {"run": run.name, "weights": {k: v for k, v in weights.items() if k != "top_parameters"},
               "errors": errors, "habits": habits(before, after),
               "unchanged_modules": unchanged_modules(out / "weights_per_parameter.csv"),
               "top_tokens_written": top_tokens_written(weights["tokens"]["top"], before, after),
               "gallery_counts": {k: len(v) for k, v in groups.items()}, "confidence": conf,
               "recorded_validation": recorded_validation(paths["meta"])}
    (out / "finetune_changes.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    (out / "report.md").write_text(markdown(summary, groups), encoding="utf-8")
    section = html_section(summary, groups, paths, charts)
    (out / "section.html").write_text(section, encoding="utf-8")
    if args.page:
        page = Path(args.page)
        page.write_text(put_section(page.read_text(encoding="utf-8"), section), encoding="utf-8", newline="\n")
        print(f"section written into {page}")
    print(f"-> {out}")


def pct(v: float | None, digits: int = 2) -> str:
    return "not measured" if v is None else f"{100 * v:.{digits}f}%"


def markdown(s: dict, groups: dict) -> str:
    w, e, c = s["weights"], s["errors"], s["confidence"]
    lines = [f"# What changed during fine-tuning ({s['run']})", "",
             "Read-only analysis: no training, test split not rescored (saved predictions).", "",
             f"Overall weight change: {pct(w['overall_relative_change'])} of {w['learned_values']:,} learned values.", "",
             "| module | values | change |", "|---|---:|---:|"]
    lines += [f"| {m['module']} | {m['values']:,} | {pct(m['relative_change'], 3)} |" for m in w["modules"]]
    lines += ["", "Batch-norm running averages (statistics, not learned weights):", ""]
    lines += [f"- {m['module']}: {pct(m['relative_change'], 3)}" for m in w["statistics"]]
    t = w["tokens"]
    lines += ["", f"Output tokens: {t['in_training_labels']:,} of {t['vocabulary']:,} occur in the training labels; "
              f"median change {pct(t['median_change_seen'], 3)} for those vs {pct(t['median_change_unseen'], 3)} "
              "for the rest.", "", "## Error types on the 120 test formulas (saved predictions)", "",
              "| kind | original | fine-tuned |", "|---|---:|---:|"]
    for k in list(KIND_LABELS.values()) + EDIT_KINDS:
        lines.append(f"| {k} | {e['original']['kinds'].get(k, 0)} | {e['fine-tuned']['kinds'].get(k, 0)} |")
    lines += ["", "## Commands in the test formulas (target / original / fine-tuned)", ""]
    lines += [f"- `{h['command']}`: {h['target']} / {h['original']} / {h['fine-tuned']}" for h in s["habits"]]
    lines += ["", f"Unchanged modules (no weight moved): {', '.join(s['unchanged_modules']) or 'none'}.",
              f"Test readings containing a most-changed token: {s['top_tokens_written']}."]
    lines += ["", "## Gallery groups (spacing-normalized)", ""]
    lines += [f"- {k}: {len(v)}" for k, v in sorted(groups.items())]
    lines += ["", "## Confidence (validation list)", ""]
    if c:
        for tag, v in c.items():
            lines.append(f"- {tag}: {v['right']}/{v['items']} right; weakest-symbol confidence "
                         f"{pct(v['weakest_right'], 1)} when right, {pct(v['weakest_wrong'], 1)} when wrong")
    else:
        lines.append("not measured")
    return "\n".join(lines) + "\n"


def esc(text) -> str:
    return html.escape(str(text), quote=True)


def card(item: dict, data_dir: Path, status: str) -> str:
    png = thumbnail(data_dir / item["image"])
    def line(label, latex, kind=None):
        tag = f" <span class='pill bad'>{esc(kind)}</span>" if kind else " <span class='pill ok'>right</span>"
        return f"<div><span class='tag'>{label}</span>{'' if label == 'Target' else tag}<br><code>{esc(latex)}</code></div>"
    return (f"<figure class='ex {status}'><img class='eximg' src='{data_uri(png)}' alt='Test formula image "
            f"{esc(Path(item['image']).stem)}' loading='lazy'><figcaption>"
            + line("Target", item["target"]) + line("Original model", item["original"], item["error_original"])
            + line("Fine-tuned", item["fine-tuned"], item["error_fine-tuned"])
            + "</figcaption></figure>")


def html_section(s: dict, groups: dict, paths: dict, charts: Path) -> str:
    w, e, c = s["weights"], s["errors"], s["confidence"]
    labels_dir = Layout(root_dir(None)).im2latex_filtered
    module_rows = "".join(f"<tr><th scope='row'>{esc(m['module'])}</th><td>{m['values']:,}</td>"
                          f"<td>{pct(m['relative_change'], 3)}</td></tr>" for m in w["modules"])
    biggest = max(w["modules"], key=lambda m: m["relative_change"])
    t = w["tokens"]
    top_tokens = ", ".join(f"<code>{esc(x['token'])}</code>" for x in readable(t["top"])[:10])
    written = s["top_tokens_written"]
    written_sentence = ("Neither model wrote any of them in the 120 test readings, so that change has no effect we "
                        "can see there." if written == 0 else
                        f"{written} of the 240 test readings (both models) contain one of them.")
    moved = [m for m in w["modules"] if m["relative_change"] > 0]
    smallest = min(moved, key=lambda m: m["relative_change"])
    strict_gain = (e["original"]["wrong_strict"] - e["fine-tuned"]["wrong_strict"])
    spacing_fall = (e["original"]["kinds"].get("Spacing only", 0), e["fine-tuned"]["kinds"].get("Spacing only", 0))
    ratio = f"{t['median_change_seen'] / t['median_change_unseen']:.1f} times" if t["median_change_unseen"] else "n/a"
    stats = [m["relative_change"] for m in w["statistics"]]
    stats_range = f"{pct(min(stats), 1)} to {pct(max(stats), 1)} per stage" if stats else "not measured"
    unchanged_sentence = "" if not s["unchanged_modules"] else (
        "<p class='prose'>Exactly 0% means not a single weight changed: "
        + ", ".join(f"<strong>{esc(m.lower())}</strong>" for m in s["unchanged_modules"])
        + " are not on the formula model's path (it reads the image features before them), so training never "
        "reached them.</p>")
    habit_rows = "".join(f"<tr><th scope='row'><code>{esc(h['command'])}</code></th><td>{h['target']}</td>"
                         f"<td>{h['original']}</td><td>{h['fine-tuned']}</td></tr>" for h in s["habits"])
    kinds = list(KIND_LABELS.values()) + EDIT_KINDS
    error_rows = "".join(f"<tr><th scope='row'>{esc(k)}</th><td>{e['original']['kinds'].get(k, 0)}</td>"
                         f"<td>{e['fine-tuned']['kinds'].get(k, 0)}</td></tr>" for k in kinds)
    wrong = {tag: sum(e[tag]["kinds"].values()) for tag in e}

    def img(name, alt, caption):
        path = charts / name
        if not path.exists():
            return ""
        return (f"<figure><img src='{data_uri(path.read_bytes())}' alt='{esc(alt)}' loading='lazy'>"
                f"<figcaption>{caption}</figcaption></figure>")

    def cards(key, status, limit=None):
        items = groups.get(key, [])
        return "".join(card(i, labels_dir, status) for i in items[:limit])

    parts = [
        "<h2 id='finetune-changes'>What changed during fine-tuning (follow-up run)</h2>",
        "<p class='prose'>The follow-up run's best checkpoint (epoch 3) against the official checkpoint the app ships. "
        "Read-only: nothing was retrained, and the test split was not scored again; the examples and error types use "
        "the predictions saved when the run was scored. Confidence was measured on the 104 validation formulas, "
        "which also chose the checkpoint, so the fine-tuned model's numbers there are on the kind side.</p>",
        "<h3>Which parts of the model moved</h3>",
        f"<p class='prose'>Each number is how far a part's weights moved, as a share of their size. Overall the weights "
        f"moved {pct(w['overall_relative_change'])}: a light touch. The most change was in "
        f"<strong>{esc(biggest['module'].lower())}</strong> ({pct(biggest['relative_change'])}); of the parts that "
        f"moved, the least in {esc(smallest['module'].lower())} ({pct(smallest['relative_change'], 3)}). A bigger number shows where training "
        "pushed, not how much that part matters for accuracy.</p>",
        "<div class='charts'>" + img("weight_change.png", "Weight change per module",
                                      "Weight change per part of the model, in % of the weights' size.") + "</div>",
        "<details><summary>Weight change per module, with sizes</summary><div class='tablewrap'><table>"
        "<thead><tr><th>Module</th><th>Values</th><th>Change</th></tr></thead><tbody>" + module_rows
        + "</tbody></table></div></details>",
        unchanged_sentence,
        f"<p class='prose'>The image encoder also keeps running averages of the images it sees (batch-norm "
        f"statistics). These moved more, {stats_range}: the im2latex images look different from what the model saw "
        "before. They are not learned weights and are left out of the numbers above.</p>",
        f"<p class='prose'>Output tokens: {t['in_training_labels']:,} of the {t['vocabulary']:,} tokens the model can "
        f"write occur in the training labels. Their output weights moved a median {pct(t['median_change_seen'], 3)}, "
        f"about {ratio} as much as the tokens that never occur ({pct(t['median_change_unseen'], 3)}). The tokens "
        f"that moved most, in share of their size, are mostly pieces of commands and words that never occur in the "
        f"labels: {top_tokens}. {written_sentence}</p>",
        "<h3>Kinds of mistakes, before and after</h3>",
        f"<p class='prose'>Every reading of the 120 test formulas that is not letter-for-letter right (strict), sorted "
        f"once. <em>Spacing only</em> and <em>same meaning, different notation</em> write the same formula "
        f"differently; the other four change the formula. Strictly wrong readings: {wrong['original']} with the "
        f"original model, {wrong['fine-tuned']} after fine-tuning; spacing only: "
        f"{e['original']['kinds'].get('Spacing only', 0)} &rarr; {e['fine-tuned']['kinds'].get('Spacing only', 0)}.</p>",
        "<div class='charts'>" + img("error_types.png", "Strictly wrong test readings by kind",
                                      "Strictly wrong test readings by kind, original vs fine-tuned (counts of 120; "
                                      "&ldquo;other notation, same&rdquo; is same meaning, different notation).")
        + "</div>",
        "<div class='tablewrap'><table><thead><tr><th>Kind</th><th>Original</th><th>Fine-tuned</th></tr></thead><tbody>"
        + error_rows + "</tbody></table></div>",
        "<h3>Habits it picked up</h3>",
        "<p class='prose'>How many of the 120 test formulas contain each command: in the correct LaTeX, and in each "
        "model's reading. These are typesetting habits of the physics papers im2latex comes from. Copying them is "
        f"most of why the strict score rose: {strict_gain} more test readings became strictly right, and spacing-only "
        f"mistakes fell from {spacing_fall[0]} to {spacing_fall[1]}. The formulas themselves do not change.</p>",
        "<div class='tablewrap'><table><thead><tr><th>Command</th><th>Correct LaTeX</th><th>Original</th>"
        "<th>Fine-tuned</th></tr></thead><tbody>" + habit_rows + "</tbody></table></div>",
    ]
    if c:
        rec = s["recorded_validation"]
        check = " and ".join(f"{c[t]['strict_right']}/{c[t]['items']} ({t})" for t in c)
        same = all(c[t]["strict_right"] == rec[t] for t in c)
        rows = "".join(
            f"<tr><th scope='row'>{esc(tag)}</th><td>{v['right']}/{v['items']}</td><td>{pct(v['weakest_right'], 1)}</td>"
            f"<td>{pct(v['weakest_wrong'], 1)}</td><td>{pct(v['geomean_right'], 1)}</td><td>{pct(v['geomean_wrong'], 1)}</td></tr>"
            for tag, v in c.items())
        parts += [
            "<h3>How sure the model is</h3>",
            "<p class='prose'>For every symbol it writes, the model gives a probability. The weakest symbol's "
            "probability is a simple confidence score for a whole reading. If wrong readings score clearly lower than "
            "right ones, the app could one day ask the student to re-scan when the score is low; that is not built.</p>",
            f"<p class='prose note'>Check: these readings are strictly right for {check}, "
            f"{'the same as' if same else 'which differs from'} the counts logged during training "
            f"({rec['original']} and {rec['fine-tuned']}), so the measurement uses the same model and preprocessing. "
            "The table counts spacing-normalized right.</p>",
            "<div class='tablewrap'><table><thead><tr><th>Model</th><th>Right (validation)</th><th>Weakest symbol, right</th>"
            "<th>Weakest symbol, wrong</th><th>Average symbol, right</th><th>Average symbol, wrong</th></tr></thead>"
            "<tbody>" + rows + "</tbody></table></div>",
            "<p class='prose'>" + " ".join(
                f"{esc(t.capitalize())}: of the readings whose weakest symbol is below 0.50, "
                f"{v['bins']['0.00-0.50'][1]} are wrong and {v['bins']['0.00-0.50'][0]} right; at 0.95 or above, "
                f"{v['bins']['0.95-0.99'][1] + v['bins']['0.99-1.00'][1]} wrong and "
                f"{v['bins']['0.95-0.99'][0] + v['bins']['0.99-1.00'][0]} right."
                for t, v in c.items()) + " A low score points to a wrong reading; a high score does not prove a "
            "right one.</p>",
            "<div class='charts'>" + img("confidence.png", "Validation readings by confidence",
                                          "Validation readings grouped by the weakest symbol's probability; "
                                          "right and wrong counted separately.") + "</div>",
        ]
    else:
        parts += ["<h3>How sure the model is</h3><p class='prose'>Not measured.</p>"]
    n = {k: len(v) for k, v in groups.items()}
    parts += [
        "<h3>Examples</h3>",
        f"<p class='prose'>Test formulas, image first, then the correct LaTeX and both models' readings. Of 120: "
        f"{n.get('fixed', 0)} fixed by fine-tuning, {n.get('broken', 0)} broken by it, {n.get('both wrong', 0)} wrong "
        f"both times, {n.get('both right', 0)} right both times (spacing-normalized). All fixed and broken ones are "
        "shown; three of the formulas wrong both times.</p>",
        "<h3>Fixed by fine-tuning</h3><div class='examples'>" + cards("fixed", "kept") + "</div>",
        "<h3>Broken by fine-tuning</h3><div class='examples'>" + cards("broken", "rejected") + "</div>",
        "<h3>Wrong both times</h3><div class='examples'>" + cards("both wrong", "rejected", 3) + "</div>",
        "<p class='note prose'>From <code>tools/model_prep/finetune_changes.py</code>.</p>",
    ]
    return "\n".join(parts)

# ---------------------------------------------------------------- main

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="step", required=True)
    for name in ("weights", "confidence", "report"):
        p = sub.add_parser(name)
        p.add_argument("--run", required=True, help="the run folder (runs/<date>-<time>_trackA_...)")
        p.add_argument("--out", help="default: <run>/analysis/finetune_changes_<date>")
        if name != "report":
            p.add_argument("--before", help="original .pdparams (default: the run's pretrained checkpoint)")
    sub.choices["confidence"].add_argument("--labels", help="default: the im2latex validation list")
    sub.choices["confidence"].add_argument("--cpu", action="store_true")
    sub.choices["report"].add_argument("--page", help="HTML page to put the section into (before <footer>)")
    args = parser.parse_args()
    {"weights": cmd_weights, "confidence": cmd_confidence, "report": cmd_report}[args.step](args)


if __name__ == "__main__":
    main()
