"""Fine-tune the recognizer for a limited time (a trial), logging everything.

Run with the training environment, from tools/training:
  C:\\Projects\\Capstone\\paddle_train_env\\Scripts\\python train_trial.py --minutes 10

What it does:
  1. Builds the training list from the TRAINING label files only
     (data/synthetic/train.txt, data/real/train.txt) and runs the guard
     that stops if any eval image is in it. Validation: data/synthetic/val.txt.
  2. Writes the config (the repo's PP-OCRv6_small_rec.yml with the
     overrides below) and run.json (every hyperparameter, data counts,
     package versions, pretrained sha256) to <root>/outputs/trials/<run>/.
  3. Tries batch sizes from large to small until one starts without running
     out of GPU memory, then trains until --minutes is up (the trainer
     saves a "latest" checkpoint after every epoch, and "best_accuracy"
     when validation improves).
  4. Samples GPU memory with nvidia-smi, parses the trainer's log and writes
     loss_curve.csv and summary.json.

It never touches the app and never starts a full run by itself.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import os
import re
import subprocess
import sys
import threading
import time
from collections import Counter
from pathlib import Path

import yaml

from common import Layout, check_no_eval_in_training, read_labels, read_manifest, root_dir, sha256_of

PADDLEOCR = Path(r"C:\Projects\Capstone\PaddleOCR-official")
CONFIG = PADDLEOCR / "configs" / "rec" / "PP-OCRv6" / "PP-OCRv6_small_rec.yml"
PRETRAINED = Path(r"C:\Projects\Capstone\tactilelens-training\pretrained\PP-OCRv6_small_rec_pretrained.pdparams")

STEP_LINE = re.compile(
    r"epoch: \[(\d+)/(\d+)\], global_step: (\d+), lr: ([\d.e-]+), (.*?), avg_reader_cost: ([\d.]+) s, "
    r"avg_batch_cost: ([\d.]+) s, avg_samples: ([\d.]+), ips: ([\d.]+) samples/s"
    r"(?:, eta: [^,]*)?(?:, max_mem_reserved: (\d+) MB,)?(?: max_mem_allocated: (\d+) MB)?"
)
EVAL_LINE = re.compile(r"cur metric, (.*)")


def build_lists(layout: Layout, run_dir: Path) -> dict:
    """train_list.txt with paths relative to <root>/data; counts per source."""

    check_no_eval_in_training(layout)
    data_dir = layout.root / "data"
    rows, counts = [], Counter()
    sources = {"synthetic": layout.label_file("synthetic-train"), "real": layout.label_file("real-train")}
    for name, label_file in sources.items():
        for image, text in read_labels(label_file):
            rows.append((f"{name}/{image}", text))
            counts[name] += 1
    with open(run_dir / "train_list.txt", "w", encoding="utf-8", newline="\n") as handle:
        for image, text in rows:
            handle.write(f"{image}\t{text}\n")
    val = [(f"synthetic/{i}", t) for i, t in read_labels(layout.label_file("synthetic-val"))]
    with open(run_dir / "val_list.txt", "w", encoding="utf-8", newline="\n") as handle:
        for image, text in val:
            handle.write(f"{image}\t{text}\n")

    manifest = list(read_manifest(layout.manifest("synthetic-train"))) + list(read_manifest(layout.manifest("real-train")))
    plain = sum(1 for r in manifest if not r.get("has_superscript", any(c in "⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿ" for c in r["label"])))
    return {
        "train_lines": len(rows),
        "train_by_source": dict(counts),
        "train_without_superscript": plain,
        "train_without_superscript_pct": round(100 * plain / max(len(manifest), 1), 1),
        "train_by_topic": dict(Counter(r.get("topic", "unknown") for r in manifest)),
        "train_longer_than_25_chars": sum(1 for _, t in rows if len(t) > 25),
        "val_lines": len(val),
        "data_dir": str(data_dir),
    }


def make_config(args, run_dir: Path, data_dir: Path, batch_size: int) -> Path:
    config = yaml.safe_load(CONFIG.read_text(encoding="utf-8"))
    g = config["Global"]
    g.update({
        "epoch_num": args.epochs,
        "save_model_dir": str(run_dir / "model"),
        "save_epoch_step": 1,
        "eval_batch_step": [0, args.eval_every],
        "print_batch_step": 10,
        "pretrained_model": str(PRETRAINED.with_suffix("")),
        "character_dict_path": str(PADDLEOCR / "ppocr" / "utils" / "dict" / "ppocrv6_dict.txt"),
        "use_space_char": True,
        "distributed": False,
        "use_gpu": True,
        "save_res_path": str(run_dir / "predicts.txt"),
        "use_visualdl": False,
    })
    if args.amp:
        g.update({"use_amp": True, "amp_level": "O1", "scale_loss": 1024.0, "use_dynamic_loss_scaling": True})
    config["Optimizer"]["lr"].update({"learning_rate": args.lr, "warmup_epoch": args.warmup_epochs})

    train = config["Train"]
    train["dataset"]["data_dir"] = str(data_dir)
    train["dataset"]["label_file_list"] = [str(run_dir / "train_list.txt")]
    train["sampler"]["first_bs"] = batch_size
    train["loader"].update({"batch_size_per_card": batch_size, "num_workers": args.workers, "use_shared_memory": False})

    evaluation = config["Eval"]
    evaluation["dataset"]["data_dir"] = str(data_dir)
    evaluation["dataset"]["label_file_list"] = [str(run_dir / "val_list.txt")]
    evaluation["loader"].update({"batch_size_per_card": batch_size, "num_workers": min(args.workers, 1), "use_shared_memory": False})

    path = run_dir / f"config_bs{batch_size}.yml"
    path.write_text(yaml.safe_dump(config, allow_unicode=True, sort_keys=False), encoding="utf-8")
    return path


class GpuSampler(threading.Thread):
    def __init__(self) -> None:
        super().__init__(daemon=True)
        self.peak = 0
        self.stop = threading.Event()

    def run(self) -> None:
        while not self.stop.is_set():
            try:
                used = subprocess.run(
                    ["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
                    capture_output=True, text=True, timeout=10,
                ).stdout.strip().splitlines()[0]
                self.peak = max(self.peak, int(used))
            except Exception:
                pass
            self.stop.wait(2)


def run_training(python: str, config: Path, log_path: Path, seconds: float, probe: bool) -> tuple[str, float]:
    """Returns (outcome, seconds run). outcome: oom, finished, time_up, error."""

    start = time.time()
    env = dict(os.environ, PYTHONIOENCODING="utf-8", FLAGS_allocator_strategy="auto_growth")
    with open(log_path, "w", encoding="utf-8") as log:
        process = subprocess.Popen(
            [python, "tools/train.py", "-c", str(config)], cwd=PADDLEOCR, stdout=log, stderr=subprocess.STDOUT, env=env,
        )
        outcome = None
        while process.poll() is None:
            time.sleep(5)
            text = log_path.read_text(encoding="utf-8", errors="replace")
            if "Out of memory" in text or "ResourceExhaustedError" in text or "out of memory" in text.lower():
                outcome = "oom"
                break
            if probe and "global_step: 20," in text:
                outcome = "fits"
                break
            if time.time() - start > seconds:
                outcome = "time_up"
                break
        if process.poll() is None:
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], capture_output=True)
            process.wait()
        if outcome is None:
            text = log_path.read_text(encoding="utf-8", errors="replace")
            outcome = "oom" if "out of memory" in text.lower() else ("finished" if process.returncode == 0 else "error")
    return outcome, time.time() - start


def parse_log(log_path: Path) -> tuple[list[dict], list[dict]]:
    steps, evals = [], []
    for line in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = STEP_LINE.search(line)
        if match:
            losses = dict(part.split(": ") for part in match.group(5).split(", ") if ": " in part)
            steps.append({
                "time": line[:19],
                "epoch": int(match.group(1)),
                "step": int(match.group(3)),
                "lr": float(match.group(4)),
                **{k: float(v) for k, v in losses.items() if re.fullmatch(r"[\d.e-]+", v)},
                "reader_s": float(match.group(6)),
                "batch_s": float(match.group(7)),
                "ips": float(match.group(9)),
                "mem_reserved_mb": int(match.group(10)) if match.group(10) else None,
                "mem_allocated_mb": int(match.group(11)) if match.group(11) else None,
            })
        eval_match = EVAL_LINE.search(line)
        if eval_match:
            evals.append({"time": line[:19], "metrics": eval_match.group(1)})
    return steps, evals


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root")
    parser.add_argument("--minutes", type=float, default=10.0)
    parser.add_argument("--batch-sizes", default="96,64,48,32,16", help="tried from left to right")
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--warmup-epochs", type=float, default=0.5)
    parser.add_argument("--epochs", type=int, default=20, help="scheduler length; the trial stops at --minutes")
    parser.add_argument("--eval-every", type=int, default=100, help="validation every N steps")
    parser.add_argument("--workers", type=int, default=2)
    parser.add_argument("--amp", action=argparse.BooleanOptionalAction, default=True)
    args = parser.parse_args()

    layout = Layout(root_dir(args.root))
    run_id = dt.datetime.now().strftime("%Y%m%d_%H%M%S") + "_trial"
    run_dir = layout.outputs / "trials" / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    data = build_lists(layout, run_dir)

    import paddle  # noqa: E402  (training env only)

    run = {
        "run_id": run_id,
        "kind": "trial",
        "started": dt.datetime.now().isoformat(timespec="seconds"),
        "args": vars(args),
        "data": data,
        "base_config": str(CONFIG),
        "pretrained": {"path": str(PRETRAINED), "sha256": sha256_of(PRETRAINED)},
        "environment": {"python": sys.version.split()[0], "paddle": paddle.__version__, "cuda": paddle.version.cuda()},
        "batch_attempts": [],
    }
    (run_dir / "run.json").write_text(json.dumps(run, ensure_ascii=False, indent=1), encoding="utf-8")

    # Find the largest batch that runs 20 steps without running out of memory.
    chosen = None
    for batch_size in [int(b) for b in args.batch_sizes.split(",")]:
        config = make_config(args, run_dir, Path(data["data_dir"]), batch_size)
        sampler = GpuSampler()
        sampler.start()
        outcome, seconds = run_training(sys.executable, config, run_dir / f"probe_bs{batch_size}.log", 600, probe=True)
        sampler.stop.set()
        run["batch_attempts"].append({"batch_size": batch_size, "outcome": outcome, "seconds": round(seconds), "gpu_peak_mb": sampler.peak})
        print(f"batch {batch_size}: {outcome} (GPU peak {sampler.peak} MB)")
        if outcome == "fits":
            chosen = batch_size
            break
    if chosen is None:
        run["result"] = "no batch size fit"
        (run_dir / "run.json").write_text(json.dumps(run, ensure_ascii=False, indent=1), encoding="utf-8")
        raise SystemExit("No batch size fit; see probe logs.")

    config = make_config(args, run_dir, Path(data["data_dir"]), chosen)
    sampler = GpuSampler()
    sampler.start()
    outcome, seconds = run_training(sys.executable, config, run_dir / "train.log", args.minutes * 60, probe=False)
    sampler.stop.set()

    steps, evals = parse_log(run_dir / "train.log")
    if steps:
        keys = sorted({k for s in steps for k in s}, key=lambda k: list(steps[0]).index(k) if k in steps[0] else 99)
        with open(run_dir / "loss_curve.csv", "w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=keys)
            writer.writeheader()
            writer.writerows(steps)

    steps_per_epoch = -(-data["train_lines"] // chosen)
    ips = [s["ips"] for s in steps[2:]] or [s["ips"] for s in steps]
    mean_ips = sum(ips) / len(ips) if ips else None
    run.update({
        "batch_size": chosen,
        "config": str(config),
        "outcome": outcome,
        "trained_seconds": round(seconds),
        "steps": steps[-1]["step"] if steps else 0,
        "epochs_completed": (steps[-1]["epoch"] - 1) if steps else 0,
        "steps_per_epoch": steps_per_epoch,
        "mean_samples_per_second": round(mean_ips, 1) if mean_ips else None,
        "estimated_seconds_per_epoch": round(data["train_lines"] / mean_ips) if mean_ips else None,
        "peak_mem_reserved_mb": max((s["mem_reserved_mb"] or 0) for s in steps) if steps else None,
        "peak_mem_allocated_mb": max((s["mem_allocated_mb"] or 0) for s in steps) if steps else None,
        "gpu_peak_nvidia_smi_mb": sampler.peak,
        "validation": evals,
        "checkpoints": sorted(p.name for p in (run_dir / "model").glob("*.pdparams")) if (run_dir / "model").exists() else [],
        "finished": dt.datetime.now().isoformat(timespec="seconds"),
    })
    (run_dir / "run.json").write_text(json.dumps(run, ensure_ascii=False, indent=1), encoding="utf-8")
    print(json.dumps({k: run[k] for k in ("batch_size", "outcome", "trained_seconds", "steps", "epochs_completed",
                                          "mean_samples_per_second", "estimated_seconds_per_epoch",
                                          "peak_mem_reserved_mb", "peak_mem_allocated_mb", "gpu_peak_nvidia_smi_mb",
                                          "checkpoints")}, indent=1))
    print(f"\nRun folder: {run_dir}")


if __name__ == "__main__":
    main()
