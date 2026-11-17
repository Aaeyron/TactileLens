"""One-time reorganisation of the training workspace (approved 2026-11-10).

  python reorganize_workspace.py --dry-run   # check every move, write the move list
  python reorganize_workspace.py --apply     # do it

Moves (renames on the same drive; nothing is deleted):
  - datasets to datasets/{public,own,synthetic}/..., models to models/,
    fonts to resources/, notes to reports/, colab_upload to colab/upload;
  - every training run to runs/<date>-<time>_<track>_<data>_<purpose>/,
    with its evaluations next to it, then sorted inside by
    common.tidy_run (config/ logs/ charts/ best_checkpoint/ checkpoints/
    onnx/ evaluation/);
  - evaluations not tied to a run to evaluations/<track>/.
Then path strings in JSON / Markdown / list files are rewritten to the new
places (logs stay as written), a README goes into every top-level folder,
and old folders are removed only if they are empty.
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import Layout, rewrite_paths, root_dir, tidy_run  # noqa: E402

DATA = [
    ("data/public/im2latex-100k", "datasets/public/im2latex-100k/raw"),
    ("data/public/im2latex_algebra_lf", "datasets/public/im2latex-100k/filtered_general_algebra"),
    ("data/public/formula_demo", "datasets/public/paddleocr_formula_demo"),
    ("data/synthetic/formula_pilot_20261109", "datasets/synthetic/formulas_pilot_20261109"),
    ("data/synthetic/images", "datasets/synthetic/text_lines/train_val/images"),
    ("data/synthetic/train.txt", "datasets/synthetic/text_lines/train_val/train.txt"),
    ("data/synthetic/val.txt", "datasets/synthetic/text_lines/train_val/val.txt"),
    ("eval/synthetic", "datasets/synthetic/text_lines/eval"),
    ("manifests", "datasets/synthetic/text_lines/manifests"),
    ("worksheets", "datasets/synthetic/worksheets"),
    ("data/real", "datasets/own/text_lines/train_val"),
    ("eval/real", "datasets/own/text_lines/eval"),
    ("review", "datasets/own/photo_pairs_review"),
    ("pretrained", "models/pretrained"),
    ("fonts", "resources/fonts"),
    ("notes", "reports/notes"),
    ("colab_upload", "colab/upload"),
]

RUNS = [  # old run folder -> runs/<name>
    ("outputs/trials/20261025_163031_trial", "20261025-163031_trackB_synthetic-lines_trial"),
    ("outputs/trials/20261025_163509_trial", "20261025-163509_trackB_synthetic-lines_trial"),
    ("outputs/dryrun/20261107_144926_dryrun", "20261107-144926_trackB_fake-split_dryrun-cpu"),
    ("outputs/dryrun/20261107_145150_dryrun", "20261107-145150_trackB_fake-split_dryrun-cpu"),
    ("outputs/dryrun/20261107_150314_dryrun", "20261107-150314_trackB_fake-split_dryrun-cpu"),
    ("outputs/dryrun/20261107_224849_dryrun", "20261107-224849_trackB_fake-split_dryrun-cpu"),
    ("outputs/dryrun/20261107_235343_dryrun", "20261107-235343_trackB_fake-split_dryrun-gpu"),
    ("outputs/dryrun/20261107_235841_dryrun", "20261107-235841_trackB_fake-split_dryrun-gpu"),
    ("outputs/dryrun/20261108_075118_dryrun", "20261108-075118_trackB_fake-split_dryrun-gpu"),
    ("outputs/dryrun/20261108_081812_dryrun", "20261108-081812_trackB_fake-split_dryrun-oom-fallback"),
    ("outputs/formula_trial/20261108_153130", "20261108-153130_trackA_paddleocr-demo_memory-trial"),
    ("outputs/formula_trial/20261108_161345", "20261108-161345_trackA_paddleocr-demo_memory-trial"),
    ("outputs/formula_verify", "20261108-083302_trackA_official-checkpoint_onnx-verification"),
    ("outputs/formula_runs/20261109_111643_check", "20261109-111643_trackA_im2latex_check-validation-crashed"),
    ("outputs/formula_runs/20261109_112129_check", "20261109-112129_trackA_im2latex_check-crlf-labels-invalid"),
    ("outputs/formula_runs/20261109_132355_check_lf_cpu", "20261109-132355_trackA_im2latex_check-cpu-crashed"),
    ("outputs/formula_runs/20261109_133324_check_lf_cpu", "20261109-133324_trackA_im2latex_check-cpu"),
    ("outputs/formula_runs/20261109_163905_prelim", "20261109-163905_trackA_im2latex_prelim"),
    ("outputs/formula_runs/20261109_234813_check_mix", "20261109-234813_trackA_im2latex+synthetic_check"),
    ("outputs/formula_runs/20261109_235227_followup_synth", "20261109-235227_trackA_im2latex+synthetic_followup"),
    ("vl_dryrun", "20261026-101624_trackC_fake-data_dryrun"),
]
NOT_SORTED = {"20261108-083302_trackA_official-checkpoint_onnx-verification",
              "20261026-101624_trackC_fake-data_dryrun"}  # not training runs: kept as they were

EVAL_INTO_RUN = [  # evaluation folders of a run's models -> runs/<name>/evaluation/<sub>
    ("outputs/trial_20261025_163509", "20261025-163509_trackB_synthetic-lines_trial", "new"),
    ("outputs/dryrun_20261107_224849_dryrun_app", "20261107-224849_trackB_fake-split_dryrun-cpu", "app"),
    ("outputs/dryrun_20261107_224849_dryrun_new", "20261107-224849_trackB_fake-split_dryrun-cpu", "new"),
    ("outputs/dryrun_20261107_235841_dryrun_app", "20261107-235841_trackB_fake-split_dryrun-gpu", "app"),
    ("outputs/dryrun_20261107_235841_dryrun_new", "20261107-235841_trackB_fake-split_dryrun-gpu", "new"),
    ("outputs/dryrun_20261108_081812_dryrun_app", "20261108-081812_trackB_fake-split_dryrun-oom-fallback", "app"),
    ("outputs/dryrun_20261108_081812_dryrun_new", "20261108-081812_trackB_fake-split_dryrun-oom-fallback", "new"),
    ("outputs/formula/run_20261109_112129_check", "20261109-112129_trackA_im2latex_check-crlf-labels-invalid", "new"),
    ("outputs/formula/run_20261109_133324_check_lf_cpu", "20261109-133324_trackA_im2latex_check-cpu", "new"),
    ("outputs/formula/run_20261109_163905_prelim", "20261109-163905_trackA_im2latex_prelim", "new"),
    ("outputs/formula/run_20261109_235227_followup_synth", "20261109-235227_trackA_im2latex+synthetic_followup", "new"),
]

EVALUATIONS = [
    ("outputs/baseline", "evaluations/trackB_recognizer/baseline"),
    ("outputs/official_onnx", "evaluations/trackB_recognizer/official_onnx"),
    ("outputs/compare", "evaluations/trackB_recognizer/compare"),
    ("outputs/formula/app", "evaluations/trackA_formula/app"),
    ("outputs/vl_eval", "evaluations/trackC_vl"),
]

EMPTY_AFTER = ["outputs/dryrun", "outputs/trials", "outputs/formula_trial", "outputs/formula_runs", "outputs/formula",
               "outputs", "data/public", "data/synthetic", "data", "eval"]

READMES = {
    "README.md": """# TactileLens training workspace

