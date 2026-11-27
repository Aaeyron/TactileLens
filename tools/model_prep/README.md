# Offline math model tools

These tools train and test the model that reads **math formulas on the
phone** (PaddleOCR's PP-FormulaNet_plus-S).

They never change the app by themselves. A new model only goes into the
app after it has been tested and shows fewer wrong formulas than the
current app.

**Python:**
- `C:\Projects\Capstone\paddle_formula_env` for training and exporting
- `C:\Projects\Capstone\paddle_onnx_env` for testing

Run the scripts from this folder. Every script explains its options with
`--help`.

## The usual steps

1. **Build a training list:** `build_crop_train.py` collects formula
   pictures from our own worksheets with the labels the online model gave
   them.
2. **Train:** `train_formula.py` trains a new version, keeps the best one,
   and turns it into a file the phone can use.
3. **Test:** `evaluate_formula.py` scores a model on a list of formulas,
   reading them the same way the app does.
4. **Compare:** `compare_formula.py` puts the old and new model side by
   side and lists every formula that got worse.

```
C:\Projects\Capstone\paddle_formula_env\Scripts\python train_formula.py --data <dataset folder> --name <short name>
C:\Projects\Capstone\paddle_onnx_env\Scripts\python evaluate_formula.py --labels <list.txt> --model <model.onnx> --tag <short name>
```

## All tools

| Tool | What it's for |
|---|---|
| `train_formula.py` | train a new version of the math model |
| `evaluate_formula.py` | score a model on a list of formulas |
| `compare_formula.py` | compare an old and a new model, formula by formula |
| `build_crop_train.py` | build the training list from formula pictures |
| `build_pseudo_labels.py` | build training lists when photos came without labels |
| `suggest_crop_labels.py` | let the current offline model read formula pictures |
| `filter_crop_labels.py` | drop pictures not worth training on (single symbols, repeats) |
| `export_formula.py` | turn a trained model into the file the phone uses |
| `compare_onnx.py`, `inspect_onnx.py` | look inside model files and compare them |
| `test_formulanet.py` | the app's way of reading a formula, copied for testing on the PC |
| `export_formula_vocab.py` | export the model's list of symbols for the app |
| `repeated_tokens.py` | count readings with repeated pieces, a common error |
| `formula_memory_trial.py` | check how much the graphics card can handle |
| `own_dataset_report.py`, `finetune_changes.py`, `charts.py` | reports and charts for the panel |

## Tests

```
python -m unittest test_compare_formula test_build_pseudo_labels test_build_crop_train test_filter_crop_labels test_finetune_changes test_own_dataset_report test_train_formula
```

Use `paddle_onnx_env`.

Results and decisions: [docs/training_runbook.md](../../docs/training_runbook.md).
