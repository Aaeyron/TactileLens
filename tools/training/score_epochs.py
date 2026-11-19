"""Track B checkpoint rule: export end-of-epoch checkpoints and score them on validation sets.

From tools/training (paddle_train_env):
  python score_epochs.py --run <run folder> --epochs 1 2 --val own=<val.txt> --val synthetic=<val.txt>

For each epoch N: checkpoints/iter_epoch_N -> candidates/epoch_N/{infer,onnx} (tools/export_model.py,
PaddleX paddle2onnx, opset 17). Then evaluate.py on every --val set for the original app model and each
epoch: candidates/scores/<model>_<set>/. Eval sets are never scored here. Apply the rule with
compare_text.py (own set) and the results.csv ALL row (guard set); the 2026-11-20 rule is in
docs/training_runbook.md.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

from train_full import HERE, ONNX_PYTHON, PADDLEOCR_ROOT, PADDLEX


def run(command: list, log: Path, **kwargs) -> int:
    with open(log, "w", encoding="utf-8") as handle:
        code = subprocess.run([str(c) for c in command], stdout=handle, stderr=subprocess.STDOUT, **kwargs).returncode
    print(f"{log.name} -> {code}", flush=True)
    return code


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--run", required=True)
    parser.add_argument("--epochs", type=int, nargs="+", required=True)
    parser.add_argument("--val", action="append", required=True, help="name=label file (validation only)")
    args = parser.parse_args()
    run_dir = Path(args.run)
    config = run_dir / "config" / "config_bs64.yml"
    out = run_dir / "candidates"
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    onnx_env = dict(env, PATH=str(ONNX_PYTHON.parent) + os.pathsep + env.get("PATH", ""))
    sets = dict(v.split("=", 1) for v in args.val)

    models: dict[str, tuple[Path, Path] | None] = {"original": None}
    for n in args.epochs:
        folder = out / f"epoch_{n}"
        folder.mkdir(parents=True, exist_ok=True)
        infer, onnx_dir = folder / "infer", folder / "onnx"
        if not (onnx_dir / "inference.onnx").exists():
            run([sys.executable, "tools/export_model.py", "-c", config, "-o",
                 f"Global.pretrained_model={run_dir / 'checkpoints' / f'iter_epoch_{n}'}",
                 f"Global.save_inference_dir={infer}"], folder / "export.log", cwd=PADDLEOCR_ROOT, env=env)
            run([PADDLEX, "--paddle2onnx", "--paddle_model_dir", infer, "--onnx_model_dir", onnx_dir,
                 "--opset_version", "17"], folder / "paddle2onnx.log", env=onnx_env)
        models[f"epoch_{n}"] = (onnx_dir / "inference.onnx", infer / "inference.yml")

    (out / "scores").mkdir(parents=True, exist_ok=True)
    for name, model in models.items():
        for set_name, labels in sets.items():
            target = out / "scores" / f"{name}_{set_name}"
            if target.exists() and any(target.rglob("predictions.tsv")):
                continue
            command = [ONNX_PYTHON, HERE / "evaluate.py", "--labels", labels, "--tag", f"{name}_{set_name}",
                       "--out", target]
            if model:
                command += ["--rec", model[0], "--rec-config", model[1]]
            run(command, out / "scores" / f"{name}_{set_name}.log", cwd=HERE, env=env)


if __name__ == "__main__":
    main()
