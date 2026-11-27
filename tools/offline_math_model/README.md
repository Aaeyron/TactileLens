# Offline math model

These tools train and test the model that reads **math formulas on the
phone** (PaddleOCR's PP-FormulaNet_plus-S).

They never change the app by themselves. A new model only goes into the
app after it has been tested and shows fewer wrong formulas than the
current app.

## The usual steps

1. **Build a training list** (`build_crop_train.py`): formula pictures
   from our own worksheets, labeled by the online model.
2. **Train** (`train_formula.py`): train a new version, keep the best
   one, and turn it into a file the phone can use.
3. **Test** (`evaluate_formula.py`): score a model on a list of formulas,
   reading them the same way the app does.
4. **Compare** (`compare_formula.py`): put the old and new model side by
   side and list every formula that got worse.

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

Each tool explains its options with `--help`, and the folder has its own
automatic tests. Results and decisions:
[docs/training_runbook.md](../../docs/training_runbook.md).
