# Offline recognizer: training groundwork

Tools to build data for, and measure, the offline text recognizer
(PP-OCRv6 small rec, `frontend/android/app/src/main/assets/paddle_onnx/PP-OCRv6-small-rec-onnx/`)
on lines with raised characters (x², xⁿ, 10⁻³, ...). Nothing here changes
the app. Data never goes into git.

Python: `C:\Projects\Capstone\paddle_onnx_env` (onnxruntime, opencv,
numpy, Pillow, PyYAML). Run the scripts from this folder.

## Where things are

Scripts (this folder): `common.py` (paths, charset, guard), `app_ocr.py`
(the app's detector + recognizer, ported), `textgen.py` (topic templates),
`render.py` (drawing + photo look), `generate_synthetic.py`, `evaluate.py`,
`worksheets.py`, `pair_photos.py`, `verify_against_app.py`, `topics.csv`.

Data root (default `C:\Projects\Capstone\tactilelens-training`, or
`--root`, or `TL_TRAIN_ROOT`). ASCII names and relative paths only, so it
can be copied to Google Drive / Colab as is.

```
fonts/                    open fonts + licences (FONTS.md)
data/synthetic/images/    train.txt  val.txt
data/real/images/         train.txt
eval/synthetic/images/    labels.txt        held out
eval/real/images/         labels.txt        held out, NEVER used for training
worksheets/               W001.pdf/.png/.json ...
review/<sheet>/           crops that need a human (review.tsv)
manifests/<set>.jsonl     one row per image
outputs/<tag>/<date>_<model sha8>_<set>/   results.md results.csv predictions.tsv
```

## Formats

Label files (PaddleOCR recognizer format): `images/<file><TAB><text>`,
UTF-8, one line per image, paths relative to the label file's folder.
Superscripts are written as Unicode characters.

Manifest rows: `id, path, label, source (synthetic|real), set, topic,
subcase, fixed_case, font, style (typeset|glyph), ...` plus the drawing
and augmentation choices (synthetic) or the sheet, photo, reading and
similarity (real).

The guard (`common.check_no_eval_in_training`) runs in every script that
writes or reads data: it stops if an eval image, or a worksheet used for
eval, also appears in a training list.

## Charset

The recognizer's dictionary (`inference.yml`, parsed like the app's
`ModelConfig.kt`, 18,709 entries with the trailing space) has
⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹ ⁺ ⁻ ⁼ ⁽ ⁾ ⁿ and − √ ∛ ≤ ≥ ≠ ± × ÷ ·, but no other
letter superscripts (no ⁱ ˣ ʸ ᵃ ...). Labels use only these; the
dictionary is not changed.

## Topics

`topics.csv` lists topics × sub-cases with an example and target counts.
Fill it in and extend it. A new row whose sub-case has no template in
`textgen.py` is generated from its `example` as written (raised
characters as Unicode superscripts).

## Synthetic lines

```
python generate_synthetic.py --set eval  --count 200     # seed 20261025
python generate_synthetic.py --set train --count 20000   # seed 1
python generate_synthetic.py --set val   --count 1000    # seed 2
```

Lines are generated text only (templates + random letters and numbers),
never textbook or worksheet text. The eval set holds the seven fixed cases
× 10 renderings, template lines and about 20% controls without
superscripts.

Two looks (`--profile`):
- `v1` (eval, frozen): the original fonts and photo effects. Regenerating
  the eval set gives the same files byte for byte.
- `v2` (train/val, default): more faces, worksheet surroundings (lined,
  grid, coloured paper, page edges, table borders, answer rules, slivers
  of neighbouring lines, item labels such as "3." or "b)"), stronger photo
  effects, and every minus drawn as a hyphen "-" or a true minus "−" (more
  often "−" in math-typesetting faces), labelled as drawn. Controls
  include hyphenated words, ranges and dates. At least 25% of train/val
  lines have no superscript (`--min-plain`).

## Baseline / comparing models

```
python evaluate.py --set synthetic-eval
python evaluate.py --set real-eval
python evaluate.py --set real-eval --rec C:\path\new_rec.onnx --tag retrained
```

Preprocessing and decoding are the app's (see `app_ocr.py`).

Side by side (exact and exponent exact for ALL, controls, negative
exponents, each topic and each photographed sheet):

```
python compare_models.py --set real-eval --b C:\path\trained.onnx --b-name trained
```

## Real photos

Targets per topic (see `topics.csv`): about 10 held-out (eval) and 20
training lines. The starter sheets do that:

- Eval: W001-W010 (16 lines each, including the seven fixed cases).
- Training: W101-W113 (16 lines each, template lines only).

1. Print `worksheets/Wxxx.pdf` on A4 at 100% (no "fit to page").
2. Photograph each sheet with your phone, the whole page in view, roughly
   flat, normal room light. Eval sheets: one photo each. Training sheets:
   1-3 photos each in different light, angle or distance.
3. Copy the photos to the PC, named `<sheet>_<anything>.jpg`, for
   example `W001_a.jpg`, `W103_window.jpg`.
4. Cut and label the lines:
   ```
   python pair_photos.py --sheet W001 C:\photos\W001_a.jpg
   ```
   Lines that match their known text clearly go to `eval/real` (eval
   sheets) or `data/real` (training sheets). The rest go to
   `review/<sheet>/` with `review.tsv` (crop, what was read, best guess,
   similarity): check them by hand; they are never added automatically.
5. Real validation (to pick checkpoints during training, never eval):
   pair the photos of a few training sheets (W111-W113) with `--val`.
   They go to `data/real/val.txt`, never into training or eval.

Do not photograph textbook pages or worksheets made by others.

## Checking the port against the phone

```
python verify_against_app.py C:\...\W001.png app_log.txt
```

See the script's help: scan a PNG page on the phone (On-device, picked
from the gallery, no selection box), save `adb logcat -d -s
TactileLensPipeline`, and compare. "VERIFIED" means every line's text is
identical and the boxes are within 2 px.

## Fonts

See `<root>/fonts/FONTS.md`: DejaVu (Bitstream Vera + public domain),
STIX (SIL OFL 1.1), Liberation (SIL OFL 1.1), TeX Gyre and Latin Modern
(GUST Font License), each with its licence file.
