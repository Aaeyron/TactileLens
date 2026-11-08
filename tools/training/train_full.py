"""Full fine-tuning run of the offline text recognizer (PP-OCRv6 small rec):
train -> pick the best checkpoint on REAL validation -> export -> ONNX ->
compare with the app's model. Never touches the app.

Run with the training environment, from tools/training:
  C:\\Projects\\Capstone\\paddle_train_env\\Scripts\\python train_full.py --split <root>\\splits\\<id>

Defaults follow the plan: batch 64, at most 8 epochs, early stopping.

  1. Training lines: data/synthetic/train.txt, data/real/train.txt and the
     split's rec_train.txt. Validation (selects the checkpoint and stops
     early): REAL lines only, data/real/val.txt and the split's
     rec_val.txt; without any, it stops (a dry run may pass
     --allow-synthetic-val, and the result is marked so).
  2. Leak guard: the recognizer guard, then by bytes: no training or
     validation image may equal an image of eval/real, eval/synthetic, the
     split's rec_eval.txt or the frozen eval registry.
  3. Trains with the repo's PP-OCRv6_small_rec.yml (pretrained weights
     from the training root). Validation every --eval-every steps; the
     trainer keeps best_accuracy. Stops after --patience validations
     without a better accuracy, or after --epochs.
  4. Exports best_accuracy (tools/export_model.py), converts it to ONNX
     with PaddleX's paddle2onnx (paddle_onnx_env, opset 17, as the October
     trial), and checks the ONNX inputs/outputs against the app's model and
     the dictionary against the app's inference.yml.
  5. Runs evaluate.py (the app's preprocessing) with the app's model and
     the new one on every eval set that exists, and writes comparison.md.

Everything goes to <root>/outputs/full/<run>/ (run.json, train.log,
loss_curve.csv, model/, infer/, onnx/inference.onnx, comparison.md).
Replacing the app's model is a separate, manual step after review.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import os
import random
import shutil
import re
import subprocess
import sys
import time
from pathlib import Path

from common import (
    REC_CONFIG,
    REC_MODEL,
    Layout,
    check_no_eval_in_training,
    load_character_list,
    read_labels,
    root_dir,
    sha256_of,
)
from train_trial import CONFIG, PRETRAINED, GpuSampler, make_config, parse_log
from train_trial import PADDLEOCR as PADDLEOCR_ROOT

HERE = Path(__file__).resolve().parent
BEST_LINE = re.compile(r"best metric, acc: ")
ONNX_PYTHON = Path(r"C:\Projects\Capstone\paddle_onnx_env\Scripts\python.exe")
PADDLEX = ONNX_PYTHON.parent / "paddlex.exe"
# How running out of GPU memory shows up in the trainer log (seen 2026-11-08:
# cuDNN reports it as a failed allocation, not as "out of memory").
OOM_SIGNS = ("ResourceExhaustedError", "cudaErrorMemoryAllocation", "CUDA error(2)",
             "CUDNN_STATUS_ALLOC_FAILED", "ALLOCATION_FAILED")
METRIC = re.compile(r"cur metric, acc: ([\d.]+)")
MAX_EPOCHS = 8


def lines_of(label_file: Path, root: Path) -> list[tuple[str, str]]:
    """Label lines with image paths relative to the training root (or
    absolute when the file lives elsewhere)."""

    base = label_file.parent.resolve()
    rows = []
    for image, text in read_labels(label_file):
        path = (base / image).resolve()
        try:
            rows.append((path.relative_to(root.resolve()).as_posix(), text))
        except ValueError:
            rows.append((str(path), text))
    return rows


def eval_hashes(layout: Layout, split: Path | None) -> dict[str, str]:
    found = {}
    for name in ("synthetic-eval", "real-eval"):
        base = layout.set_dir(name)
        for image, _ in read_labels(layout.label_file(name)):
            if (base / image).exists():
                found[sha256_of(base / image)] = name
    if split and (split / "rec_eval.txt").exists():
        for image, _ in read_labels(split / "rec_eval.txt"):
            found[sha256_of(split / image)] = f"{split.name}/rec_eval"
    registry = layout.root / "splits" / "frozen_eval.jsonl"
    if registry.exists():
        for line in registry.read_text(encoding="utf-8").splitlines():
            if line.strip():
                found.setdefault(json.loads(line)["sha256"], "frozen eval registry")
    return found


def subset(rows: list, n: int | None, seed: int) -> list:
    if not n or n >= len(rows):
        return rows
    return random.Random(seed).sample(rows, n)


def train(python: str, config: Path, log_path: Path, patience: int, max_seconds: float | None) -> dict:
    """Runs the trainer; stops early after `patience` validations without
    a better accuracy. Returns outcome and the validation history."""

    env = dict(os.environ, PYTHONIOENCODING="utf-8", FLAGS_allocator_strategy="auto_growth")
    start, history, best, since_best, outcome = time.time(), [], -1.0, 0, None
    with open(log_path, "w", encoding="utf-8") as log:
        process = subprocess.Popen([python, "tools/train.py", "-c", str(config)], cwd=PADDLEOCR_ROOT,
                                   stdout=log, stderr=subprocess.STDOUT, env=env)
        seen = 0
        while process.poll() is None:
            time.sleep(5)
            text = log_path.read_text(encoding="utf-8", errors="replace")
            if any(sign in text for sign in OOM_SIGNS) or "out of memory" in text.lower():
                outcome = "oom"
                break
            metrics = [float(m) for m in METRIC.findall(text)]
            for acc in metrics[seen:]:
                history.append(acc)
                if acc > best:
                    best, since_best = acc, 0
                else:
                    since_best += 1
            seen = len(metrics)
            # The trainer prints "best metric" after each validation, once
            # best_accuracy is saved; only stop after that line.
            saved = len(BEST_LINE.findall(text)) >= seen
            if patience and since_best >= patience and saved:
                outcome = "early_stop"
                break
            if max_seconds and time.time() - start > max_seconds:
                outcome = "time_limit"
                break
        if process.poll() is None:
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], capture_output=True)
            process.wait()
        if outcome is None:
            outcome = "finished" if process.returncode == 0 else "error"
    return {"outcome": outcome, "seconds": round(time.time() - start), "validation_acc": history,
            "best_validation_acc": best if best >= 0 else None}


def fallback_sizes(requested: int, fallbacks: str) -> list[int]:
    """The requested batch, then each smaller fallback (default 48, 32)."""

    sizes = [requested] + [int(b) for b in fallbacks.split(",") if b.strip() and int(b) < requested]
    return list(dict.fromkeys(sizes))


def train_with_fallback(sizes: list[int], attempt) -> tuple[int, dict, list[dict]]:
    """Runs attempt(batch) for each size until one does not run out of GPU
    memory. Returns (batch used, its result, every attempt)."""

    attempts = []
    for batch_size in sizes:
        result = attempt(batch_size)
        attempts.append({"batch_size": batch_size, "outcome": result["outcome"]})
        if result["outcome"] != "oom":
            return batch_size, result, attempts
    raise SystemExit(f"Out of GPU memory at every batch size {sizes}; see train_bs*.log")


def run_logged(command: list[str], log_path: Path, cwd: Path | None = None, path_first: Path | None = None) -> int:
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    if path_first:
        env["PATH"] = str(path_first) + os.pathsep + env.get("PATH", "")
    with open(log_path, "w", encoding="utf-8") as log:
        return subprocess.run(command, cwd=cwd, stdout=log, stderr=subprocess.STDOUT, env=env).returncode


def check_onnx(new: Path, log_path: Path) -> dict:
    """Inputs/outputs of the new ONNX vs the app's (names, ranks, dtypes)."""

    script = (
        "import json,sys,onnx\n"
        "def io(p):\n"
        " m=onnx.load(p,load_external_data=False)\n"
        " f=lambda v:[v.name,[d.dim_param or d.dim_value for d in v.type.tensor_type.shape.dim],v.type.tensor_type.elem_type]\n"
        " return {'inputs':[f(v) for v in m.graph.input],'outputs':[f(v) for v in m.graph.output],'opset':[o.version for o in m.opset_import]}\n"
        "print(json.dumps({'app':io(sys.argv[1]),'new':io(sys.argv[2])}))\n"
    )
    result = subprocess.run([str(ONNX_PYTHON), "-c", script, str(REC_MODEL), str(new)], capture_output=True, text=True)
    log_path.write_text(result.stdout + result.stderr, encoding="utf-8")
    if result.returncode:
        return {"ok": False, "error": result.stderr[-500:]}
    shapes = json.loads(result.stdout)
    rank = lambda side, key: [(len(v[1]), v[2]) for v in shapes[side][key]]  # noqa: E731
    same = rank("app", "inputs") == rank("new", "inputs") and rank("app", "outputs") == rank("new", "outputs")
    return {"ok": same, **shapes}


