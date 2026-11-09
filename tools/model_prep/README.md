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
| `compare_formula.py` | before vs after on the same list: strict and spacing-normalized scores, items that got worse, the pass bar |
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

`--no-final-eval` runs a plumbing check without scoring the evaluation
list (it stays reserved for the real run). Scores and the adoption rule
for our own data: `docs/training_runbook.md` (Track A, and "Adoption rule
for our own data").

Tests: `python -m unittest test_compare_formula` (`paddle_onnx_env`).
