"""Track A memory trial: PP-FormulaNet_plus-S on the laptop GPU.

From tools/model_prep, with C:\\Projects\\Capstone\\paddle_formula_env:
  python formula_memory_trial.py --data <dir with train.txt and images/> [--batch-sizes 14,8,4,2,1] [--steps 30]

For each batch size, from large to small: fine-tune from the official
training checkpoint for --steps steps with the repo's config
(PP-FormulaNet_plus-S.yaml: 384 x 384, max_new_tokens 1024, AdamW,
full precision), no validation, then stop. Records the trainer's
max_mem_reserved, nvidia-smi's peak, seconds per step and samples per
second, or that it ran out of memory. "fits" means it ran all steps
with the trainer's reserved memory within the card's memory; on Windows
a larger batch can still run by spilling into system memory (reported
as such, and much slower). The largest batch that fits is reported. Nothing is saved as a model; this is a measurement.

The "Snow" augmentation needs ImageMagick (Wand), which is not installed;
it is skipped (returns the image unchanged). The other augmentations run
as configured. Output: <root>/runs/<date>-<time>_trackA_<data>_memory-trial/ (one log
per batch size, results.json, results.md).
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
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

STEP = re.compile(r"global_step: (\d+), .*?avg_batch_cost: ([\d.]+) s, avg_samples: ([\d.]+), ips: ([\d.]+) samples/s"
                  r"(?:.*?max_mem_reserved: (\d+) MB)?")
OOM_SIGNS = ("ResourceExhaustedError", "cudaErrorMemoryAllocation", "CUDA error(2)", "ALLOC_FAILED",
             "ALLOCATION_FAILED", "out of memory")

# Runs inside the trainer process: skip Snow, then PaddleOCR's own train.py.
CHILD = r'''
import os, runpy, sys
sys.path.insert(0, os.getcwd())
import ppocr.data.imaug.unimernet_aug as aug
aug.Snow.apply = lambda self, img, **params: img   # ImageMagick not installed: Snow skipped
sys.argv = ["tools/train.py"] + sys.argv[1:]
runpy.run_path("tools/train.py", run_name="__main__")
'''


class GpuPeak(threading.Thread):
    def __init__(self) -> None:
        super().__init__(daemon=True)
        self.peak, self.stop = 0, threading.Event()

    def run(self) -> None:
        while not self.stop.is_set():
            try:
                out = subprocess.run(["nvidia-smi", "--query-gpu=memory.used,memory.total", "--format=csv,noheader,nounits"],
                                     capture_output=True, text=True, timeout=10).stdout.strip().split(",")
                self.peak = max(self.peak, int(out[0]))
                self.total = int(out[1])
            except Exception:  # noqa: BLE001
                pass
            self.stop.wait(1)


def run_one(batch: int, args, out: Path) -> dict:
    log_path = out / f"bs{batch}.log"
    overrides = [
        f"Global.pretrained_model={PRETRAINED}", f"Global.save_model_dir={out / f'model_bs{batch}'}",
        "Global.epoch_num=1", "Global.print_batch_step=5", "Global.eval_batch_step=[100000000, 100000000]",
        "Global.cal_metric_during_train=False", "Global.use_visualdl=False", "Global.save_epoch_step=1000",
        f"Train.dataset.data_dir={args.data}", f"Train.dataset.label_file_list=['{Path(args.data) / 'train.txt'}']",
        f"Train.loader.batch_size_per_card={batch}", f"Eval.dataset.data_dir={args.data}",
        f"Eval.dataset.label_file_list=['{Path(args.data) / 'val.txt'}']",
    ]
    env = dict(os.environ, PYTHONIOENCODING="utf-8", FLAGS_allocator_strategy="auto_growth")
    sampler = GpuPeak()
    sampler.start()
    start, outcome = time.time(), None
    with open(log_path, "w", encoding="utf-8") as log:
        process = subprocess.Popen([sys.executable, "-c", CHILD, "-c", str(CONFIG), "-o", *overrides], cwd=PADDLEOCR,
                                   stdout=log, stderr=subprocess.STDOUT, env=env)
        while process.poll() is None:
            time.sleep(3)
            text = log_path.read_text(encoding="utf-8", errors="replace")
            if any(s in text for s in OOM_SIGNS):
                outcome = "out of memory"
                break
            done = [int(m.group(1)) for m in STEP.finditer(text)]
            if done and max(done) >= args.steps:
                outcome = "fits"
                break
            if time.time() - start > args.timeout:
                outcome = "timeout"
                break
        if process.poll() is None:
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], capture_output=True)
            process.wait()
    sampler.stop.set()
    text = log_path.read_text(encoding="utf-8", errors="replace")
    if outcome is None:
        outcome = "out of memory" if any(s in text for s in OOM_SIGNS) else f"stopped (exit {process.returncode})"
    steps = [m.groups() for m in STEP.finditer(text)]
    later = steps[1:] or steps  # the first report includes start-up
    result = {"batch_size": batch, "outcome": outcome, "seconds": round(time.time() - start),
              "steps_reported": int(steps[-1][0]) if steps else 0,
              "max_mem_reserved_mb": max((int(s[4]) for s in steps if s[4]), default=None),
              "nvidia_smi_peak_mb": sampler.peak or None, "gpu_total_mb": getattr(sampler, "total", None),
              "seconds_per_step": round(sum(float(s[1]) for s in later) / len(later), 3) if later else None,
              "samples_per_second": round(sum(float(s[3]) for s in later) / len(later), 2) if later else None}
    # On Windows the driver lets Paddle reserve more than the card has by
    # spilling into system memory (much slower). That is not "fits".
    total = result["gpu_total_mb"]
    if outcome == "fits" and total and result["max_mem_reserved_mb"] and result["max_mem_reserved_mb"] > total:
        result["outcome"] = outcome = "runs only by spilling into system memory"
    if "Traceback" in text and outcome != "fits":
        result["error"] = text[text.rfind("Traceback"):][-600:]
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data", required=True, help="folder with train.txt, val.txt and the images they list")
    parser.add_argument("--batch-sizes", default="14,8,4,2,1", help="tried from left to right (14 = the config's)")
    parser.add_argument("--steps", type=int, default=30)
    parser.add_argument("--timeout", type=int, default=900, help="seconds per batch size")
    parser.add_argument("--keep-going", action="store_true", help="also measure the smaller sizes after one fits")
    args = parser.parse_args()

    out = LAYOUT.run_dir("trackA", Path(args.data).name, "memory-trial")
    out.mkdir(parents=True, exist_ok=True)
    results = []
    for batch in [int(b) for b in args.batch_sizes.split(",")]:
        result = run_one(batch, args, out)
        results.append(result)
        print(json.dumps(result))
        if result["outcome"] == "fits" and not args.keep_going:
            break
    fits = [r["batch_size"] for r in results if r["outcome"] == "fits"]
    summary = {"data": args.data, "steps": args.steps, "config": str(CONFIG), "pretrained": str(PRETRAINED),
               "precision": "fp32", "snow_augmentation": "skipped (no ImageMagick)", "results": results,
               "largest_batch_that_fits": max(fits) if fits else None}
    (out / "results.json").write_text(json.dumps(summary, indent=1), encoding="utf-8")
    lines = ["# PP-FormulaNet_plus-S memory trial", "", f"- Data: `{args.data}`; {args.steps} steps per batch size;"
             " fp32; Snow augmentation skipped", "",
             "| batch | outcome | max_mem_reserved MB | nvidia-smi peak MB | s/step | samples/s |", "|---|---|---|---|---|---|"]
    for r in results:
        lines.append(f"| {r['batch_size']} | {r['outcome']} | {r['max_mem_reserved_mb'] or '-'} | {r['nvidia_smi_peak_mb'] or '-'}"
                     f" | {r['seconds_per_step'] or '-'} | {r['samples_per_second'] or '-'} |")
    lines += ["", f"Largest batch that fits: {summary['largest_batch_that_fits']}"]
    (out / "results.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    tidy_run(out)
    print(f"\nOutput (sorted): {out}")


if __name__ == "__main__":
    main()
