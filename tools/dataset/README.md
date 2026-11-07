# Dataset intake and split (all training tracks)

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

Put the delivery (zips and/or folders) in `<root>\incoming\`, then:

```
python intake.py
```

The originals are never changed: zips are extracted and folders copied to
`<root>\intake\<run>\extracted\` (zip entries that would escape the
folder are refused), and only that copy is read. Report:
`<root>\intake\<run>\report.md` (+ `report.json`, `items.csv`).

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
python split_dataset.py --intake <root>\intake\<run>
```

- Groups: items with the same bytes, near-duplicates, the same task and
  target, or an ss/cap pair always land in the same split.
- Held-out eval (default 10% per topic) is drawn from groups with a
  labelled phone capture (`cap`) first; screenshots only when a topic has
  too few captures (noted in the report). Then validation (10%), then
  training. `eval` given in the labels CSV is kept.
- Leak guard against every existing eval set: the recognizer's
  `eval/real` and `eval/synthetic`, and every item any earlier split held
  out (`<root>\splits\frozen_eval.jsonl`, appended after each split).
  An item an earlier split held out goes to eval again. An item matching
  the recognizer's eval sets stops the split with nothing written, unless
  `--drop-eval-overlap` leaves it out. After assigning, an independent
  check confirms no train/val item has the bytes, a near-duplicate or the
  target of an eval item.

Output `<root>\splits\<id>\`: `images\`, `labels.csv`, `rec_{train,val,eval}.txt`
(one-line text items of kinds S/M/T in the recognizer's charset),
`formula_{train,val,eval}.txt` (LaTeX without delimiters),
`split_report.md`/`.json`.

## Dry run on a FAKE delivery (done 2026-11-07)

```
python make_fake_intake.py --out <scratch>\incoming --leak-from <root>\eval\synthetic
python intake.py --incoming <scratch>\incoming --work <scratch>\intake --registry <scratch>\splits\frozen_eval.jsonl
python split_dataset.py --intake <scratch>\intake\<run> --out <scratch>\splits --registry <scratch>\splits\frozen_eval.jsonl
```

The fake delivery (generated drawings marked FAKE; a zip and a folder;
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

Keeps algebra-level LaTeX only (allowed commands, at most 60 tokens, no
environments, sums, integrals, limits, accents or fonts, at least one of
= < > ^ \frac \sqrt f(x)); every dropped line is counted by reason. For
im2latex-100k (CC0); see `docs/training_runbook.md`. Not run on a real
dataset yet (none downloaded).

Tests: `python -m unittest discover -s tests -t .` (11, on a temporary
root, never the real one).
