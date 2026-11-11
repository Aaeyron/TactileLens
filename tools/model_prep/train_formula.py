"""Track A: fine-tune PP-FormulaNet_plus-S, export to ONNX, compare with the app's model.

From tools/model_prep, with C:\\Projects\\Capstone\\paddle_formula_env:
  python train_formula.py --data <dir> --name check --subset-train 40 --subset-val 16 --epochs 1   # short check
  python train_formula.py --data <dir> --name prelim --epochs 15 --patience 3                       # full run

<dir> holds train.txt, val.txt, test.txt (images/<name><TAB><latex>) and
images/, e.g. tools/dataset/prepare_im2latex.py's output.

1. Trains from the official checkpoint (pretrained/formula/) with
   PaddleOCR's tools/train.py and the repo config, with these overrides:
   batch --batch-size (4 = fits the 6 GB card with headroom), shuffled
   training data, learning rate --lr with --warmup-steps (the config's
   default warmup is 5,000 steps, longer than our runs), full precision,
   validation on val.txt every epoch (--eval-every steps to change).
   The Snow augmentation is skipped (no ImageMagick).
   On Windows, PaddleOCR skips the last batch of every training epoch and
   of every validation; with num_workers 0 there is no reason to, so
   tools/program.py is told the platform is Linux (nothing else changes)
   and every validation image is scored.
2. Model selection: PaddleOCR keeps best_accuracy (highest val exp_rate,
   exact expression match; a tie replaces the earlier one) and latest.
   Early stopping: after --patience validations without a higher
   exp_rate, the run stops (once the following step has started, so the
   saves have finished).
3. Exports best_accuracy with export_formula.py (ONNX), then scores the
   app's ONNX and the new ONNX with evaluate_formula.py (the app's
   preprocessing, CPU, 4 threads) on --eval-list (default test.txt), and
   compares them with compare_formula.py.

Output: <root>/runs/<date>-<time>_trackA_<data>_<name>/ (data: im2latex,
im2latex+synthetic, or the data folder's name), sorted at the end by
common.tidy_run: run.json, summary.md, config/, logs/, charts/,
best_checkpoint/, checkpoints/ (others), onnx/, evaluation/ (the app's
and the new model's scores and the comparison).
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import random
import re
import subprocess
import sys
import threading
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
PADDLEOCR = Path(r"C:\Projects\Capstone\PaddleOCR-official")
CONFIG = PADDLEOCR / "configs" / "rec" / "PP-FormuaNet" / "PP-FormulaNet_plus-S.yaml"
ROOT = Path(os.environ.get("TL_TRAIN_ROOT", r"C:\Projects\Capstone\tactilelens-training"))
sys.path.insert(0, str(HERE.parent / "training"))
from common import Layout, tidy_run  # noqa: E402  (tools/training/common.py: the workspace layout)

LAYOUT = Layout(ROOT)
PRETRAINED = LAYOUT.pretrained / "formula" / "PP-FormulaNet_plus-S_pretrained"
ONNX_PYTHON = Path(r"C:\Projects\Capstone\paddle_onnx_env\Scripts\python.exe")
APP_MODEL = HERE.parents[1] / "frontend" / "android" / "app" / "src" / "main" / "assets" / "paddle_onnx" / \
    "PP-FormulaNet_plus-S" / "pp-formulanet_plus-s.onnx"

STEP = re.compile(r"epoch: \[(\d+)/(\d+)\], global_step: (\d+), .*?avg_batch_cost: ([\d.]+) s, avg_samples: ([\d.]+), "
                  r"ips: ([\d.]+) samples/s(?:.*?max_mem_reserved: (\d+) MB)?")
METRIC = re.compile(r"cur metric, (.*)")
OOM_SIGNS = ("ResourceExhaustedError", "cudaErrorMemoryAllocation", "CUDA error(2)", "ALLOC_FAILED",
             "ALLOCATION_FAILED", "out of memory")

CHILD = r'''
import os, runpy, sys, types
sys.path.insert(0, os.getcwd())
import ppocr.data.imaug.unimernet_aug as aug
aug.Snow.apply = lambda self, img, **params: img   # ImageMagick not installed: Snow skipped
import tools.program as program
program.platform = types.SimpleNamespace(system=lambda: "Linux")   # score every batch (num_workers 0)
sys.argv = ["tools/train.py"] + sys.argv[1:]
runpy.run_path("tools/train.py", run_name="__main__")
'''


EVAL_CHILD = CHILD.replace('"tools/train.py"', '"tools/eval.py"')


def baseline_validation(overrides: list[str], out: Path) -> dict | None:
    """PaddleOCR's metric for the original checkpoint on the same val list (step 0)."""

    keep = [o for o in overrides if o.startswith(("Global.pretrained_model", "Eval.", "Global.use_gpu",
                                                   "Global.print_mem_info", "Global.seed"))]
    log = out / "baseline_val.log"
    env = dict(os.environ, PYTHONIOENCODING="utf-8", FLAGS_allocator_strategy="auto_growth")
    with open(log, "w", encoding="utf-8") as handle:
        subprocess.run([sys.executable, "-c", EVAL_CHILD, "-c", str(CONFIG), "-o", *keep], cwd=PADDLEOCR,
                       stdout=handle, stderr=subprocess.STDOUT, env=env)
    text = log.read_text(encoding="utf-8", errors="replace")
    values = dict(re.findall(r"ppocr INFO: (exp_rate|edit distance|bleu_score):\s*([\d.]+)", text))
    return {k: float(v) for k, v in values.items()} or None


