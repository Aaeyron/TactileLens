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

Output: <root>/outputs/formula_runs/<time>_<name>/ with train.log,
gpu_memory.csv, run.json, summary.md, model/ (checkpoints), export/
and eval/.
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
PRETRAINED = ROOT / "pretrained" / "formula" / "PP-FormulaNet_plus-S_pretrained"
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


def train(args, out: Path, data: Path) -> dict:
    train_list = subset(data / "train.txt", args.subset_train, out / "train_subset.txt", args.seed)
    val_list = subset(data / "val.txt", args.subset_val, out / "val_subset.txt", args.seed)
    n_train = sum(1 for l in train_list.read_text(encoding="utf-8").splitlines() if l.strip())
    n_val = sum(1 for l in val_list.read_text(encoding="utf-8").splitlines() if l.strip())
    steps_per_epoch = -(-n_train // args.batch_size)
    eval_every = args.eval_every or steps_per_epoch
    overrides = [
        f"Global.pretrained_model={PRETRAINED}", f"Global.save_model_dir={out / 'model'}",
        f"Global.epoch_num={args.epochs}", "Global.print_batch_step=10",
        # True as in the config: PaddleOCR switches validation to the formula
        # path only inside the training-metric code (False breaks validation).
        f"Global.eval_batch_step=[0, {eval_every}]", "Global.cal_metric_during_train=True",
        "Global.use_visualdl=False", "Global.save_epoch_step=100000",
        f"Optimizer.lr.learning_rate={args.lr}", f"Optimizer.lr.warmup_steps={args.warmup_steps}",
        f"Train.dataset.data_dir={data}", f"Train.dataset.label_file_list=['{train_list}']",
        "Train.loader.shuffle=True", f"Train.loader.batch_size_per_card={args.batch_size}",
        f"Eval.dataset.data_dir={data}", f"Eval.dataset.label_file_list=['{val_list}']",
        f"Eval.loader.batch_size_per_card={args.eval_batch_size}",
    ] + (["Global.use_gpu=False", "Global.print_mem_info=False"] if args.cpu else [])
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
        "validations": metrics,
    }
    if result["max_mem_reserved_mb"] and gpu.total and result["max_mem_reserved_mb"] > gpu.total:
        result["memory_note"] = "reserved more than the card has: spilled into system memory (slower)"
    if "Traceback" in text and outcome not in ("finished", "stopped early"):
        result["error"] = text[text.rfind("Traceback"):][-800:]
    return result


def run(cmd: list[str], log: Path, cwd: Path = HERE) -> tuple[int, str]:
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    with open(log, "w", encoding="utf-8") as handle:
        code = subprocess.run(cmd, cwd=cwd, stdout=handle, stderr=subprocess.STDOUT, env=env).returncode
    return code, log.read_text(encoding="utf-8", errors="replace")


def evaluate(model: Path, labels: Path, tag: str, out: Path) -> Path | None:
    code, text = run([str(ONNX_PYTHON), "evaluate_formula.py", "--labels", str(labels), "--model", str(model),
                      "--tag", tag, "--root", str(ROOT)], out / f"eval_{tag}.log")
    found = re.findall(r"Written to (.+)", text)
    return Path(found[-1].strip()) if code == 0 and found else None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--epochs", type=int, default=15)
    parser.add_argument("--batch-size", type=int, default=4)
    parser.add_argument("--eval-batch-size", type=int, default=8)
    parser.add_argument("--eval-every", type=int, help="validate every N steps (default: once per epoch)")
    parser.add_argument("--patience", type=int, default=3, help="validations without a higher exp_rate; 0 = off")
    parser.add_argument("--lr", type=float, default=2e-5)
    parser.add_argument("--warmup-steps", type=int, default=100)
    parser.add_argument("--subset-train", type=int, help="use N training items (short check)")
    parser.add_argument("--subset-val", type=int, help="use N validation items (short check)")
    parser.add_argument("--eval-list", help="formula list for the final comparison (default: <data>/test.txt)")
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--cpu", action="store_true", help="train on the CPU (plumbing checks only; very slow)")
    args = parser.parse_args()

    data = Path(args.data).resolve()
    eval_list = Path(args.eval_list).resolve() if args.eval_list else data / "test.txt"
    for f in (data / "train.txt", data / "val.txt", eval_list, PRETRAINED.with_suffix(".pdparams")):
        if not f.exists():
            raise SystemExit(f"missing {f}")
    for f in (data / "train.txt", data / "val.txt", eval_list):
        check_label_file(f)
    out = ROOT / "outputs" / "formula_runs" / f"{dt.datetime.now():%Y%m%d_%H%M%S}_{args.name}"
    out.mkdir(parents=True)
    info = {"args": vars(args), "config": str(CONFIG), "pretrained": str(PRETRAINED), "precision": "fp32",
            "snow_augmentation": "skipped (no ImageMagick)", "eval_list": str(eval_list)}
    print(f"Output: {out}")

    info["train"] = train(args, out, data)
    print(json.dumps(info["train"], indent=1))
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
        if info["export"] == "ok":
            before = evaluate(APP_MODEL, eval_list, "app", out)
            after = evaluate(onnx, eval_list, f"run_{out.name}", out)
            info["eval_app"], info["eval_new"] = str(before), str(after)
            if before and after:
                code, text = run([str(ONNX_PYTHON), "compare_formula.py", "--before", str(before), "--after", str(after),
                                  "--out", str(out / "eval")], out / "compare.log")
                info["comparison"] = str(out / "eval" / "comparison.md") if code == 0 else "failed, see compare.log"
    (out / "run.json").write_text(json.dumps(info, indent=1), encoding="utf-8")

    t = info["train"]
    lines = [f"# Track A run `{out.name}`", "", f"- Data: `{data}` ({t['train_items']} train, {t['val_items']} val)",
             f"- Batch {args.batch_size}, lr {args.lr}, warmup {args.warmup_steps} steps, up to {args.epochs} epochs,"
             f" patience {args.patience}; fp32; Snow skipped",
             f"- Outcome: {t['outcome']}{' (' + t['stopped_early'] + ')' if t['stopped_early'] else ''};"
             f" {t['last_step']} steps in {t['seconds']} s, {t['seconds_per_step']} s/step",
             f"- Memory: trainer reserved {t['max_mem_reserved_mb']} MB, nvidia-smi peak {t['nvidia_smi_peak_mb']} MB"
             f" of {t['gpu_total_mb']} MB", "", "| validation | exp_rate | other |", "|---|---|---|"]
    for i, m in enumerate(t["validations"], 1):
        lines.append(f"| {i} | {m.get('exp_rate')} | " + ", ".join(f"{k} {v}" for k, v in m.items() if k != "exp_rate") + " |")
    lines += ["", f"- Exported: `{info.get('exported_checkpoint', '-')}`, export {info.get('export', '-')}",
              f"- Comparison on `{eval_list.name}`: {info.get('comparison', info.get('result', '-'))}"]
    if info.get("comparison", "").endswith(".md"):
        lines += ["", Path(info["comparison"]).read_text(encoding="utf-8")]
    (out / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
