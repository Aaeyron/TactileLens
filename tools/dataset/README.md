# Datasets: intake, splits, public and synthetic data (all tracks)

The first two steps when a dataset arrives, before any training. One
audit and one split feed all three tracks, so an item held out for one
model is never trained on by another:

- Track B, offline text recognizer: `rec_*.txt` -> `tools/training/train_full.py`
- Track A, offline formula model (PP-FormulaNet_plus-S): `formula_*.txt`
- Track C, PaddleOCR-VL: `labels.csv` -> `tools/training_vl/convert_to_sft.py`

Nothing here changes the app. Data stays under the training root
(`C:\Projects\Capstone\tactilelens-training`, `--root` or `TL_TRAIN_ROOT`),
never in git. Python: any of our environments with Pillow
(`C:\Projects\Capstone\paddle_onnx_env`). Run from this folder.

## 1. Audit: `intake.py`

Put the delivery (zips and/or folders) in `<root>\datasets\own\incoming\`, then:

```
python intake.py
```

The originals are never changed: zips are extracted and folders copied to
`<root>\datasets\own\intake\<run>\extracted\` (zip entries that would escape the
folder are refused), and only that copy is read. Report:
`<root>\datasets\own\intake\<run>\report.md` (+ `report.json`, `items.csv`).

| check | result |
|---|---|
| counts | usable items per topic x source (`ss`/`cap`) x kind (`S`/`M`/`T`/`W`), per task |
| names | `topic_source_kind_number.ext` (`../training_vl/config.json`) -> error |
| labels | every `*.csv` with `filename,task,target[,split]`; LaTeX braces, `\left`/`\right`, `\begin`/`\end`; OTSL tokens and even rows -> error; text not in the offline recognizer's charset -> warning (kept for VL, left out of `rec_*.txt`) |
| images | unreadable or tiny, image without label, label without image, two labels that disagree -> error |
| duplicates | same bytes (sha256); near-duplicates (256-bit difference hash, at most 12 bits apart, similar shape); ss/cap pairs of one item (same task + target, or same topic/kind/number) -> warning, kept together by the split |
| flags | GPS or comment/artist/copyright in EXIF; email, phone, "Name:", "Section:", "LRN:", "Mr./Ms. ..."; copyright, ISBN, publisher names, page numbers; the forbidden textbook page 04 sample -> a person checks |
| eval | same bytes or near-duplicate of an image already in an eval set -> flag |

Errors keep an item out of the split. Flagged items are also left out
until a person has checked them (then `--allow-flagged`). Nothing is
deleted or fixed automatically.

## 2. Split: `split_dataset.py`

```
python split_dataset.py --intake <root>\datasets\own\intake\<run>
```

- Groups: items with the same bytes, near-duplicates, the same task and
  target, or an ss/cap pair always land in the same split.
- Held-out eval (default 10% per topic) is drawn from groups with a
  labelled phone capture (`cap`) first; screenshots only when a topic has
  too few captures (noted in the report). Then validation (10%), then
  training. `eval` given in the labels CSV is kept.
- Leak guard against every existing eval set: the recognizer's
  `datasets/own/text_lines/eval` and `datasets/synthetic/text_lines/eval`, and every item any earlier split held
  out (`<root>\datasets\own\splits\frozen_eval.jsonl`, appended after each split).
  An item an earlier split held out goes to eval again. An item matching
  the recognizer's eval sets stops the split with nothing written, unless
  `--drop-eval-overlap` leaves it out. After assigning, an independent
  check confirms no train/val item has the bytes, a near-duplicate or the
  target of an eval item.

Output `<root>\datasets\own\splits\<id>\`: `images\`, `labels.csv`, `rec_{train,val,eval}.txt`
(one-line text items of kinds S/M/T in the recognizer's charset),
`formula_{train,val,eval}.txt` (LaTeX without delimiters),
`split_report.md`/`.json`.

## Dry run on a FAKE delivery (done 2026-11-07)

```
python make_fake_intake.py --out <scratch>\incoming --leak-from <root>\datasets\synthetic\text_lines\eval
python intake.py --incoming <scratch>\incoming --work <scratch>\intake --registry <scratch>\splits\frozen_eval.jsonl
python split_dataset.py --intake <scratch>\intake\<run> --out <scratch>\splits --registry <scratch>\splits\frozen_eval.jsonl
```

The fake delivery (generated drawings marked FAKE, each labelled exactly as
drawn except the one planted broken label; a zip and a folder;
51 images, 51 label rows) has planted problems. Result:

- 48 usable, 4 errors: the broken label (`\sqrt{x+9=5`), the bad name
  `IMG_2041.jpg`, an image without a label, a label without an image.
- Flags: the leak (same bytes as an image in `synthetic-eval`), and the
  photo with GPS in EXIF and "Name: ... Section: ...".
- Warnings: the exact copy, the re-saved JPEG near-duplicate (5 bits;
  different formulas were 21+ bits apart), the ss/cap pair, the
  off-charset `ˣ`.
- The split stopped on the leak with nothing written. With
  `--drop-eval-overlap`: 46 items, train 37 / val 4 / eval 5, all eval
  items phone captures, the pair and the duplicates in one split. A
  second split with another seed kept the same 5 items in eval.
- `convert_to_sft.py` converted that split (37 / 4 / 5 records).

Not measured: the near-duplicate threshold on real photos (check the
near-duplicate list of the first real intake), and the flags' false
positives on real worksheets.

## Public formulas for a preliminary run: `algebra_filter.py`

```
python algebra_filter.py --labels public_labels.tsv --out kept.tsv --report report.md
```

Keeps expressions using general-algebra notation only (allowed commands, at most 60 tokens, no
environments, sums, integrals, limits, accents or fonts, at least one of
= < > ^ \frac \sqrt f(x)); every dropped line is counted by reason.

For im2latex-100k (CC0), `prepare_im2latex.py` does it all in one step
(`paddle_formula_env`, needs `pyarrow`; run with `python -I`):

```
python -I prepare_im2latex.py --src <folder with the .parquet files> --out <new folder>
```

It applies the filter, gives each formula one topic (a heuristic on the
LaTeX; rules in the script and the report), drops train/val formulas
whose image or LaTeX is also in test (and train ones also in val), and
writes `images/<topic>_pub_i2l-<split>_<n>.png`, `train.txt`, `val.txt`,
`test.txt` and `report.md`. Result on 2026-11-09: 945 / 104 / 120 kept
of 55,033 / 6,072 / 6,810; per topic in `docs/training_runbook.md`.
Label lists are written with LF line ends (PaddleOCR leaves "\r" in the
label otherwise).

Filtering report for the panel (reads only):

```
python -I im2latex_filter_report.py --src <parquet folder> --subset <prepare_im2latex.py output> --out <new folder>
```

Writes `report.md` (source, licence, rules in plain words, formulas left
after each rule per split, per topic, the leak-guard duplicates, kept and
rejected examples with the reason, limits, and counts for looser filter
variants), the example images, two example sheets and three charts
(`chart_funnel.png`, `chart_topics.png`, `chart_looser.png`). Charts are
drawn with Pillow (`tools/model_prep/charts.py`).

## Synthetic formulas for Track A (training only): `make_synthetic_formulas.py`

```
python make_synthetic_formulas.py --out <new folder> --per-topic 300 --workers 8 --seed 2026
```

`paddle_formula_env` (matplotlib, Pillow, OpenCV). Worksheet-level
formulas from templates for the 8 topics, rendered with matplotlib's
mathtext in 10 font styles, on Track B paper, with phone-photo effects in
formula-safe ranges; labels in im2latex's spaced style, exactly what is
drawn. Writes `images/<topic>_syn_<n>.png`, `train.txt` (no val or test:
synthetic data is never used to evaluate), `manifest.jsonl` and
`report.md`. Leak guard against im2latex val/test and the frozen eval
registry. Pilot on 2026-11-10: 2,400 images in 47 s; details in
`docs/training_runbook.md` (Track A).

Tests: `python -m unittest discover -s tests -t .` (19, on a temporary
root, never the real one).

## A delivery without labels: `prepare_unlabeled.py`, `split_unlabeled.py`

The 2026-11-18 delivery of our own images came without label files. After
`intake.py`:

1. `prepare_unlabeled.py --intake <intake run> --out <root>/datasets/own/working/<id>`
   copies the intake's extracted images (never `incoming/`) to `images/`,
   fixes topic spellings (`TOPIC_FIXES`), gives "(1)" names a free number,
   keeps one image per group of byte-identical files and lists every change
   in `mapping.csv`; `items.csv` lists the kept images.
2. `split_unlabeled.py --working <working dir> --intake <intake run>` chooses
   eval / validation / training from the kind S images, before any model
   reading is looked at. Eval: per topic, groups that contain a phone
   capture; an ss/cap pair is one group. A copy left out as a duplicate
   follows the name that was kept, so its pair is not lost.
   `--check split.csv` only checks that an existing split keeps every pair
   on one side (exit 1 if not).

Note: all topics draw from one seeded random sequence, so a change in one
topic's groups changes the draw of every later topic. Keep a split once it
is used; check it with `--check` rather than regenerating it.

## A later delivery on top: `intake.py --dedupe`, `extend_unlabeled.py`

When the full delivery came as several zips that repeat each other (one
per topic, plus overlapping parts of an earlier download):

1. `intake.py --dedupe` hashes every file in every zip first and extracts
   one file per distinct content (the alphabetically first name). Every
   copy is listed in `<run>/same_bytes.csv`, and the report still counts
   them as exact duplicates. Without this, the same name in two zips is an
   error ("2 images with this name") and the item is never hashed.
2. `extend_unlabeled.py --old <working> --intake <run> --out <new working>`
   hard-links the old images (same names) and the new ones into a new
   folder and extends split.csv: old sides never change (the eval set stays
   frozen), new images go to validation (per-topic seed) or training, and
   new images that are near-duplicates of an eval image, or numbered like
   one, are left out.

Finding (2026-11-18 delivery): ss and cap images with the same topic, kind
and number were NOT the same formula in any of the 20 pairs checked by eye.
Number-pairing is kept only as a cautious rule; the label check (no
training label equal to an eval or validation label) is the guard that
matters.