class GpuLog(threading.Thread):
    def __init__(self, path: Path) -> None:
        super().__init__(daemon=True)
        self.path, self.peak, self.total, self.stop = path, 0, None, threading.Event()

    def run(self) -> None:
        with open(self.path, "w", encoding="utf-8") as handle:
            handle.write("seconds,memory_used_mb\n")
            start = time.time()
            while not self.stop.is_set():
                try:
                    used, total = subprocess.run(
                        ["nvidia-smi", "--query-gpu=memory.used,memory.total", "--format=csv,noheader,nounits"],
                        capture_output=True, text=True, timeout=10).stdout.strip().split(",")
                    self.peak, self.total = max(self.peak, int(used)), int(total)
                    handle.write(f"{time.time() - start:.0f},{int(used)}\n")
                    handle.flush()
                except Exception:  # noqa: BLE001
                    pass
                self.stop.wait(5)


def check_label_file(path: Path) -> None:
    """PaddleOCR strips only "\\n" from each line: a CRLF file leaves "\\r" at
    the end of every label, the model learns it and no prediction matches."""

    if b"\r" in path.read_bytes():
        raise SystemExit(f"{path} has CR (Windows) line ends; rewrite it with LF only")


def subset(src: Path, n: int | None, out: Path, seed: int) -> Path:
    lines = [l for l in src.read_text(encoding="utf-8").splitlines() if l.strip()]
    if n is None or n >= len(lines):
        return src
    random.Random(seed).shuffle(lines)
    with open(out, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines[:n]) + "\n")
    return out


def parse_metric(text: str) -> dict:
    values = {}
    for part in text.split(", "):
        if ": " in part:
            k, v = part.split(": ", 1)
            try:
                values[k.strip()] = float(v)
            except ValueError:
                pass
    return values


def latex_key(label: str) -> str:
    return re.sub(r"\s+", "", label)


def extra_training_list(folder: Path, held_out: list[Path], out: Path) -> dict:
    """Extra training data (e.g. the synthetic pilot): its train.txt with
    absolute image paths (PaddleOCR joins data_dir with a relative path; an
    absolute one is used as is), minus any formula that is also in the
    validation list or the final evaluation list (leak guard, checked again
    here although the generator already guards)."""

    src = folder / "train.txt"
    check_label_file(src)
    held = set()
    for path in held_out:
        held |= {latex_key(l.split("\t", 1)[1]) for l in path.read_text(encoding="utf-8").splitlines() if "\t" in l}
    kept, dropped = [], 0
    for line in src.read_text(encoding="utf-8").splitlines():
        if "\t" not in line:
            continue
        image, label = line.split("\t", 1)
        if latex_key(label) in held:
            dropped += 1
            continue
        kept.append(f"{(folder / image).resolve()}\t{label}")
    target = out / "extra_train.txt"
    with open(target, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(kept) + "\n")
    return {"list": target, "items": len(kept), "dropped_by_leak_guard": dropped, "source": str(folder)}