Data, models and results for training the app's recognition models. Never
in git. The code is in the TactileLens repository (`tools/`), and the
runbook is `docs/training_runbook.md` there.

| folder | what is in it |
|---|---|
| `datasets/` | all data: public, our own, synthetic (see its README) |
| `models/pretrained/` | official checkpoints and models we start from |
| `runs/` | one folder per training run, named `<date>-<time>_<track>_<data>_<purpose>` |
| `evaluations/` | model scores that are not part of a run (baselines, comparisons) |
| `reports/` | write-ups, the im2latex filtering report and panel page, notes |
| `resources/fonts/` | open fonts used to draw synthetic data (licences in FONTS.md) |
| `colab/upload/` | files prepared for Google Drive / Colab (Track C) |

Tracks: **A** = on-device formula model (PP-FormulaNet_plus-S),
**B** = on-device text-line recognizer (PP-OCRv6 small rec),
**C** = PaddleOCR-VL (online engine).

Reorganised on 2026-11-10 (`tools/training/reorganize_workspace.py`); the
move list is `reports/workspace_move_list_20261110.md`. Logs inside runs
keep the paths that were current when they were written.
""",
    "datasets/README.md": """# Datasets

- `public/im2latex-100k/raw/`: im2latex-100k as published (CC0-1.0), three Parquet files.
- `public/im2latex-100k/filtered_general_algebra/`: im2latex-100k filtered to
  expressions using general-algebra notation; the source formulas come from
  physics papers (not a worksheet algebra set). `train.txt`, `val.txt`,
  `test.txt`, `images/`, `report.md`.
