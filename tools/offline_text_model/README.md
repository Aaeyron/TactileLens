# Offline text model

These tools train and test the model that reads **lines of text on the
phone** (PaddleOCR's PP-OCRv6 small text model). They focus on lines with
raised characters, such as x², xⁿ and 10⁻³.

Nothing here changes the app. Photos and labels stay in the training
folder on the PC and never go into git.

## The usual steps

1. **Make practice lines** (`generate_synthetic.py`): made-up text lines
   with exponents, in many fonts, with a phone-photo look.
2. **Add real lines:** print the practice worksheets, photograph them, and
   let `pair_photos.py` cut and label each line. Lines it isn't sure about
   are set aside for a person to check.
3. **Train** (`train_full.py`): train a new version and pick the best one
   using real photos only.
4. **Test** (`evaluate.py`, `compare_models.py`): score models the same
   way the app reads text.

## Good to know

- **Test lines are kept apart.** Every tool checks that no test line is
  ever used for training, and stops if it finds one.
- **Practice lines are made up.** They never copy text from textbooks or
  other people's worksheets.
- `common.py` also defines where everything lives in the training folder;
  the other tool folders use it too.

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

Each tool explains its options with `--help`, and the folder has its own
automatic tests. Results and decisions:
[docs/training_runbook.md](../../docs/training_runbook.md).