def train(args, out: Path, data: Path) -> dict:
    train_list = subset(data / "train.txt", args.subset_train, out / "train_subset.txt", args.seed)
    val_list = subset(data / "val.txt", args.subset_val, out / "val_subset.txt", args.seed)
    n_train = sum(1 for l in train_list.read_text(encoding="utf-8").splitlines() if l.strip())
    n_val = sum(1 for l in val_list.read_text(encoding="utf-8").splitlines() if l.strip())
    lists, ratios, extra = [train_list], [1.0], None
    if args.extra_train:
        extra = extra_training_list(Path(args.extra_train), [val_list, Path(args.eval_list_resolved)], out)
        lists.append(extra["list"])
        ratios.append(args.extra_ratio)
    per_epoch = n_train + (round(extra["items"] * args.extra_ratio) if extra else 0)
    steps_per_epoch = -(-per_epoch // args.batch_size)
    eval_every = args.eval_every or steps_per_epoch
    overrides = [
        f"Global.pretrained_model={PRETRAINED}", f"Global.save_model_dir={out / 'model'}",
        f"Global.epoch_num={args.epochs}", "Global.print_batch_step=10",
        # True as in the config: PaddleOCR switches validation to the formula
        # path only inside the training-metric code (False breaks validation).
        f"Global.eval_batch_step=[0, {eval_every}]", "Global.cal_metric_during_train=True",
        "Global.use_visualdl=False", "Global.save_epoch_step=100000", f"Global.seed={args.seed}",
        f"Optimizer.lr.learning_rate={args.lr}", f"Optimizer.lr.warmup_steps={args.warmup_steps}",
        f"Train.dataset.data_dir={data}",
        "Train.dataset.label_file_list=[" + ", ".join(f"'{p}'" for p in lists) + "]",
        "Train.dataset.ratio_list=[" + ", ".join(str(r) for r in ratios) + "]",
        "Train.loader.shuffle=True", f"Train.loader.batch_size_per_card={args.batch_size}",
        f"Eval.dataset.data_dir={data}", f"Eval.dataset.label_file_list=['{val_list}']",
        f"Eval.loader.batch_size_per_card={args.eval_batch_size}",
    ] + (["Global.use_gpu=False", "Global.print_mem_info=False"] if args.cpu else [])
    baseline = baseline_validation(overrides, out)
    log_path = out / "train.log"
    env = dict(os.environ, PYTHONIOENCODING="utf-8", FLAGS_allocator_strategy="auto_growth")
    gpu = GpuLog(out / "gpu_memory.csv")
    gpu.start()
    start, stopped_early, outcome = time.time(), None, None
    with open(log_path, "w", encoding="utf-8") as log:
        process = subprocess.Popen([sys.executable, "-c", CHILD, "-c", str(CONFIG), "-o", *overrides], cwd=PADDLEOCR,
                                   stdout=log, stderr=subprocess.STDOUT, env=env)
        while process.poll() is None:
            time.sleep(10)
            text = log_path.read_text(encoding="utf-8", errors="replace")
            if any(s in text for s in OOM_SIGNS):
                outcome = "out of memory"
                break
            metrics = [parse_metric(m.group(1)) for m in METRIC.finditer(text)]
            if args.patience and len(metrics) > args.patience:
                rates = [m.get("exp_rate", 0.0) for m in metrics]
                best_at = max(range(len(rates)), key=lambda i: (rates[i], -i))  # first time the best was reached
                if len(rates) - 1 - best_at >= args.patience:
                    after_last = text[text.rfind("cur metric"):]
                    if STEP.search(after_last):
                        stopped_early = (f"no higher val exp_rate in the last {args.patience} validations"
                                         f" (best {rates[best_at]} at validation {best_at + 1})")
                        break
        if process.poll() is None:
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], capture_output=True)
            process.wait()
    gpu.stop.set()
    text = log_path.read_text(encoding="utf-8", errors="replace")
    if outcome is None:
        if stopped_early:
            outcome = "stopped early"
        elif process.returncode == 0:
            outcome = "finished"
        else:
            outcome = "out of memory" if any(s in text for s in OOM_SIGNS) else f"failed (exit {process.returncode})"
    steps = [m.groups() for m in STEP.finditer(text)]
    later = steps[1:] or steps
    metrics = [parse_metric(m.group(1)) for m in METRIC.finditer(text)]
    result = {
        "outcome": outcome, "stopped_early": stopped_early, "seconds": round(time.time() - start),
        "train_items": n_train, "val_items": n_val, "steps_per_epoch": steps_per_epoch, "eval_every_steps": eval_every,
        "last_step": int(steps[-1][2]) if steps else 0, "last_epoch": int(steps[-1][0]) if steps else 0,
        "max_mem_reserved_mb": max((int(s[6]) for s in steps if s[6]), default=None),
        "nvidia_smi_peak_mb": gpu.peak or None, "gpu_total_mb": gpu.total,
        "seconds_per_step": round(sum(float(s[3]) for s in later) / len(later), 3) if later else None,
        "validations": metrics, "baseline_validation": baseline,
        "extra_train": {k: str(v) if isinstance(v, Path) else v for k, v in extra.items()} if extra else None,
        "extra_ratio": args.extra_ratio if extra else None, "items_per_epoch": per_epoch,
    }
    if result["max_mem_reserved_mb"] and gpu.total and result["max_mem_reserved_mb"] > gpu.total:
        result["memory_note"] = "reserved more than the card has: spilled into system memory (slower)"
    if "Traceback" in text and outcome not in ("finished", "stopped early"):
        result["error"] = text[text.rfind("Traceback"):][-800:]
    result["loss_history"], result["validation_steps"] = history(text)
    return result