- `public/paddleocr_formula_demo/`: PaddleOCR's formula demo set (used for the memory trial).
- `own/incoming/`: put a new delivery of our dataset here.
- `own/intake/`: intake reports (`tools/dataset/intake.py`).
- `own/splits/`: train/val/eval splits (`tools/dataset/split_dataset.py`) and
  `frozen_eval.jsonl`, the frozen eval registry (created by the first split;
  items in it are never trained on).
- `own/text_lines/`: Track B real photo lines (`train_val/`, `eval/`).
- `own/photo_pairs_review/`: photo crops that could not be paired confidently.
- `synthetic/text_lines/`: Track B synthetic lines (`train_val/`, `eval/`, `manifests/`).
- `synthetic/worksheets/`: printable worksheets with their known lines.
- `synthetic/formulas_pilot_20261109/`: Track A synthetic formulas, training only.
""",
    "models/README.md": """# Models

`pretrained/`: what training starts from, as downloaded.

- `pretrained/formula/`: PP-FormulaNet_plus-S training checkpoint and official inference model (Track A).
- `pretrained/PP-OCRv6_small_rec_*`: the text-line recognizer checkpoint and ONNX (Track B).
- `pretrained/official_onnx/`: the official recognizer converted to ONNX.

Trained models are inside each run: `runs/<run>/best_checkpoint/` and `runs/<run>/onnx/`.
""",
    "runs/README.md": """# Training runs

One folder per run: `<date>-<time>_<track>_<data>_<purpose>` (track A =
formula model, B = text-line recognizer, C = PaddleOCR-VL).

Inside a run:

| item | what |
|---|---|
| `summary.md` | read this first: settings, outcome, scores |
| `run.json` | everything the run recorded |
| `config/` | the training configs and the exact train/val lists |
| `logs/` | raw logs (paths in them are those of the day they were written) |
| `charts/` | loss and validation charts and their data |
| `best_checkpoint/` | the checkpoint chosen on validation |
| `checkpoints/` | other checkpoints, only where they were kept |
| `onnx/` | the exported model (`paddle_static/` = Paddle inference model) |
| `evaluation/` | scores of the app's model and the new one, and the comparison |

`dryrun`, `check` and `trial` runs test the tools; their numbers are not
results. Two folders are kept as they were written (not training runs):
the Track A ONNX verification and the Track C fake-data dry run.
""",
    "evaluations/README.md": """# Evaluations not tied to a training run

- `trackA_formula/app/`: the app's formula model on our evaluation lists.
- `trackB_recognizer/`: recognizer baselines (`baseline/`, `official_onnx/`) and model comparisons (`compare/`).
- `trackC_vl/`: PaddleOCR-VL evaluations (`evaluate_vl.py`).

Scores of a run's own models are in `runs/<run>/evaluation/`.
""",
    "reports/README.md": """# Reports

- `im2latex_filter/`: the filtering report for im2latex-100k (filtered to
  general-algebra notation; formulas from physics papers) with charts,
  examples and the panel page `im2latex_filter_report.html`.
