# Training runbook: the first three days after the dataset arrives

Status 2026-11-07: tools ready and dry-run on FAKE data; **nothing has been
trained on real data and there are no training results.** Everything
marked "not measured" is not measured.

Three tracks share one intake and one split (`tools/dataset/`), so an item
held out for one model is never trained on by another:

| track | model | where it runs | tools |
|---|---|---|---|
| B | offline text recognizer, PP-OCRv6 small rec | laptop GPU (RTX 4050 6 GB) | `tools/training/train_full.py` |
| A | offline formula model, PP-FormulaNet_plus-S | laptop GPU, after a memory trial | official PaddleOCR config; `tools/model_prep/evaluate_formula.py` |
| C | PaddleOCR-VL, partial fine-tuning (LoRA) | free Colab (experimental) or laptop via WSL2 (memory test first) | `tools/training_vl/colab_lora_sft.ipynb`, `convert_to_sft.py`, `evaluate_vl.py` |

The app is not changed by any of this. Data stays in
`C:\Projects\Capstone\tactilelens-training` (never in git). Swapping a
model into the app is a separate, reviewed step, and any change that
affects Braille output goes to the Braille expert first.

## Training workspace (layout of 2026-11-10)

`C:\Projects\Capstone\tactilelens-training` (never in git; a README in
each top-level folder):

