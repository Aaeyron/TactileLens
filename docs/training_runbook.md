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

## Day 1: intake, split, baselines

**You**

1. Copy the delivery (zips and/or folders) into
   `C:\Projects\Capstone\tactilelens-training\incoming\`. Keep the originals
   elsewhere too; the tools never change them.
2. Read `intake\<run>\report.md` when I send it, and check every flagged
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
   mainly from labelled phone captures; the frozen eval registry keeps them
   out of training for good.
3. Zip `splits\<id>\images` + `labels.csv` for Drive and tell you its size.
4. Baselines of today's models on the held-out eval (nothing trained yet):
   - recognizer: `tools\training\evaluate.py --labels splits\<id>\rec_eval.txt`
   - formula: `tools\model_prep\evaluate_formula.py --labels splits\<id>\formula_eval.txt`
   - VL: `tools\training_vl\evaluate_vl.py --eval splits\<id>\sft --engine local`
     (PaddleOCR-VL-1.6 on the laptop; stop the AI service first)

## Day 2: training

**Track B (laptop).** I start it (or you, with the same command):

```
cd C:\Projects\Capstone\TactileLens\tools\training
C:\Projects\Capstone\paddle_train_env\Scripts\python train_full.py --split C:\Projects\Capstone\tactilelens-training\splits\<id>
```

Batch 64, at most 8 epochs, validation on REAL lines only (the split's
`rec_val.txt` and `data\real\val.txt`; it stops if there are none),
early stopping after 3 validations without a better accuracy, then export,
ONNX (PaddleX paddle2onnx, opset 17), a check of the ONNX inputs/outputs
and dictionary against the app's, and `evaluate.py` with the app's model
and the new one on every eval set. Output and `comparison.md`:
`outputs\full\<run>\`. Full precision (AMP crashes in this environment,
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
Only measured numbers. A model is proposed for the app only if it beats
the current one on the held-out phone captures, and then only after its
Braille output is checked.

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
   `tactilelens-training\pretrained\formula\`
   `PP-FormulaNet_plus-S_pretrained.pdparams` (256,890,832 bytes, sha256
   `a8a72053...`) and `PP-FormulaNet_plus-S_infer.tar` (259,604,480,
   `31e8659f...`); the demo set `ocr_rec_latexocr_dataset_example.tar`
   (25,108,480, `6ed9bd71...`; 10,000 train / 500 val arXiv-style formulas)
   in `data\public\formula_demo\`.
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
   checkpoint; `outputs\formula_trial\20261108_161345\`):

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

**Proposed full preliminary run (waiting for approval):**

- Data: `im2latex_algebra_lf`, all 945 train / 104 val; test only for
  the final comparison.
- Batch 4, fp32, lr 2e-5 (a fifth of the config's 1e-4: small data, a
  converged model), warmup 100 steps, cosine decay, up to 20 epochs (the
  config's), 237 steps per epoch.
- Selection: PaddleOCR's `best_accuracy` (highest val exp_rate; one val
  item is about 1%).
- Early stopping: after 3 validations (epochs) without a higher val
  exp_rate.
- Time (estimated from measurements, not measured for this run): 0.19
  s/step at batch 4 in the memory trial, 1.2 s/step averaged over the
  check's first 10 steps (includes start-up); validation of 104 items at
  about 4 items/s on the GPU (check: 3.97) is about 30 s. So 1-5 minutes
  per epoch, about 20-100 minutes for 20 epochs, less with early stopping.
- Disk: about 2.5 GB per run (best and latest checkpoints with optimizer
  state, 720 MB each, plus the 448 MB export).
- Report: per topic and per length, original vs fine-tuned on the test
  split, and every item that was exact before and not after. Suggested
  bar for "simple formulas didn't get worse": at most 1 of the 24 simple
  test items exact before and not after, and overall exact not lower.

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
   2026-11-08 to `tactilelens-training\data\public\im2latex-100k\` (three
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

**Algebra subset** (`tools/dataset/prepare_im2latex.py`, 2026-11-09):
`tactilelens-training\data\public\im2latex_algebra_lf\` (7.9 MB).

| | train | val | test |
|---|---|---|---|
| published | 55,033 | 6,072 | 6,810 |
| passed the algebra filter | 953 | 104 | 120 |
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
- **2026-11-09, about 12:30: the RTX 4050 disappeared from Windows**
  (device status `CM_PROB_PHANTOM`, `nvidia-smi`: "insufficient
  permissions", Paddle: "no CUDA-capable device"); the laptop was on
  battery (47%). The GPU checks before that ran on it. Usually the
  dedicated GPU is switched off by a power / graphics mode (e.g. on
  battery) or needs a restart; not diagnosed further.
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
6 GB; logs, configs and results kept). Declined: UniMER-Test SPE.

Still needed:

| item | size | why |
|---|---|---|
| Track A preliminary run on the im2latex algebra subset (proposal in Track A) | about 2.5 GB disk per run; 20-100 min estimated, not measured | first fine-tuned formula model |
| Delete superseded outputs: `im2latex_algebra\` (CRLF) and the checkpoints of the three check runs | frees about 5 GB | disk |
| ImageMagick for Windows (Wand) | not checked | the Snow augmentation (skipped for now) |
| WSL2 env: `paddlepaddle-gpu` 3.2.x + ERNIEKit + requirements | not checked (several GB) | Track C laptop memory test (on hold) |
| `PaddlePaddle/PaddleOCR-VL` (0.9B) to the laptop | 2.00 GiB | Track C laptop test (on hold) |
| AI service: optional VL model folder settings | code change | demo of a fine-tuned VL model (on hold) |

Colab installs and downloads happen on Google's machines when you run the
notebook; nothing is installed on the PC for that.