LOSS = re.compile(r"epoch: \[(\d+)/\d+\], global_step: (\d+), lr: ([\d.e-]+),.*? loss: ([\d.]+),")


def history(text: str) -> tuple[list[dict], list[int]]:
    """Training loss per logged step (PaddleOCR's smoothed loss over 10 steps)
    and the global step of each validation."""

    losses = [{"epoch": int(m.group(1)), "step": int(m.group(2)), "lr": float(m.group(3)), "loss": float(m.group(4))}
              for m in LOSS.finditer(text)]
    val_steps = []
    for m in METRIC.finditer(text):
        before = [int(s.group(2)) for s in LOSS.finditer(text[:m.start()])]
        val_steps.append(before[-1] if before else 0)
    return losses, val_steps


def write_curves(out: Path, t: dict) -> None:
    import csv

    from charts import line_chart

    with open(out / "loss_curve.csv", "w", encoding="utf-8", newline="") as handle:
        w = csv.DictWriter(handle, fieldnames=["epoch", "step", "lr", "loss"])
        w.writeheader()
        w.writerows(t["loss_history"])
    n = t["val_items"]
    pairs = ([(0, t["baseline_validation"])] if t.get("baseline_validation") else []) + list(
        zip(t["validation_steps"], t["validations"]))
    rows = [{"validation": i, "step": s, "exp_rate_pct": round(100 * m.get("exp_rate", 0), 1),
             "exact": round(m.get("exp_rate", 0) * n), "items": n, "edit_distance": m.get("edit distance")}
            for i, (s, m) in enumerate(pairs, 0 if t.get("baseline_validation") else 1)]
    with open(out / "validation_history.csv", "w", encoding="utf-8", newline="") as handle:
        w = csv.DictWriter(handle, fieldnames=["validation", "step", "exp_rate_pct", "exact", "items", "edit_distance"])
        w.writeheader()
        w.writerows(rows)
    if t["loss_history"]:
        line_chart({"training loss (smoothed, 10 steps)": [(r["step"], r["loss"]) for r in t["loss_history"]]},
                   "PP-FormulaNet_plus-S fine-tuning: training loss", "step", "loss", out / "loss_curve.png",
                   note=f"{t['train_items']} im2latex-100k formulas (filtered to general-algebra notation; from physics "
                        f"papers)" + (f" + {round(t['extra_train']['items'] * t['extra_ratio'])} synthetic per epoch"
                                      if t.get("extra_train") else "") + f"; batch {t.get('batch_size', '')}")
    if rows:
        line_chart({"validation exact match %": [(r["step"], r["exp_rate_pct"]) for r in rows]},
                   f"Validation exact match ({n} formulas)", "step", "exact match %", out / "validation_history.png",
                   note="Step 0 = the original model. Exact = PaddleOCR's exp_rate (after its normalisation); count above each point",
                   markers=True, y_range=(0, 100), point_labels={"validation exact match %": [f"{r['exact']}/{n}" for r in rows]})