| folder | what |
|---|---|
| `datasets\public\im2latex-100k\raw\`, `\filtered_general_algebra\` | im2latex-100k as published, and filtered to general-algebra notation (formulas from physics papers) |
| `datasets\public\paddleocr_formula_demo\` | PaddleOCR's formula demo set |
| `datasets\own\incoming\`, `intake\`, `splits\` | our dataset: delivery, intake reports, splits and the frozen eval registry `splits\frozen_eval.jsonl` |
| `datasets\own\text_lines\`, `photo_pairs_review\` | Track B real photo lines |
| `datasets\synthetic\text_lines\`, `worksheets\`, `formulas_pilot_20261109\` | synthetic data (training only) |
| `models\pretrained\` | official checkpoints and models |
| `runs\<date>-<time>_<track>_<data>_<purpose>\` | one training run: `summary.md`, `run.json`, `config\`, `logs\`, `charts\`, `best_checkpoint\`, `checkpoints\` (others, where kept), `onnx\`, `evaluation\` |
| `evaluations\trackA_formula\`, `trackB_recognizer\`, `trackC_vl\` | scores not tied to a run |
| `reports\` | im2latex filtering report and panel page, notes, the move list |
| `resources\fonts\`, `colab\upload\` | fonts; files for Google Drive / Colab |

All tools take these paths from `Layout` in `tools/training/common.py`.
`train_formula.py`, `train_full.py` and `formula_memory_trial.py` sort a
finished run with `common.tidy_run`.

Reorganisation (2026-11-10, approved): `tools/training/reorganize_workspace.py`;
the move list (54 renames, nothing deleted) is
`reports\workspace_move_list_20261110.md`. 19 earlier training runs were
sorted the same way; the Track A ONNX verification and the Track C
fake-data dry run were kept as written. Path strings in run JSON /
Markdown / list files were rewritten to the new places (logs keep the
paths of the day). Remaining references to paths that no longer exist
were checked one by one: weights deleted earlier with your approval
(CRLF subset, three ONNX files, check-run checkpoints), checkpoint names
written without extension (the files exist), and the old `data` root in
the two October trials (its contents are now split across `datasets\`).
After the move: all tool tests pass (dataset 19, recognizer and layout
12, VL 15, formula comparison 10), and a short Track A check run on the
new layout (`runs\20261110-011959_trackA_im2latex+synthetic_layout-check`;
40 + 48 items, 22 steps, export to ONNX, test split not scored) wrote and
sorted its run folder correctly.

## Adoption rule for our own data (decided 2026-11-10, before any run on it)

Written down before any model is trained or scored on our own dataset,
so the rule cannot be fitted to the results.

- **Applies to** every model that outputs LaTeX formulas and could
  replace the app's: Track A (PP-FormulaNet_plus-S) and the formula
  blocks of Track C. Track B (text lines) keeps its own rule (Day 3).
- **Evaluation set:** the frozen eval registry of our own data
  (`datasets\own\splits\frozen_eval.jsonl`), mainly phone captures (`cap`). The
  registry is created by the first split of our data
  (`split_dataset.py`, Day 1) and only ever grows; its items are never
  trained on or used to choose settings or checkpoints.
- **Main metric:** spacing-normalized exact match on that set (the rule
  in Track A: LaTeX spacing commands, whitespace and math delimiters
  ignored, nothing else). Reported overall, per topic and per source
  (ss / cap), with counts.
- **Simple formulas must not get worse:** no simple formula (at most 20
  LaTeX tokens) that the app's current model reads correctly on the
  spacing-normalized score may become wrong with the new model (0
  allowed).
- **A model is proposed for the app only if** its spacing-normalized
  exact match on the frozen eval set is higher than the app's model,
  **and** no simple formula got worse. The **strict** score is always
  reported next to it and never replaces it. Then the Braille check
  (Day 3) before any change to the app.
- Checkpoints and settings are chosen on validation only; the frozen eval
  set is scored once per candidate model.

## Day 1: intake, split, baselines

**You**

1. Copy the delivery (zips and/or folders) into
   `C:\Projects\Capstone\tactilelens-training\datasets\own\incoming\`. Keep the originals
   elsewhere too; the tools never change them.
2. Read `datasets\own\intake\<run>\report.md` when I send it, and check every flagged
   item (personal data, third-party pages, items already in an eval set).
   Tell me which flagged items may be used.
3. Upload to Google Drive (for Track C):
   `MyDrive/tactilelens/tools/training_vl/` (5 files, about 0.1 MB:
   `convert_to_sft.py`, `vl_common.py`, `config.json`, `evaluate_vl.py`,
   `local_vl_worker.py`) and `MyDrive/tactilelens/data/<split id>.zip`.

**Me**

1. `python tools\dataset\intake.py` and send you the report (counts per
   topic x source x kind, errors, flags, duplicates).
2. After your answers: `python tools\dataset\split_dataset.py --intake ...`
   (add `--allow-flagged` only for items you cleared). Held-out eval comes
   mainly from labelled phone captures; this first split **creates the
   frozen eval registry** (`datasets\own\splits\frozen_eval.jsonl`), which keeps them
   out of training for good (see "Adoption rule for our own data").
3. Zip `datasets\own\splits\<id>\images` + `labels.csv` for Drive and tell you its size.
4. Baselines of today's models on the held-out eval (nothing trained yet):
   - recognizer: `tools\training\evaluate.py --labels datasets\own\splits\<id>\rec_eval.txt`
   - formula: `tools\model_prep\evaluate_formula.py --labels datasets\own\splits\<id>\formula_eval.txt`
   - VL: `tools\training_vl\evaluate_vl.py --eval datasets\own\splits\<id>\sft --engine local`
     (PaddleOCR-VL-1.6 on the laptop; stop the AI service first)

## Day 2: training

**Track B (laptop).** I start it (or you, with the same command):

```
cd C:\Projects\Capstone\TactileLens\tools\training
C:\Projects\Capstone\paddle_train_env\Scripts\python train_full.py --split C:\Projects\Capstone\tactilelens-training\datasets\own\splits\<id>
```

Batch 64, at most 8 epochs, validation on REAL lines only (the split's
`rec_val.txt` and `datasets\own\text_lines\train_val\val.txt`; it stops if there are none),
early stopping after 3 validations without a better accuracy, then export,
ONNX (PaddleX paddle2onnx, opset 17), a check of the ONNX inputs/outputs
and dictionary against the app's, and `evaluate.py` with the app's model
and the new one on every eval set. Output and `comparison.md`:
`runs\<date>-<time>_trackB_<data>_full\`. Full precision (AMP crashes in this environment,
see "Known issues").

Measured so far (synthetic lines only, not a result):
- GPU dry run 2026-11-08, batch 64, 2,048 lines, 40 steps: finished in
  195 s including two validations; peak 5,858 MB reserved (trainer) /
  5,908 MB (nvidia-smi) on the 6 GB card, so batch 64 fits **with
  almost no headroom**. If a run runs out of memory, `train_full.py`
  retries automatically at 48, then 32 (`--fallback-batch-sizes`), each
  attempt with its own log (`train_bs<N>.log`) and listed in `run.json`.
  Tested by asking for batch 256: it ran out of memory and the run
  continued at 64.
- October trial, batch 96: 38.3 lines/s, about 157 s per epoch of 6,000
  lines.
- Estimate (not measured): about 12,000 synthetic + the dataset's lines
  at about 35 lines/s is about 6 minutes per epoch, so at most about an
  hour for 8 epochs with validations; early stopping usually ends sooner.

**Track A (laptop)**: memory trial done (batch 5 fits, 4 is safe; see
Track A); a short real run when the data is ready.

**Track C.** You open `colab_lora_sft.ipynb` in Colab, choose a GPU
runtime and run the cells. On the free T4 cell 1 stops unless you set
`EXPERIMENTAL_T4 = True` (a 20-step fp16 test, undocumented). Checkpoints
are written to Drive and the notebook resumes after a timeout. In
parallel, or instead, the laptop memory test in WSL2 (below), after your
approval.

## Day 3: evaluation and decision

**Me**: evaluate every new model on the same held-out eval as day 1 and
write one comparison (app model vs new, per topic, per source ss/cap).
Only measured numbers. Formula models: the "Adoption rule for our own
data" above decides (spacing-normalized exact match on the frozen eval
set, no simple formula worse, strict reported alongside). Track B: a
model is proposed only if it beats the current one on the held-out phone
captures. Either way, only after its Braille output is checked.

**You**: download `runs/<run id>/` from Drive if Track C produced a merged
model (about 1.8 GiB; only if it beat the base model), and decide.

## Google Drive (free 15 GB)

| what | size |
|---|---|
| `tools/training_vl/` | about 0.1 MB |
| `data/<split id>.zip` (images + labels.csv) | depends on the delivery: about (number of images) x (average file size); e.g. 1,000 phone photos at 2 MB = about 2 GB. Not measured. |
| `cache/PaddleOCR-VL/` (base 0.9B, downloaded by the notebook once) | 2.00 GiB (Hugging Face listing) |
| `runs/<run id>/checkpoints/` (LoRA, 3 kept) | not measured |
| `runs/<run id>/merged/` | about 1.8 GiB (`model.safetensors` of the base) |

## Track A: formula model (PP-FormulaNet_plus-S)

- **Official training support: yes.** PaddleOCR documents training,
  evaluation and export (`docs/version3.x/module_usage/formula_recognition.en.md`,
  section 4) with the config in our checkout:
  `PaddleOCR-official/configs/rec/PP-FormuaNet/PP-FormulaNet_plus-S.yaml`
  (folder name spelled so upstream). Input 384 x 384, 1 channel
  (`d2s_train_image_shape: [1,384,384]`), `max_new_tokens: 1024`, AdamW
  lr 1e-4, batch 14 per card in the example.
- **Checkpoint:** `PP-FormulaNet_plus-S_pretrained.pdparams` (official
  "Training Model" link in that doc; 256,890,832 bytes = 244 MiB). The
  app's ONNX (`pp-formulanet_plus-s.onnx`, sha256 `449d205c...`) is the
  same file as `models\PP-FormulaNet_plus-S\pp-formulanet_plus-s.onnx`;
  it is **verified** to be this model (weights and outputs; "Done" 3
  below).
- **Vocabulary: matches.** The trainer's tokenizer
  (`ppocr/utils/dict/unimernet_tokenizer/tokenizer.json`) and the one the
  app's `pp-formulanet_vocab.json` was exported from have the same 50,000
  entries, merges and added tokens (checked 2026-11-07; the files differ
  only in JSON formatting).
- **Preprocessing:** training eval uses `UniMERNetImgDecode` +
  `UniMERNetTestTransform` + `LatexImageFormat`, the transforms the app's
  port follows (`tools/model_prep/test_formulanet.py`: crop margin, fit
  384, black padding, gray, mean 0.7931 / std 0.1738).
- **Dependencies** (from the doc and the code): `tokenizers==0.19.1`
  (2,168 KiB wheel), `ftfy` (44 KiB), `imagesize` (9 KiB), `Wand`
  (140 KiB) + the ImageMagick program. `paddle_train_env` has none of them.
  Wand is only used by the "Snow" augmentation
  (`ppocr/data/imaug/unimernet_aug.py`); on Windows without ImageMagick a
  training run would fail when Snow is drawn. A memory trial can run
  without the training augmentation; a real run needs ImageMagick or WSL2.

**Done (2026-11-08, after approval)**

1. **Environment:** `C:\Projects\Capstone\paddle_formula_env`, a copy of
   `paddle_train_env` (3.65 GB, Paddle 3.2.1, NumPy 2.4.1), plus
   `tokenizers` 0.19.1, `ftfy` 6.3.1, `imagesize` 2.0.1, `Wand` 0.7.2 and
   the dependencies pip added for them (`huggingface_hub` 0.36.2,
   `wcwidth`, `fsspec`, `filelock`). No ImageMagick: `import wand.image`
   fails, and the Snow augmentation is skipped (returns the image
   unchanged); the other augmentations run. `paddle_train_env` is
   unchanged. Use `python -m pip` in the copy (its `pip.exe` points to the
   old folder).
2. **Downloads** (sizes equal to the servers'): in
   `tactilelens-training\models\pretrained\formula\`
   `PP-FormulaNet_plus-S_pretrained.pdparams` (256,890,832 bytes, sha256
   `a8a72053...`) and `PP-FormulaNet_plus-S_infer.tar` (259,604,480,
   `31e8659f...`); the demo set `ocr_rec_latexocr_dataset_example.tar`
   (25,108,480, `6ed9bd71...`; 10,000 train / 500 val arXiv-style formulas)
   in `datasets\public\paddleocr_formula_demo\`.
3. **The app's ONNX is this model** (`tools/model_prep/compare_onnx.py`):
   - official inference model -> `paddlex --paddle2onnx` vs the app's
     ONNX: all 836 weight tensors (57,916,120 values) identical, same 1,160
     operators including the decoding `Loop`, same inputs/outputs
     (`x` [N,1,384,384] -> token ids), opset 18, identical token ids on
     20 of 20 demo images. The files differ only in ONNX `ir_version`
     (10 vs 8, a different converter release).
   - **training checkpoint -> our export -> ONNX** vs the app's ONNX:
     832 of 836 weight tensors identical (the other 4 hold one value each),
     same inputs/outputs, opset 18, the `Loop` present, 22 fewer graph
     nodes, and **identical token ids on 50 of 50 demo images**. So a
     model trained from this checkpoint can be exported to an ONNX the app
     can load (running it on the phone: not verified).
   - Needed for that: `tools/model_prep/export_formula.py`. Paddle 3.2.1
     records `masked_fill_` as its own operator, which paddle2onnx 2.0.2rc3
     cannot convert ("unsupported operators"); during export only it is
     written as `where(mask, full_like(x, value), x)` (the official model
     has `where` + `full_like` there), then PaddleOCR's
     `tools/export_model.py` runs unchanged.
4. **Memory trial on the RTX 4050** (`tools/model_prep/formula_memory_trial.py`;
   demo set, 30 steps per batch, fp32, Snow skipped, from the official
   checkpoint; `runs\20261108-161345_trackA_paddleocr-demo_memory-trial\`):

   | batch | result | trainer max_mem_reserved | nvidia-smi peak | s/step | samples/s |
   |---|---|---|---|---|---|
   | 8 | runs only by spilling into system memory | 6,805 MB | 5,909 MB | 0.532 | 17.4 |
   | 6 | runs only by spilling into system memory | 6,361 MB | 5,877 MB | 0.309 | 21.1 |
   | **5** | **fits** | **5,703 MB** | 5,837 MB | **0.215** | **23.6** |
   | 4 | fits | 3,722 MB | 3,863 MB | 0.194 | 20.7 |

   The card has 6,141 MB. **Largest batch that fits: 5** (fastest, but
   close to the limit); batch 4 leaves about 2 GB free. On Windows the
   driver lets larger batches run by spilling into system memory: an
   earlier pass reported batch 14 "running" with 11,860 MB reserved at
   2.55 s/step (6.1 samples/s), so the trial now counts a batch as
   fitting only if the reserved memory is within the card. Reserved
   memory varied between the two passes (batch 8: 9,099 vs 6,805 MB).
   The demo set's formulas are long arXiv formulas (median 118 characters,
   longest 1,351); algebra-level formulas are shorter and should need less
   memory (not measured).

**Preliminary run on im2latex (2026-11-09)**: `tools/model_prep/train_formula.py`
trains from the official checkpoint (batch 4, shuffled, lr and warmup set
explicitly because the config's warmup is 5,000 steps, validation on
`val.txt` each epoch, early stopping), exports `best_accuracy` with
`export_formula.py`, scores the app's ONNX and the new ONNX on
`test.txt` with `evaluate_formula.py` (the app's preprocessing, CPU, 4
threads; per topic and per formula length) and compares them with
`compare_formula.py` (per group, plus the items that were exact before
and not after, simple ones first).

Short end-to-end checks (40 train / 16 val items, 10 steps, then export
and the comparison on all 120 test formulas). **Plumbing checks, not
results:**

| run | where | outcome | notes |
|---|---|---|---|
| `20261109_111643_check` | GPU | validation crashed | `cal_metric_during_train=False` makes PaddleOCR validate formula models on the wrong path; now `True` as in the config |
| `20261109_112129_check` | GPU | finished, exported, compared; 10 steps in 80 s, 2,317 MB reserved | **invalid:** the label files had CRLF line ends, so every label ended in `\r` (val exp_rate 0.0); fixed |
| `20261109_133324_check_lf_cpu` | CPU (GPU unavailable, see Known issues) | finished, exported, compared; 10 steps in 240 s (10.3 s/step) | val exp_rate 0.25 (4 of 16); test: app 48.3% exact, after 10 steps 48.3%; simple formulas 54.2% both, none got worse |

App model on the im2latex algebra test split (120 formulas, exact after
removing spaces and delimiters): **48.3% overall**; exponents 82.4%,
fractions 38.9%, linear_equations 53.3%, radicals 41.7%,
quadratic_equations 62.5%, inequalities 20.0%; simple (at most 20
tokens) 54.2%. Many misses are notation variants the strict comparison
counts as wrong (`\left(` vs `(`, `'` vs `\prime`, `\le` vs `\leq`).

**Preliminary run `20261109_163905_prelim` (2026-11-09, approved; a
first experiment on public data, not a model for the app):**

- Settings: 945 train / 104 val formulas, batch 4, lr 2e-5, warmup 100,
  up to 20 epochs, seed 1024 (PaddleOCR's `Global.seed`; augmentation and
  GPU kernels can still make two runs differ), fp32, Snow skipped.
- Speed (measured): 0.13-0.17 s/step, about 1 minute per epoch with
  validation and saving; 2,479 MB reserved (2,613 MB nvidia-smi peak) of
  6,141 MB. Epoch 4 ran at 0.8-0.9 s/step for about 3 minutes, then
  returned to normal; cause not found (the charger was connected around
  then). Whole run: 9 minutes of training plus about 5 minutes for export
  and the two test scorings.
- Validation (PaddleOCR's exact match, 104 formulas): original 41
  (39.4%); after epochs 1-7: 49, 50, 51, **53**, 53, 50, 46. Early
  stopping after epoch 7 (no higher score than epoch 4 for 3 epochs).
  Exported checkpoint: epoch 5 (PaddleOCR keeps the later of two equal
  scores). Charts: `loss_curve.png`, `validation_history.png` in the run
  folder.
- **Test split (120 formulas, the app's preprocessing, our strict
  comparison):**

  | group | items | original | fine-tuned | got worse | got better |
  |---|---|---|---|---|---|
  | all | 120 | 48.3% (58) | 50.8% (61) | 11 | 14 |
  | exponents | 17 | 82.4% (14) | 88.2% (15) | 1 | 2 |
  | fractions | 54 | 38.9% (21) | 38.9% (21) | 6 | 6 |
  | function_notation | 3 | 100% (3) | 66.7% (2) | 1 | 0 |
  | inequalities | 10 | 20.0% (2) | 30.0% (3) | 1 | 2 |
  | linear_equations | 15 | 53.3% (8) | 46.7% (7) | 2 | 1 |
  | polynomials | 1 | 0% (0) | 100% (1) | 0 | 1 |
  | quadratic_equations | 8 | 62.5% (5) | 75.0% (6) | 0 | 1 |
  | radicals | 12 | 41.7% (5) | 50.0% (6) | 0 | 1 |
  | simple (at most 20 tokens) | 24 | 54.2% (13) | 58.3% (14) | **3** | 4 |
  | 21-40 tokens | 62 | 50.0% (31) | 56.5% (35) | 3 | 7 |
  | more than 40 tokens | 34 | 41.2% (14) | 35.3% (12) | 5 | 3 |

- **The run failed the pre-agreed strict pass bar.** 3 of the 24 simple
  formulas got worse (the bar allows 1); overall 58 -> 61. The 3: `b \geq a r , \qquad ...`
  read with `\;` instead of `\qquad` (spacing); `\{ F , G \} =` read with
  an extra `\,` (spacing); `d f = - [ \theta , f ] ,` read as
  `d f\,--[\theta,f],` (a real error). Of the 11 that got worse overall,
  several differ only in spacing commands or extra braces
  (`{\frac{...}{...}}`); others are real errors (a duplicated `y` in a
  fraction, a misplaced brace).
- Per-topic differences are 1-2 formulas on 1-54 items: too small to
  call a gain or a loss. The test split is very likely close to the base
  model's training data.
- **Spacing-normalized score** (rule below, applied to both models the
  same way): overall 84 -> **78** of 120 (14 got worse, 8 better);
  simple 19 -> 17 of 24 (3 worse). On this score the fine-tuned model is
  worse: the strict gain came from copying im2latex's spacing habits,
  while real errors increased (e.g. `v~<<0`, runs of backslashes,
  `\frac\{P{((z)}}`).
- Outputs: `tactilelens-training\runs\20261109-163905_trackA_im2latex_prelim\`
  (`summary.md`, `run.json`, charts, `eval\comparison.md`). Kept: the
  epoch-5 checkpoint (`model\best_accuracy.*`) and its export (ONNX); the
  other checkpoints were deleted (2026-11-10, approved), 1.2 GB left.

**Two scores, decided in advance (2026-11-10).** Strict: math delimiters
and whitespace removed (evaluate_formula.py). Spacing-normalized: strict,
and in addition these LaTeX spacing commands are removed from target and
prediction before comparing: `\,` `\:` `\;` `\!` `\ ` (backslash-space)
`~` `\quad` `\qquad` `\enspace` `\thinspace` `\medspace` `\thickspace`
`\negthinspace` `\negmedspace` `\negthickspace` `\hspace{...}`. Nothing
else changes (braces, `\left`/`\right`, `\le` vs `\leq` still count).
**The pass bar is decided on the strict score**; the other is reported
alongside (`compare_formula.py`, 10 tests).

**Synthetic pilot (built 2026-11-10, approved)**:
`tools/dataset/make_synthetic_formulas.py`, output
`tactilelens-training\datasets\synthetic\formulas_pilot_20261109\` (2,400
images, 122 MB; `train.txt` only, LF; `manifest.jsonl`; `report.md`).

- 300 per topic from templates at worksheet level (e.g.
  `\frac{3x+1}{4}=2`, `\sqrt{x+9}=5`, `-3<2x+1\leq 7`,
  `f(x)=2x^{2}-3x+1`); labels in im2latex's spaced style, exactly what is
  drawn (`\leq`/`\geq`/`\neq` always written the same way). A check drew
  3,000 per topic: all 24,000 parse in mathtext; 1,049-2,859 distinct
  formulas per topic.
- Rendered with matplotlib 3.11.2 mathtext (installed 2026-11-10 with
  contourpy 1.3.3, cycler, fonttools 4.68.0, kiwisolver, pyparsing,
  python-dateutil 2.9.0.post0, six) in 10 font styles (cm, stix,
  stixsans, dejavusans, dejavuserif, Latin Modern, TeX Gyre Termes and
  Pagella, Liberation Serif and Sans; 219-262 images each). Half the
  fractions are drawn in display size (`\dfrac`), still labelled `\frac`.
- Paper from Track B (plain, tinted, lined or grid; the page-edge and
  table backgrounds are left out because they can put dark areas under
  the formula). Photo effects of the same kinds as Track B's
  `augment_v2` but with formula-safe ranges (`formula_effects`): Track B
  shrinks a line to 14-48 px high, which erased fractions and exponents in
  a first preview, and its perspective cut off the ends of a formula.
  15.7% are left clean (376), 2,024 have effects.
- Leak guard: no generated formula equals an im2latex val or test formula
  (224 held out; 0 matches) or a target in the frozen eval registry (none
  exists yet); duplicates dropped. `train_formula.py --extra-train`
  checks again against val and the final evaluation list (0 dropped).
- Generation: 47 s on 8 processes (51 images/s). A first attempt stopped
  on a template bug (`\leq` followed by a letter became the unknown command
  `\leqn`); its partial folder was replaced.

**Follow-up run `20261109_235227_followup_synth` (2026-11-10, approved;
the last run on im2latex: after this we wait for our own data).**

- Data: the 945 im2latex training formulas every epoch, plus 945 of the
  2,400 synthetic formulas drawn anew each epoch (PaddleOCR `ratio_list`
  0.394), so synthetic is half of each epoch (1,891 items, 473 steps).
- Settings, chosen on validation only: as the preliminary run (batch 4,
  lr 2e-5, warmup 100, seed 1024, patience 3), up to 10 epochs because
  the preliminary run's validation peaked at epochs 4-5.
- Speed: 0.12-0.14 s/step, 2,475 MB reserved; 2,860 steps in 442 s.
- Validation (104): original 41; epochs 1-6: 47, 52, **54**, 50, 50, 52.
  Stopped after epoch 6; exported checkpoint: epoch 3.
- **Test split (120 formulas), used once:**

  | score | all, original | all, fine-tuned | simple, original | simple, fine-tuned | simple got worse | bar |
  |---|---|---|---|---|---|---|
  | strict | 58 (48.3%) | **71 (59.2%)** | 13 (54.2%) | 17 (70.8%) | 0 | **met** |
  | spacing-normalized | 84 (70.0%) | 83 (69.2%) | 19 (79.2%) | 20 (83.3%) | 0 | not met (overall -1) |

  Per topic (strict): exponents 14 -> 15 of 17, fractions 21 -> 25 of 54,
  function_notation 3 -> 2 of 3, inequalities 2 -> 5 of 10,
  linear_equations 8 -> 10 of 15, polynomials 0 -> 1 of 1,
  quadratic_equations 5 -> 6 of 8, radicals 5 -> 7 of 12.
  Spacing-normalized: exponents 14 -> 15, fractions 34 -> 30,
  function_notation 3 -> 2, inequalities 6 -> 8, linear_equations
  11 -> 11, polynomials 1 -> 1, quadratic_equations 7 -> 8, radicals
  8 -> 8.
- **Meets the pre-agreed strict bar.** On the spacing-normalized score
  it is level with the original (83 vs 84; 8 worse, 7 better). The 8 that
  got worse are real errors: several drop the final `,` or `.` after a
  spacing command, one `\\\ =k`, one `c c)`, one broken `\ \(`, one reads
  `\left( ... \right)` as plain brackets. So most of the strict gain is
  im2latex's spacing style; no clear gain in reading formulas on this
  physics-paper data. Whether the synthetic worksheet formulas help on
  real worksheets can only be shown on our own `cap` eval set.
- Outputs: `tactilelens-training\runs\20261109-235227_trackA_im2latex+synthetic_followup\`
  (2.5 GB with all checkpoints). The plumbing check before it
  (`20261109_234813_check_mix`, 40 + 48 items, 22 steps, test split not
  scored) is 2.5 GB too.

**Filtering report for the panel:** `tactilelens-training\reports\im2latex_filter\`
(`report.md`, `chart_funnel.png`, `chart_topics.png`, `chart_looser.png`,
`examples_kept.png`, `examples_rejected.png`, `examples\`), made by
`tools/dataset/im2latex_filter_report.py`.

**Looser filters (counts only, before the leak guard):**

| variant | train | val | test |
|---|---|---|---|
| current | 953 | 104 | 120 |
| + subscripts (x_n, a_i, x_{n+1}) | 2,643 | 259 | 304 |
| + 8 Greek letters | 1,659 | 178 | 195 |
| + both | 4,456 | 458 | 522 |

Per topic (train) for "+ both": fractions 1,722, exponents 884,
linear_equations 669, quadratic_equations 432, inequalities 331, radicals
327, function_notation 60, polynomials 31 (current: 407, 149, 98, 89, 85,
92, 28, 5).

**Proposal (2026-11-09; built as a pilot on 2026-11-10, see above): synthetic algebra formulas for Track A training**

- What: formulas generated from templates for the 8 topics (fractions,
  exponents, radicals, linear and quadratic equations, inequalities,
  polynomials, function notation) with random numbers and letters, at
  worksheet level (e.g. `\frac{3x+1}{4}=2`, `\sqrt{x+9}=5`,
  `f(x)=2x^{2}-3x+1`, `-3<2x+1\le 7`). Labels in the same spaced LaTeX
  style as im2latex.
- Rendering: no LaTeX renderer is installed. Proposed: matplotlib's
  mathtext (renders \frac, \sqrt, \sqrt[3], powers, subscripts, \le, \ge,
  \neq, \pm, \cdot, \times, \left( \right)), with its 5 built-in font sets
  (Computer Modern, STIX, STIX sans, DejaVu Sans, DejaVu Serif) plus
  serif / sans fonts from our Track B font folder. Install into
  `paddle_formula_env`: matplotlib 3.11.2 (8.9 MB wheel) + fonttools (1.6
  MB), kiwisolver, pyparsing, cycler, contourpy (an older version with a
  Python 3.11 wheel, about 0.2 MB), python-dateutil 2.9.0.post0: about 11
  MB in total (sizes from PyPI; not downloaded).
- Phone-photo effects: Track B's `render.augment_v2` (blur, noise, JPEG,
  uneven light, perspective, paper and ink colour). Measured on this PC:
  67 images/s at 120 x 600 px and 21 images/s at 200 x 900 px, one
  process; 12 CPU cores.
- How many: a pilot of 300 per topic (2,400), then up to 1,500 per topic
  (12,000), more for the weak topics (fractions, inequalities, radicals).
  Mixed with the 945 im2latex formulas so that synthetic is at most about
  half of each batch (a weighted list), to limit drift towards one
  rendering style.
- Time: rendering speed not measured (no renderer installed). With
  effects at 21-67 images/s per process and rendering assumed to be of the
  same order, 12,000 images on 8 processes would take roughly 2-15
  minutes (estimate). Training cost: 12,945 items at batch 4 is 3,237
  steps, about 8 minutes per epoch at the measured 0.15 s/step.
- Kept separate from every eval set: synthetic items only ever go into a
  training list; a leak guard drops any synthetic LaTeX (spaces removed)
  equal to an im2latex val/test formula or to a target in our frozen eval
  registry; synthetic images are named `<topic>_syn_<n>.png` so the
  evaluator can never mistake them for `cap` items. Validation stays
  im2latex val (and our own val captures when they exist).
- Limits: rendered formulas with simulated photo effects are still not
  phone photos of real worksheets; mathtext layout differs slightly from
  LaTeX. The gain has to be shown on our own `cap` eval set.

## Track C: PaddleOCR-VL partial fine-tuning

What the sources say (checked 2026-11-07):

| question | answer | source |
|---|---|---|
| which model can be trained | **only the original `PaddlePaddle/PaddleOCR-VL` (0.9B)** is documented. PaddleOCR-VL-1.6 is not named as a fine-tuning target anywhere; its card documents inference only ("architecture fully compatible with PaddleOCR-VL-1.5"). We do not substitute 1.6. | ERNIE `docs/paddleocr_vl_sft.md` (release/v1.5); huggingface.co/PaddlePaddle/PaddleOCR-VL-1.6 |
| LoRA | a maintainer: setting `fine_tuning` to LoRA (with `lora_rank`) starts LoRA SFT; raise `learning_rate` and `packing_size`; best practice still being explored. No shipped LoRA config (`examples/configs/PaddleOCR-VL/` has only `sft/run_ocr_vl_sft_16k.yaml`). Merging/exporting LoRA: an error report there is unanswered. | github.com/PaddlePaddle/ERNIE/issues/1397 |
| PaddleFormers | release notes: LoRA fine-tuning for VLMs and `paddleocr_vl` among new models; no PaddleOCR-VL config or keys given. | github.com/PaddlePaddle/PaddleFormers/releases |
| frozen vision encoder / only some layers | **not documented** for PaddleOCR-VL in ERNIEKit or PaddleFormers. (A different tool, mlx-vlm, reports freezing `model.visual` for LoRA; not applicable here.) | as above |
| hardware | config: `compute_type: bf16`, `use_flash_attention: True`, recompute full; "about 2 hours on a single A800-80G"; CUDA 12+. A T4 is neither listed nor excluded, but has no bf16. | ERNIE guide and config |
| hosted API | cannot be fine-tuned; the deployed app keeps using it | |

**Memory test on the RTX 4050 (after approval; WSL2 Ubuntu is already
installed but stopped)**: a Python env in WSL2 with `paddlepaddle-gpu`
3.2.x (CUDA 12.6) and ERNIEKit (sizes not checked), the base 0.9B (2.00
GiB). Settings: bf16 (Ada supports it), batch 1, recompute full, LoRA
rank 8, `max_seq_len` 2048, short formula crops only, 20 steps. Record
peak memory (nvidia-smi every 5 s and the trainer's log) and seconds per
step. Decision: peak under about 5.5 GB -> train on the laptop; otherwise
Colab.

**Colab (free)**: `tools/training_vl/colab_lora_sft.ipynb` (never run).
Cell 1 checks the GPU and stops on a T4 unless `EXPERIMENTAL_T4 = True`
(fp16, no flash attention, 20 steps). In that mode the run folder ends in
`_EXPERIMENTAL_T4`, `run.json` is labelled **"EXPERIMENTAL, not the
documented setup, not a usable model"**, and cells 7 and 8 (merge,
evaluation) refuse to run. Otherwise it mounts Drive, unpacks the split,
runs `convert_to_sft.py`, installs PaddlePaddle + ERNIEKit, caches the base
model on Drive, trains with checkpoints on Drive and resumes from the
newest after a timeout (`resume_from_checkpoint`: not verified), tries the
LoRA merge (not verified), evaluates the merged model and the base 0.9B
with `evaluate_vl.py`, and leaves everything in `runs/<run id>/`. The older
`colab_sft.ipynb` (full fine-tuning, A100 40 GB) is kept for reference.

**The approved T4 test, step by step (you run every cell):**

1. In Google Drive, create `MyDrive/tactilelens/` and upload into it the
   two folders I prepared (about 0.3 MB): `tools/training_vl/` (5 files) and
   `data/FAKE_split_T4_test.zip` (the FAKE dry-run split: 46 generated
   images, labelled FAKE; the test needs data only to run, not to learn).
2. colab.research.google.com > File > Upload notebook >
   `tools/training_vl/colab_lora_sft.ipynb`.
3. Runtime > Change runtime type > **T4 GPU** > Save.
4. In cell 1 set `EXPERIMENTAL_T4 = True`. In cell 2 set
   `SPLIT_ZIP = BASE / "data" / "FAKE_split_T4_test.zip"`.
5. Run cells 1 to 6 in order. Cell 2 asks you to sign in to Google Drive.
   Cell 4 installs PaddlePaddle and ERNIEKit on Colab (time not measured);
   cell 5 downloads the 0.9B model to `MyDrive/tactilelens/cache/` (2.0
   GiB of your Drive); cell 6 trains 20 steps.
6. Do not run cells 7 and 8 (they stop in this mode anyway).
7. Send me `MyDrive/tactilelens/runs/<id>_EXPERIMENTAL_T4/run.json` and
   `logs/` (`train.log`, `gpu_memory.csv`), or paste the last 50 lines of
   cell 6 and any error. If a cell fails, send that cell's output.
8. Afterwards you may delete `runs/CURRENT_RUN.txt` (so a later run starts
   fresh) and `cache/` (2.0 GiB) if Drive space is needed.

What it can show: whether ERNIEKit accepts fp16 without flash attention
for PaddleOCR-VL on a T4, peak GPU memory, seconds per step. What it
cannot show: anything about accuracy (20 steps on FAKE data).

**Serving for the demo**: run the fine-tuned model on the laptop through
the AI service's local engine (`PADDLEOCR_ENGINE=local`); the deployed app
keeps the hosted API. The local engine cannot load another model folder
today: it needs two optional settings passed to `PaddleOCRVL(...)`
(`vl_rec_model_dir`, `vl_rec_model_name`) and `PADDLEOCR_PIPELINE_VERSION=v1`
for a 0.9B model. That is an AI service change, proposed, not made.
Until then `evaluate_vl.py --engine finetuned --model-dir ...` runs it.

## Public data for the preliminary run (Track A)

1. **im2latex-100k** (huggingface.co/datasets/yuntian-deng/im2latex-100k):
   CC0-1.0 (its README: `license: cc0-1.0`); rendered printed formulas
   from arXiv LaTeX; train 55,033 / val 6,072 / test 6,810. Downloaded
   2026-11-08 to `tactilelens-training\datasets\public\im2latex-100k\raw\` (three
   Parquet files, 272,974,295 + 30,031,854 + 34,007,576 bytes = the
   listing). `pyarrow` 26.0.1 installed in `paddle_formula_env`
   (2026-11-09, after approval; no other packages added).
2. **UniMER-Test SPE: not used** (your decision, 2026-11-09): no licence
   stated for that subset, and it overlaps the data the base model was
   trained on. (Findings kept for reference: SPE is "Pix2tex Validation",
   LaTeX from Wikipedia, arXiv and im2latex-100k rendered with XeLaTeX;
   about 18 MB of the 146.7 MB `UniMER-Test.zip`; the only licence is the
   card's `apache-2.0` for the whole dataset.)

**Evaluation sets.** Main: our own held-out phone captures (`cap`, the
frozen eval split). Public check: im2latex-100k's own **test** split,
never trained on or used for model selection.

**im2latex-100k filtered to expressions using general-algebra notation;
the source formulas come from physics papers** (`tools/dataset/prepare_im2latex.py`,
2026-11-09): `tactilelens-training\datasets\public\im2latex-100k\filtered_general_algebra\` (7.9 MB).
Not a worksheet algebra dataset. Panel page (filter rules, counts,
examples, limits, both runs' charts):
https://claude.ai/artifact/RzYqVDqxHiLboEnVZjzdVv (private until you share it),
local copy `tactilelens-training\reports\im2latex_filter\im2latex_filter_report.html`.

| | train | val | test |
|---|---|---|---|
| published | 55,033 | 6,072 | 6,810 |
| passed the filter | 953 | 104 | 120 |
| dropped by the leak guard | 8 | 0 | 0 |
| **kept** | **945** | **104** | **120** |

| topic | train | val | test |
|---|---|---|---|
| fractions | 405 | 44 | 54 |
| exponents | 149 | 14 | 17 |
| linear_equations | 96 | 12 | 15 |
| radicals | 91 | 7 | 12 |
| quadratic_equations | 87 | 10 | 8 |
| inequalities | 84 | 13 | 10 |
| function_notation | 28 | 2 | 3 |
| polynomials | 5 | 2 | 1 |

| formula length (LaTeX tokens) | train | val | test |
|---|---|---|---|
| at most 20 ("simple") | 134 | 13 | 24 |
| 21-40 | 560 | 65 | 62 |
| more than 40 | 251 | 26 | 34 |

- The filter keeps 1.7% of im2latex (most drops: longer than 60 tokens
  11,920; accents 3,787; subscripts other than x_1 2,663; `\mu` 2,248).
- Topics are a heuristic on the LaTeX, one per formula, first rule that
  matches: f(x) -> function_notation; <, >, \le, \ge, \neq ->
  inequalities; \sqrt -> radicals; \frac -> fractions; = and a power of 2
  -> quadratic_equations; a power with + or - and no = -> polynomials;
  other powers -> exponents; the rest -> linear_equations. Not checked by
  hand.
- Leak guard between the splits: a train or val formula is dropped when
  its image (sha256) or its LaTeX (spaces removed) is also in test, and a
  train formula when it is also in val. It dropped 8 train images that are
  byte-identical to val (5) or test (3) images.
- These are physics-paper formulas that pass the filter on syntax (for
  example `F ^ { 2 } - 1 \le 2 ( N ^ { 2 } - 1 ) + ...`), not worksheet
  algebra; good for checking the pipeline and catching regressions, not a
  stand-in for our data.

Caveat: PP-FormulaNet was very likely trained on data from the same
sources (arXiv formulas, im2latex), so the public check is not an unseen
test; our own held-out phone captures are.

## Known issues found while preparing

- **PaddleOCR reads label lines with `strip("\n")` only.** A label file
  with Windows line ends (CRLF) leaves `\r` at the end of every label: the
  model is trained to output it and no validation item matches (exp_rate
  0.0). `prepare_im2latex.py` writes LF (tested) and `train_formula.py`
  refuses a label file containing CR. The first im2latex subset
  (`data\public\im2latex_algebra\`, CRLF, 7.9 MB) is superseded by
  `im2latex_algebra_lf\` (same text and images).
- PaddleOCR switches validation of formula models to the right code path
  only inside its training-metric code, so `cal_metric_during_train` must
  stay `True` (it is in the config).
- `train_formula.py` tells `tools/program.py` the platform is Linux so
  that every training batch and every validation item is used (the
  Windows last-batch skip exists for data-loader workers; we use 0).
- **2026-11-09, about 12:30-16:30: the RTX 4050 disappeared from Windows**
  (device status `CM_PROB_PHANTOM`, `nvidia-smi`: "insufficient
  permissions", Paddle: "no CUDA-capable device"); the laptop was on
  battery (47%). The GPU checks before that ran on it. Usually the
  dedicated GPU is switched off by a power / graphics mode (e.g. on
  battery) or needs a restart; not diagnosed further. It was back at
  16:30 (after you plugged in / restarted) and the preliminary run used it.
- On Windows, PaddleOCR's `tools/program.py` skips the last batch of every
  validation pass and of every training epoch (`max_iter = len(loader) - 1`).
  With a single validation batch nothing is scored (acc 0, edit distance
  1.0). `train_full.py` validates in batches of 8, records how many lines
  are scored and refuses below 80%.
- Sanity check (2026-11-07): `evaluate.py --set synthetic-eval` with the
  app's recognizer (sha256 `dfa6c7c5...`) on the frozen synthetic eval set
  (labels sha256 `e29fb71a...`) gives 68.5% exact, 59.7% exponent exact,
  CER 7.3%: every per-topic row and all 200 predictions are identical to
  the October baseline. The evaluation path is reproducible.
- AMP (mixed precision) crashes in `paddle_train_env`: when the loss
  scaler meets an inf/nan step, Paddle 3.2.1 formats its message with
  `float()` of a 1-element array, which NumPy 2.4.1 rejects
  (`TypeError: only 0-dimensional arrays can be converted to Python
  scalars`). `train_full.py` therefore defaults to full precision
  (`--amp` to try it), as the October trial ran. Fixing it would need
  an older NumPy in that environment (an environment change: ask first).
- PaddleX's `--paddle2onnx` looks for the `paddle2onnx` executable on
  PATH (`shutil.which`); `train_full.py` puts `paddle_onnx_env\Scripts`
  first on PATH for that step.
- Paddle warns it was built with cuDNN 9.9 while the machine has 9.5. The
  October trial and today's GPU dry run trained with it; not otherwise
  investigated.
- In the previous session the GPU was not visible to my tools (Paddle:
  "no GPU detected"); in this one it is (`gpu:0`, compute capability 8.9).
  The first dry run therefore ran on the CPU.

### Track B dry runs (2026-11-07/08; synthetic lines, not results)

| run | where | lines (train / val) | outcome | checks |
|---|---|---|---|---|
| `20261107_224849_dryrun` | CPU | 192 / 40 (32 scored) | stopped at the 40-minute limit, then `--continue-run`: export, ONNX, evaluation | ONNX inputs/outputs and dictionary as the app's: yes; app model on synthetic-eval 68.5% exact (= October) |
| `20261107_235841_dryrun` | GPU, batch 64 | 2,048 / 80 (72 scored) | finished in 195 s (40 steps), export, ONNX, evaluation | as above; peak 5,858 MB reserved |
| `20261108_081812_dryrun` | GPU, batch 256 requested | 2,048 / 80 (72 scored) | batch 256 ran out of memory (cuDNN `CUDNN_STATUS_INTERNAL_ERROR_HOST_ALLOCATION_FAILED`), retried at 64, finished in 100 s | fallback works; peak at 64: 5,143 MB reserved |

The "new" model's numbers in those runs (79.5% and 88.0% exact on
synthetic-eval) come from a few steps on lines from the same generator as
that eval set; they show the plumbing works, nothing about real photos.

## Approvals

Done after approval: 2026-11-08: the Track A environment copy and
packages, the checkpoint, the official inference model, the demo set,
im2latex-100k (download). 2026-11-09: `pyarrow` 26.0.1; deleting the
dry-run checkpoints and Track A verification exports (weights only, about
6 GB; logs, configs and results kept); the Track A preliminary run;
deleting the check runs' checkpoints and the CRLF subset (about 5 GB).
2026-11-10: matplotlib 3.11.2 and dependencies; the synthetic pilot
(2,400); the follow-up run; keeping only the preliminary run's epoch-5
checkpoint and ONNX; the workspace reorganisation; deleting the follow-up
run's other checkpoints and the `check_mix` run's checkpoints (about
3.8 GB). Declined: UniMER-Test SPE, the looser filter.

Still needed:

| item | size | why |
|---|---|---|
| Delete the layout check run's checkpoints and export (`runs\20261110-011959_trackA_im2latex+synthetic_layout-check`) | frees about 2.5 GB | disk |
| ImageMagick for Windows (Wand) | not checked | the Snow augmentation (skipped for now) |
| WSL2 env: `paddlepaddle-gpu` 3.2.x + ERNIEKit + requirements | not checked (several GB) | Track C laptop memory test (on hold) |
| `PaddlePaddle/PaddleOCR-VL` (0.9B) to the laptop | 2.00 GiB | Track C laptop test (on hold) |
| AI service: optional VL model folder settings | code change | demo of a fine-tuned VL model (on hold) |

Colab installs and downloads happen on Google's machines when you run the
notebook; nothing is installed on the PC for that.