- `notes/`: working notes.
- `workspace_move_list_20261110.md`: what moved where on 2026-11-10.
""",
}


def plan(root: Path) -> list[tuple[str, str, str]]:
    moves = [("data", a, b) for a, b in DATA] + [("run", a, f"runs/{n}") for a, n in RUNS]
    for old, run, who in EVAL_INTO_RUN:
        src = root / old
        for child in sorted(src.iterdir()) if src.exists() else []:
            moves.append(("run evaluation", f"{old}/{child.name}", f"runs/{run}/evaluation/{who}_{child.name}"))
    moves += [("evaluation", a, b) for a, b in EVALUATIONS]
    return moves


def check(root: Path, moves) -> list[str]:
    problems, targets = [], set()
    for _, a, b in moves:
        if not (root / a).exists():
            problems.append(f"missing source: {a}")
        if (root / b).exists():
            problems.append(f"destination exists: {b}")
        if b in targets:
            problems.append(f"two moves to: {b}")
        targets.add(b)
    return problems


def size(path: Path) -> int:
    return path.stat().st_size if path.is_file() else sum(p.stat().st_size for p in path.rglob("*") if p.is_file())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--dry-run", action="store_true")
    group.add_argument("--apply", action="store_true")
    parser.add_argument("--root")
    args = parser.parse_args()

    root = root_dir(args.root)
    moves = plan(root)
    problems = check(root, moves)
    lines = ["# Workspace move list (2026-11-10)", "", f"Root: `{root}`. Renames only; nothing is deleted.", "",
             "| kind | from | to | size |", "|---|---|---|---|"]
    for kind, a, b in moves:
        lines.append(f"| {kind} | `{a}` | `{b}` | {size(root / a) / 1e6:,.1f} MB |" if (root / a).exists()
                     else f"| {kind} | `{a}` | `{b}` | missing |")
    lines += ["", "Inside each training run (not the two kept as written: "
              + ", ".join(sorted(NOT_SORTED)) + "), files are then sorted by `common.tidy_run`: "
              "`*.log` -> `logs/`, configs and train/val lists -> `config/`, charts -> `charts/`, `best_accuracy.*` -> "
              "`best_checkpoint/`, other checkpoints -> `checkpoints/`, ONNX and the static export -> `onnx/`, `eval/` -> "
              "`evaluation/`. Path strings in JSON / Markdown / list files are rewritten; logs are not.", "",
              f"New, empty: `datasets/own/incoming/`, `datasets/own/intake/`, `datasets/own/splits/`. "
              f"Removed if empty afterwards: {', '.join(f'`{e}`' for e in EMPTY_AFTER)}.", ""]
    if problems:
        lines += ["## Problems (nothing was moved)", ""] + [f"- {p}" for p in problems]
    text = "\n".join(lines) + "\n"
    if args.dry_run or problems:
        print(text)
        if problems:
            raise SystemExit("problems found; nothing moved")
        return

    layout = Layout(root)
    done = []
    for kind, a, b in moves:
        (root / b).parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(root / a), str(root / b))
        done.append((root / a, root / b))
        print(f"moved {a} -> {b}")
    for path in (layout.incoming, layout.intake, layout.splits):
        path.mkdir(parents=True, exist_ok=True)
    sorted_runs = 0
    for _, name in RUNS:
        if name not in NOT_SORTED:
            tidy_run(root / "runs" / name)
            sorted_runs += 1
    changed = sum(rewrite_paths(root / top, done) for top in ("runs", "evaluations", "datasets", "reports"))
    for rel in EMPTY_AFTER:
        path = root / rel
        if path.exists() and path.is_dir() and not any(path.iterdir()):
            path.rmdir()
    for rel, body in READMES.items():
        target = root / rel
        if target.exists():
            print(f"kept existing {rel}")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        with open(target, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(body)
    with open(layout.reports / "workspace_move_list_20261110.md", "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
    left = sorted(p.name for p in root.iterdir())
    print(f"\n{len(done)} moves, {sorted_runs} runs sorted, path strings rewritten in {changed} files.")
    print("Top level now:", ", ".join(left))


if __name__ == "__main__":
    main()
