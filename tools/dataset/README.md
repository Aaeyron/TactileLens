# Dataset tools

These tools get a new batch of photos ready **before** any training. They
check the photos, sort them, and split them into three groups:

- **Training:** photos the models learn from.
- **Validation:** photos used to pick the best version while training.
- **Test (held out):** photos kept aside to measure the final result.
  They are **never** used for training.

The same split is used for every model, so a photo kept aside for one
model is never used to train another.

Nothing here changes the app. Photos and labels stay in the training
folder (`C:\Projects\Capstone\tactilelens-training`) and never go into
git.

**Python:** `C:\Projects\Capstone\paddle_onnx_env`. Run the scripts from
this folder. Every script explains its options with `--help`.

## The usual steps

### 1. Check a new batch: `intake.py`

Put the new zips or folders in `datasets\own\incoming\` inside the
training folder, then run:

```
python intake.py
```

It works on a copy, so your original files are never changed. It writes a
report that lists:

- how many usable photos there are per topic
- badly named files, broken labels, and photos without labels
- exact and near-duplicate photos
- things a person should look at, such as names, phone numbers or
  location data inside a photo
- photos that are too close to ones already kept aside for testing

Nothing is deleted or fixed automatically.

### 2. Split the photos: `split_dataset.py`

```
python split_dataset.py --intake <the intake folder from step 1>
```

- About 10% of each topic is kept aside for testing (phone photos
  first), and 10% for validation. The rest is for training.
- Copies and near-copies of a photo always land in the same group, so a
  test photo can't sneak into training.
- If a photo matches one already used for testing, the split stops and
  writes nothing.

## Other tools

| Tool | What it's for |
|---|---|
| `algebra_filter.py`, `prepare_im2latex.py` | pick simple algebra formulas from a free public collection (im2latex-100k) |
| `im2latex_filter_report.py` | a plain report of how that collection was filtered |
| `make_synthetic_formulas.py` | draw extra practice formulas for training only (never for testing) |
| `finalize_labels.py` | lock in the reviewed labels for the test and validation photos |
| `crop_formulas.py` | cut each formula out of full-page photos, the same way the app does |
| `prepare_unlabeled.py`, `split_unlabeled.py` | prepare and split a batch that came without labels |
| `extend_unlabeled.py` | add a later batch without changing the photos already kept aside |
| `make_fake_intake.py` | make a small fake batch with planted problems, to test these tools |

## Tests

```
python -m unittest discover -s tests -t .
```

The tests use a temporary folder, never the real training folder.

More details and results: [docs/training_runbook.md](../../docs/training_runbook.md).
