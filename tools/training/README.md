# Offline text model tools

These tools train and test the model that reads **lines of text on the
phone** (PaddleOCR's PP-OCRv6 small text model). They focus on lines with
raised characters, such as x², xⁿ and 10⁻³.

Nothing here changes the app. Photos and labels stay in the training
folder (`C:\Projects\Capstone\tactilelens-training`) and never go into
git.

**Python:** `C:\Projects\Capstone\paddle_onnx_env` (training uses
`C:\Projects\Capstone\paddle_train_env`). Run the scripts from this
folder. Every script explains its options with `--help`.

## The usual steps

1. **Make practice lines:** `generate_synthetic.py` draws made-up text
   lines with exponents, in many fonts, with a phone-photo look.
2. **Add real lines:** print the worksheets in `worksheets/`, photograph
   them, and run `pair_photos.py` to cut and label each line. Lines the
   tool isn't sure about are set aside for a person to check.
3. **Train:** `train_full.py` trains a new version and picks the best one
   using real photos only.
4. **Test:** `evaluate.py` and `compare_models.py` score models the same
   way the app reads text.

```
python generate_synthetic.py --set train --count 20000
python evaluate.py --set real-eval
python compare_models.py --set real-eval --b <new model.onnx> --b-name new
```

## Good to know

- **Test lines are kept apart.** Every script checks that no test line
  is ever used for training, and stops if it finds one.
- **Practice lines are made up.** They never copy text from textbooks or
  other people's worksheets. Don't photograph those either.
- `common.py` also defines where everything lives in the training folder,
  and the other tool folders use it too.

## Other tools

| Tool | What it's for |
|---|---|
| `cut_text_lines.py` | cut text lines out of our own page photos, like the app does |
| `text_sets.py`, `pick_text_test_images.py`, `finalize_text_eval.py` | choose and lock in the test and training lines |
| `score_epochs.py` | score each saved version during training |
| `compare_text.py` | compare an old and a new model, line by line |
| `verify_against_app.py` | check that the PC copy reads a page exactly like the phone |
| `worksheets.py` | make the printable practice worksheets |
| `topics.csv` | the list of topics and examples for the practice lines |

## Tests

```
python -m unittest discover -s tests -t .
```

Fonts and their licenses are listed in `resources/fonts/FONTS.md` inside
the training folder.

Results and decisions: [docs/training_runbook.md](../../docs/training_runbook.md).