def evaluate(args_list: list[str], log_path: Path) -> Path | None:
    run_logged([str(ONNX_PYTHON), str(HERE / "evaluate.py"), *args_list], log_path, cwd=HERE)
    text = log_path.read_text(encoding="utf-8", errors="replace")
    match = re.search(r"Written to (.+)", text)
    return Path(match.group(1).strip()) if match else None


def export_and_compare(run: dict, run_dir: Path, layout: Layout) -> None:
    """Export best_accuracy, convert to ONNX, check it, evaluate app vs new."""

    config = Path(run["config"])
    split = Path(run["split"]) if run.get("split") else None
    tag, run_id = run["args"]["tag"], run["run_id"]
    write = lambda: (run_dir / "run.json").write_text(json.dumps(run, ensure_ascii=False, indent=1), encoding="utf-8")  # noqa: E731

    best = run_dir / "model" / "best_accuracy.pdparams"
    if not best.exists():
        run["result"] = f"no best_accuracy checkpoint (training {run['training']['outcome']}); see train.log"
        write()
        raise SystemExit(run["result"])

    infer = run_dir / "infer"
    code = run_logged([sys.executable, "tools/export_model.py", "-c", str(config), "-o",
                       f"Global.pretrained_model={best.with_suffix('')}", f"Global.save_inference_dir={infer}"],
                      run_dir / "export.log", cwd=PADDLEOCR_ROOT)
    run["export"] = {"returncode": code, "files": sorted(p.name for p in infer.glob("*")) if infer.exists() else []}
    onnx_dir = run_dir / "onnx"
    # PaddleX looks for the paddle2onnx executable on PATH (shutil.which).
    code = run_logged([str(PADDLEX), "--paddle2onnx", "--paddle_model_dir", str(infer), "--onnx_model_dir",
                       str(onnx_dir), "--opset_version", "17"], run_dir / "paddle2onnx.log",
                      path_first=ONNX_PYTHON.parent)
    new_onnx = onnx_dir / "inference.onnx"
    run["onnx"] = {"returncode": code, "path": str(new_onnx), "exists": new_onnx.exists()}
    if not new_onnx.exists():
        write()
        raise SystemExit("ONNX conversion failed; see paddle2onnx.log")
    run["onnx"].update(check_onnx(new_onnx, run_dir / "onnx_check.json"))
    run["onnx"]["sha256"] = sha256_of(new_onnx)
    run["dictionary_matches_app"] = load_character_list(infer / "inference.yml") == load_character_list(REC_CONFIG)
    write()

    sets = []
    for name in ("synthetic-eval", "real-eval"):
        if read_labels(layout.label_file(name)):
            sets.append((name, ["--set", name]))
    if split and read_labels(split / "rec_eval.txt"):
        sets.append((f"{split.name}/rec_eval", ["--labels", str(split / "rec_eval.txt")]))
    comparison = []
    for name, selector in sets:
        safe = name.replace("/", "_")
        app = evaluate([*selector, "--tag", f"{tag}_{run_id}_app"], run_dir / f"eval_app_{safe}.log")
        new = evaluate([*selector, "--rec", str(new_onnx), "--rec-config", str(infer / "inference.yml"),
                        "--tag", f"{tag}_{run_id}_new"], run_dir / f"eval_new_{safe}.log")
        comparison.append((name, app, new))
    run["evaluation"] = [{"set": n, "app": str(a) if a else None, "new": str(b) if b else None} for n, a, b in comparison]

    lines = [f"# Recognizer {run['kind']}: {run_id}", "",
             f"- Training lines {run['train_lines']}, validation {run['val_lines']} ({run['validation']};"
             f" {run['val_lines_scored_per_validation']} scored per validation), batch {run.get('batch_size', run['args']['batch_size'])}"
             f"{' (after running out of memory at ' + ', '.join(str(a['batch_size']) for a in run.get('batch_attempts', [])[:-1]) + ')' if len(run.get('batch_attempts', [])) > 1 else ''},"
             f" at most {run['args']['epochs']} epochs, patience {run['args']['patience']}",
             f"- Training: {run['training']['outcome']} after {run['training']['seconds']} s,"
             f" best validation acc {run['training']['best_validation_acc']}",
             f"- ONNX inputs/outputs like the app's: {run['onnx'].get('ok')}; dictionary as the app's:"
             f" {run['dictionary_matches_app']}", ""]
    if run["kind"].startswith("DRY"):
        lines += ["**DRY RUN: plumbing check on a tiny subset; these numbers are not a result.**", ""]
    lines += ["| eval set | app exact % | new exact % | app CER % | new CER % |", "|---|---|---|---|---|"]
    for name, app, new in comparison:
        def all_row(folder):
            if not folder or not (folder / "results.csv").exists():
                return {}
            with open(folder / "results.csv", encoding="utf-8") as handle:
                rows = [r for r in csv.DictReader(line for line in handle if not line.startswith("#"))]
            return next((r for r in rows if r["group"] == "ALL"), {})
        a, b = all_row(app), all_row(new)
        lines.append(f"| {name} | {a.get('exact_pct', '-')} | {b.get('exact_pct', '-')} | {a.get('cer_pct', '-')}"
                     f" | {b.get('cer_pct', '-')} |")
    if not comparison:
        lines.append("| (no eval set with lines) | - | - | - | - |")
    (run_dir / "comparison.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    run["finished"] = dt.datetime.now().isoformat(timespec="seconds")
    write()
    print("\n".join(lines))
    print(f"\nRun folder: {run_dir}")



def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root")
    parser.add_argument("--split", help="a dataset split folder (tools/dataset/split_dataset.py)")
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--fallback-batch-sizes", default="48,32",
                        help="tried in order if the GPU runs out of memory (only those below --batch-size)")
    parser.add_argument("--epochs", type=int, default=MAX_EPOCHS, help=f"at most {MAX_EPOCHS}")
    parser.add_argument("--eval-every", type=int, help="validation every N steps (default: twice per epoch)")
    parser.add_argument("--eval-batch-size", type=int, default=8,
                        help="validation batch (small: on Windows the last validation batch is skipped)")
    parser.add_argument("--patience", type=int, default=3, help="validations without improvement before stopping")
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--warmup-epochs", type=float, default=0.5)
    parser.add_argument("--workers", type=int, default=2)
    # AMP off by default: with NumPy 2.4 in paddle_train_env, Paddle 3.2.1 crashes in
    # grad_scaler when it reports an inf/nan step (float() of a 1-element array).
    # The October trial (which worked) ran in full precision.
    parser.add_argument("--amp", action=argparse.BooleanOptionalAction, default=False)
    parser.add_argument("--max-minutes", type=float, help="safety limit for the whole training")
    parser.add_argument("--allow-synthetic-val", action="store_true",
                        help="DRY RUN ONLY: validate on synthetic lines when there is no real validation set")
    parser.add_argument("--subset-train", type=int, help="DRY RUN: use only N training lines")
    parser.add_argument("--subset-val", type=int, help="DRY RUN: use only N validation lines")
    parser.add_argument("--cpu", action="store_true", help="DRY RUN: train on the CPU (no GPU numbers)")
    parser.add_argument("--tag", default="full")
    parser.add_argument("--continue-run", help="a run folder whose training ended (or was interrupted): skip "
                                               "training and continue with export, ONNX and evaluation")
    args = parser.parse_args()

    if args.continue_run:
        run_dir = Path(args.continue_run)
        run = json.loads((run_dir / "run.json").read_text(encoding="utf-8"))
        if "training" not in run:  # interrupted before the summary was written
            log = (run_dir / "train.log").read_text(encoding="utf-8", errors="replace")
            history = [float(m) for m in METRIC.findall(log)]
            run["training"] = {"outcome": "interrupted; continued with --continue-run", "seconds": None,
                               "validation_acc": history, "best_validation_acc": max(history) if history else None}
        run["continued"] = dt.datetime.now().isoformat(timespec="seconds")
        export_and_compare(run, run_dir, Layout(root_dir(args.root)))
        return

    if args.epochs > MAX_EPOCHS:
        raise SystemExit(f"--epochs at most {MAX_EPOCHS} (the plan's limit)")
    layout = Layout(root_dir(args.root))
    root = layout.root
    split = Path(args.split).resolve() if args.split else None
    dry_run = bool(args.allow_synthetic_val or args.subset_train or args.subset_val or args.cpu)

    check_no_eval_in_training(layout)
    train_rows = []
    for name in ("synthetic-train", "real-train"):
        train_rows += lines_of(layout.label_file(name), root)
    real_val = lines_of(layout.label_file("real-val"), root)
    if split:
        train_rows += lines_of(split / "rec_train.txt", root)
        real_val += lines_of(split / "rec_val.txt", root)
    val_rows, val_kind = real_val, "real"
    if not val_rows:
        if not args.allow_synthetic_val:
            raise SystemExit("No REAL validation lines (data/real/val.txt or the split's rec_val.txt). "
                             "A full run must select checkpoints on real photos.")
        val_rows, val_kind = lines_of(layout.label_file("synthetic-val"), root), "synthetic (DRY RUN ONLY)"
    train_rows = subset(train_rows, args.subset_train, 1)
    val_rows = subset(val_rows, args.subset_val, 2)

    held_out = eval_hashes(layout, split)
    for image, _ in train_rows + val_rows:
        path = Path(image) if Path(image).is_absolute() else root / image
        source = held_out.get(sha256_of(path))
        if source:
            raise SystemExit(f"LEAK: {image} has the same bytes as an eval image ({source}). Nothing trained.")

    run_id = dt.datetime.now().strftime("%Y%m%d_%H%M%S") + ("_dryrun" if dry_run else "_full")
    run_dir = layout.outputs / args.tag / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    for name, rows in (("train_list.txt", train_rows), ("val_list.txt", val_rows)):
        with open(run_dir / name, "w", encoding="utf-8", newline="\n") as handle:
            handle.writelines(f"{image}\t{text}\n" for image, text in rows)

    # On Windows PaddleOCR's tools/program.py skips the LAST batch of every
    # validation (max_iter = len(loader) - 1). Validate in small batches so
    # few lines are lost, and refuse if too few would be scored.
    last = len(val_rows) % args.eval_batch_size or args.eval_batch_size
    scored = len(val_rows) - last if os.name == "nt" else len(val_rows)
    if scored < 0.8 * len(val_rows) or scored == 0:
        raise SystemExit(f"Only {scored} of {len(val_rows)} validation lines would be scored on Windows "
                         f"(the last batch of {args.eval_batch_size} is skipped). Add validation lines or "
                         "lower --eval-batch-size.")

    def build_config(batch_size: int) -> tuple[Path, int, int]:
        """config_bs<N>.yml for this batch size; (path, steps per epoch, eval every)."""

        import yaml  # noqa: E402

        steps = -(-len(train_rows) // batch_size)
        trial_args = argparse.Namespace(epochs=args.epochs, eval_every=args.eval_every or max(steps // 2, 1),
                                        amp=args.amp, lr=args.lr, warmup_epochs=args.warmup_epochs,
                                        workers=args.workers)
        path = make_config(trial_args, run_dir, root, batch_size)
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        data["Eval"]["loader"]["batch_size_per_card"] = args.eval_batch_size
        if args.cpu:
            data["Global"].update({"use_gpu": False, "use_amp": False})
        path.write_text(yaml.safe_dump(data, allow_unicode=True, sort_keys=False), encoding="utf-8")
        return path, steps, trial_args.eval_every

    sizes = fallback_sizes(args.batch_size, args.fallback_batch_sizes)
    config, steps_per_epoch, eval_every = build_config(sizes[0])

    import paddle  # noqa: E402  (training env only)

    run = {
        "run_id": run_id, "kind": "DRY RUN (not a result)" if dry_run else "full",
        "started": dt.datetime.now().isoformat(timespec="seconds"),
        "args": vars(args), "split": str(split) if split else None,
        "train_lines": len(train_rows), "val_lines": len(val_rows), "validation": val_kind,
        "steps_per_epoch": steps_per_epoch, "eval_every_steps": eval_every,
        "batch_sizes_to_try": sizes,
        "val_lines_scored_per_validation": scored, "eval_batch_size": args.eval_batch_size,
        "base_config": str(CONFIG), "config": str(config),
        "pretrained": {"path": str(PRETRAINED), "sha256": sha256_of(PRETRAINED)},
        "environment": {"python": sys.version.split()[0], "paddle": paddle.__version__, "cuda": paddle.version.cuda()},
        "leak_guard": f"passed ({len(held_out)} eval images checked by bytes)",
    }
    write = lambda: (run_dir / "run.json").write_text(json.dumps(run, ensure_ascii=False, indent=1), encoding="utf-8")  # noqa: E731
    write()

    def attempt(batch_size: int) -> dict:
        nonlocal config
        config, steps, every = build_config(batch_size)
        run.update({"config": str(config), "steps_per_epoch": steps, "eval_every_steps": every})
        if (run_dir / "model").exists():  # partial checkpoints of a failed attempt
            shutil.rmtree(run_dir / "model")
        sampler = GpuSampler()
        sampler.start()
        result = train(sys.executable, config, run_dir / f"train_bs{batch_size}.log", args.patience,
                       args.max_minutes * 60 if args.max_minutes else None)
        sampler.stop.set()
        result["gpu_peak_nvidia_smi_mb"] = sampler.peak or "not measured (nvidia-smi unavailable)"
        print(f"batch {batch_size}: {result['outcome']}")
        return result

    batch_size, run["training"], run["batch_attempts"] = train_with_fallback(sizes, attempt)
    run["batch_size"] = batch_size
    shutil.copyfile(run_dir / f"train_bs{batch_size}.log", run_dir / "train.log")
    steps, _ = parse_log(run_dir / "train.log")
    if steps:
        keys = list(dict.fromkeys(k for s in steps for k in s))
        with open(run_dir / "loss_curve.csv", "w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=keys)
            writer.writeheader()
            writer.writerows(steps)
        run["training"]["steps"] = steps[-1]["step"]
        run["training"]["peak_mem_reserved_mb"] = max((s["mem_reserved_mb"] or 0) for s in steps)
    write()

    export_and_compare(run, run_dir, layout)


if __name__ == "__main__":
    main()