def run(cmd: list[str], log: Path, cwd: Path = HERE) -> tuple[int, str]:
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    with open(log, "w", encoding="utf-8") as handle:
        code = subprocess.run(cmd, cwd=cwd, stdout=handle, stderr=subprocess.STDOUT, env=env).returncode
    return code, log.read_text(encoding="utf-8", errors="replace")


def evaluate(model: Path, labels: Path, tag: str, out: Path, sub: str) -> Path | None:
    code, text = run([str(ONNX_PYTHON), "evaluate_formula.py", "--labels", str(labels), "--model", str(model),
                      "--tag", tag, "--root", str(ROOT), "--out", str(out / "eval" / sub)], out / f"eval_{sub}.log")
    found = re.findall(r"Written to (.+)", text)
    return Path(found[-1].strip()) if code == 0 and found else None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--epochs", type=int, default=20)
    parser.add_argument("--batch-size", type=int, default=4)
    parser.add_argument("--eval-batch-size", type=int, default=8)
    parser.add_argument("--eval-every", type=int, help="validate every N steps (default: once per epoch)")
    parser.add_argument("--patience", type=int, default=3, help="validations without a higher exp_rate; 0 = off")
    parser.add_argument("--lr", type=float, default=2e-5)
    parser.add_argument("--warmup-steps", type=int, default=100)
    parser.add_argument("--subset-train", type=int, help="use N training items (short check)")
    parser.add_argument("--subset-val", type=int, help="use N validation items (short check)")
    parser.add_argument("--eval-list", help="formula list for the final comparison (default: <data>/test.txt)")
    parser.add_argument("--seed", type=int, default=1024,
                        help="PaddleOCR's Global.seed (its default) and the subset draw; augmentation and GPU kernels"
                             " can still make two runs differ")
    parser.add_argument("--cpu", action="store_true", help="train on the CPU (plumbing checks only; very slow)")
    parser.add_argument("--no-final-eval", action="store_true",
                        help="plumbing checks: export, but do not score anything on the evaluation list")
    parser.add_argument("--extra-train",help="folder with an extra train.txt (e.g. the synthetic pilot); training only")
    parser.add_argument("--extra-ratio", type=float, default=1.0,
                        help="share of the extra list drawn each epoch (PaddleOCR ratio_list; a new draw per epoch)")
    args = parser.parse_args()

    data = Path(args.data).resolve()
    eval_list = Path(args.eval_list).resolve() if args.eval_list else data / "test.txt"
    args.eval_list_resolved = str(eval_list)
    for f in (data / "train.txt", data / "val.txt", eval_list, PRETRAINED.with_suffix(".pdparams")):
        if not f.exists():
            raise SystemExit(f"missing {f}")
    for f in (data / "train.txt", data / "val.txt", eval_list):
        check_label_file(f)
    data_tag = ("im2latex" if "im2latex" in str(data) else data.name) + ("+synthetic" if args.extra_train else "")
    out = LAYOUT.run_dir("trackA", data_tag, args.name)
    out.mkdir(parents=True)
    info = {"args": vars(args), "config": str(CONFIG), "pretrained": str(PRETRAINED), "precision": "fp32",
            "snow_augmentation": "skipped (no ImageMagick)", "eval_list": str(eval_list)}
    print(f"Output: {out}")

    info["train"] = train(args, out, data)
    info["train"]["batch_size"] = args.batch_size
    write_curves(out, info["train"])
    print(json.dumps({k: v for k, v in info["train"].items() if k != "loss_history"}, indent=1))
    checkpoint = out / "model" / "best_accuracy"
    if not checkpoint.with_suffix(".pdparams").exists():
        checkpoint = out / "model" / "latest"
    if info["train"]["outcome"] not in ("finished", "stopped early") or not checkpoint.with_suffix(".pdparams").exists():
        info["result"] = "training did not finish; nothing exported"
    else:
        info["exported_checkpoint"] = str(checkpoint)
        code, text = run([sys.executable, "export_formula.py", "--checkpoint", str(checkpoint),
                          "--out", str(out / "export")], out / "export.log")
        onnx = out / "export" / "onnx" / "inference.onnx"
        info["export"] = "ok" if code == 0 and onnx.exists() else f"failed (exit {code}), see export.log"
        if info["export"] == "ok" and args.no_final_eval:
            info["comparison"] = "skipped (--no-final-eval: the evaluation list is kept for the real run)"
        elif info["export"] == "ok":
            before = evaluate(APP_MODEL, eval_list, "app", out, "app")
            after = evaluate(onnx, eval_list, f"run_{out.name}", out, "new")
            info["eval_app"], info["eval_new"] = str(before), str(after)
            if before and after:
                code, text = run([str(ONNX_PYTHON), "compare_formula.py", "--before", str(before), "--after", str(after),
                                  "--out", str(out / "eval")], out / "compare.log")
                info["comparison"] = str(out / "eval" / "comparison.md") if code == 0 else "failed, see compare.log"
    (out / "run.json").write_text(json.dumps(info, indent=1), encoding="utf-8")

    t = info["train"]
    extra = t.get("extra_train")
    lines = [f"# Track A run `{out.name}`", "", f"- Data: `{data}` ({t['train_items']} train, {t['val_items']} val)",
             (f"- Extra training data: `{extra['source']}` ({extra['items']} items, {extra['dropped_by_leak_guard']} "
              f"dropped by the leak guard), ratio {t['extra_ratio']} per epoch; {t['items_per_epoch']} items per epoch"
              if extra else "- Extra training data: none"),
             f"- Batch {args.batch_size}, lr {args.lr}, warmup {args.warmup_steps} steps, up to {args.epochs} epochs,"
             f" patience {args.patience}, seed {args.seed}; fp32; Snow skipped",
             "- Charts: `loss_curve.png`, `validation_history.png` (data in the .csv files)",
             f"- Outcome: {t['outcome']}{' (' + t['stopped_early'] + ')' if t['stopped_early'] else ''};"
             f" {t['last_step']} steps in {t['seconds']} s, {t['seconds_per_step']} s/step",
             f"- Memory: trainer reserved {t['max_mem_reserved_mb']} MB, nvidia-smi peak {t['nvidia_smi_peak_mb']} MB"
             f" of {t['gpu_total_mb']} MB", "", "| validation | step | exact match | edit distance | BLEU |",
             "|---|---|---|---|---|"]
    n = t["val_items"]
    base = [("original", 0, t["baseline_validation"])] if t.get("baseline_validation") else []
    for i, step, m in base + [(i, s, m) for i, (s, m) in enumerate(zip(t["validation_steps"], t["validations"]), 1)]:
        rate = m.get("exp_rate", 0)
        lines.append(f"| {i} | {step} | {100 * rate:.1f}% ({round(rate * n)}/{n}) | {m.get('edit distance', 0):.4f}"
                     f" | {m.get('bleu_score', 0):.4f} |")
    lines += ["", f"- Exported: `{info.get('exported_checkpoint', '-')}`, export {info.get('export', '-')}",
              f"- Comparison on `{eval_list.name}`: {info.get('comparison', info.get('result', '-'))}"]
    if info.get("comparison", "").endswith(".md"):
        lines += ["", Path(info["comparison"]).read_text(encoding="utf-8")]
    (out / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    # Sort the finished run (config/ logs/ charts/ best_checkpoint/ onnx/ evaluation/).
    tidy_run(out)
    print(f"\nRun folder (sorted): {out}")


if __name__ == "__main__":
    main()
