# Track A: on-device formula model (PP-FormulaNet_plus-S), plus ONNX checks

Tools for the app's on-device formula recognizer (PP-FormulaNet_plus-S,
`frontend/android/.../paddle_onnx/PP-FormulaNet_plus-S/`): verify the ONNX,
fine-tune it, export it again and compare it with the app's model. The
app is never changed by these tools; swapping a model in is a separate,
reviewed step (and Braille output goes to the Braille expert first).

Environments: `C:\Projects\Capstone\paddle_formula_env` (training, export,
charts) and `C:\Projects\Capstone\paddle_onnx_env` (ONNX Runtime
scoring). Workspace paths come from `tools/training/common.py` (`Layout`);
the workspace is `C:\Projects\Capstone\tactilelens-training` (see its
README).

| script | what it does |
|---|---|
| `train_formula.py` | fine-tune from the official checkpoint, early stopping on validation, export, score the app's and the new ONNX on the evaluation list, compare; writes `runs/<date>-<time>_trackA_<data>_<name>/` and sorts it at the end |
| `evaluate_formula.py` | score one ONNX on a formula list with the app's preprocessing: exact match and edit distance, per topic and per formula length |
| `compare_formula.py` | before vs after on the same list: applies the adoption rule for our own data (notation-normalized exact match higher; at most 1 simple-formula regression per 100, minimum 1), lists every regression sorted into spacing only / same meaning, different notation / meaning-changing (reported separately); spacing-normalized and strict scores alongside; `--meta labels.csv` adds reviewed topics, source and label-source groups |
| `build_pseudo_labels.py` | training lists from an unlabeled delivery: version 1 (offline model and PaddleOCR-VL agree), version 2 (plus PaddleOCR-VL's reading on disagreements that pass basic checks), the synthetic list, and a leak guard against eval and validation |
| `own_dataset_report.py` | the panel section for our own dataset, from saved results only; also measures how close labels and model are to PaddleOCR-VL and looks for near-duplicates. Example images are left out of the page |
| `finetune_changes.py` | what changed during fine-tuning, read-only: per-layer weight change grouped by module (`weights`), per-token confidence of both checkpoints on the validation list (`confidence`), then error types, a before/after gallery from the saved test predictions, charts and an HTML section that `--page` puts into a page (`report`) |
| `suggest_crop_labels.py` | offline-model readings of formula crops (`--engine paddle` gives per-symbol confidence; resumable) |
| `filter_crop_labels.py` | crop filter (several lines, words, trivial, near-duplicates, held-out labels) and the PaddleOCR-VL order |
| `build_crop_train.py` | crop training list: PaddleOCR-VL labels first, offline-only above `--threshold` up to `--offline-share`; `--analyse` prints the threshold table |
| `repeated_tokens.py` | count readings with repeated tokens (fracfrac, `^^`, extra `{{`/`}}`/`\\`) per model |
| `export_formula.py` | checkpoint -> Paddle inference model -> ONNX (works around `masked_fill` for paddle2onnx) |
| `compare_onnx.py` | two ONNX files: inputs/outputs, operators, weights, token ids on the same images |
| `formula_memory_trial.py` | which batch size fits the 6 GB GPU (reserved memory, speed) |
| `charts.py` | slide charts with Pillow (loss, validation history, bar charts) |
| `test_formulanet.py` | the app's preprocessing and decoding, ported from PaddleX (used by the evaluator) |
| `export_formula_vocab.py` | export the tokenizer vocabulary for Android and check the decode |
| `inspect_onnx.py` | print an ONNX model's inputs, outputs and operators |

Typical use (from this folder):

```
C:\Projects\Capstone\paddle_formula_env\Scripts\python train_formula.py --data <dataset folder> --name <purpose> [--extra-train <synthetic folder> --extra-ratio 0.394]
C:\Projects\Capstone\paddle_onnx_env\Scripts\python evaluate_formula.py --labels <list.txt> [--model <onnx>] --tag <tag>
```

`--extra-train-2 <folder> --extra-ratio-2 <share>` adds a second extra training
list, and `--max-minutes <n>` stops after the first finished validation past
that time, keeping the best checkpoint. `--min-free-gb <n>` stops when the
disk has less free space (before the first validation at once, otherwise once
the last validation's checkpoint is saved). Without these options a run is set
up exactly as before.

`--no-final-eval` runs a plumbing check without scoring the evaluation
list (it stays reserved for the real run). Scores and the adoption rule
for our own data: `docs/training_runbook.md` (Track A, and "Adoption rule
for our own data").

Tests: `python -m unittest test_compare_formula test_build_pseudo_labels test_finetune_changes test_own_dataset_report test_train_formula` (`paddle_onnx_env`).
