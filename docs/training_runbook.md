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
  almost no headroom**. If a real run runs out of memory, use
  `--batch-size 48`.
- October trial, batch 96: 38.3 lines/s, about 157 s per epoch of 6,000
  lines.
- Estimate (not measured): about 12,000 synthetic + the dataset's lines
  at about 35 lines/s is about 6 minutes per epoch, so at most about an
  hour for 8 epochs with validations; early stopping usually ends sooner.

**Track A (laptop), after your approval** (see "Approvals"): the memory
trial below, then a full run only if it fits.

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
  that it was converted from this exact checkpoint is **not verified**
  (step 2 below checks it).
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

**Plan (each step after your approval)**

1. Install the four packages into a copy of `paddle_train_env` (so the
   recognizer environment stays as it is) and download the 244 MiB
   checkpoint.
2. Export check before training: `tools/export_model.py` on the
   downloaded checkpoint -> `paddlex --paddle2onnx` -> compare with the
   app's ONNX: same inputs/outputs, the decoding `Loop` operator inside the
   graph (the Android runtime needs it), and the same predictions on our
   `formula_eval.txt` with `evaluate_formula.py`. If this does not
   reproduce the app's model, we stop: a retrained model could not be
   used.
3. Memory trial (about 15 minutes): batch 8, then 4, then 2, AMP on,
   `max_new_tokens` 1024, 50 steps on the split's `formula_train.txt` (or
   the 23 MiB official demo set), no Snow augmentation; record peak GPU
   memory (trainer log `max_mem_reserved`) and seconds per step.
4. Only if a batch fits: a short real run, export as in 2, and
   `evaluate_formula.py` against the app's model.

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
(fp16, no flash attention, 20 steps: a feasibility and memory test, not
documented). It mounts Drive, unpacks the split, runs `convert_to_sft.py`,
installs PaddlePaddle + ERNIEKit, caches the base model on Drive, trains
with checkpoints on Drive and resumes from the newest after a timeout
(`resume_from_checkpoint`: not verified), tries the LoRA merge (not
verified), evaluates the merged model and the base 0.9B with
`evaluate_vl.py` on the held-out eval, and leaves everything in
`runs/<run id>/` for download. The older `colab_sft.ipynb` (full
fine-tuning, A100 40 GB) is kept for reference; it needs a paid GPU.

**Serving for the demo**: run the fine-tuned model on the laptop through
the AI service's local engine (`PADDLEOCR_ENGINE=local`); the deployed app
keeps the hosted API. The local engine cannot load another model folder
today: it needs two optional settings passed to `PaddleOCRVL(...)`
(`vl_rec_model_dir`, `vl_rec_model_name`) and `PADDLEOCR_PIPELINE_VERSION=v1`
for a 0.9B model. That is an AI service change, proposed, not made.
Until then `evaluate_vl.py --engine finetuned --model-dir ...` runs it.

## Public data for the preliminary run (Track A)

Recommended (not downloaded):

1. **im2latex-100k** (huggingface.co/datasets/yuntian-deng/im2latex-100k):
   CC0-1.0; rendered printed formulas from arXiv LaTeX; train 55,033 / val
   6,072 / test 6,810; about 337 MB. Mostly advanced math, so filter first.
2. **UniMER-Test SPE** (huggingface.co/datasets/wanderkid/UniMER_Dataset):
   Apache-2.0 tag; 6,762 simple printed expressions; held out for
   evaluation only. The whole UniMER download is about 2.13 GB (SPE alone:
   not checked).

Caveat: PP-FormulaNet was very likely trained on data from the same
sources, so these are a plumbing and sanity check, not an unseen test;
our own held-out phone captures are. Filter:
`tools/dataset/algebra_filter.py` (allowed commands only: frac, sqrt,
cdot, times, div, pm, inequalities, spacing, a few Greek letters; at most
60 tokens; no environments, sums, integrals, limits, accents or fonts; at
least one of = < > ^ \frac \sqrt f(x)). Tested on hand-written examples;
how much of im2latex-100k it keeps is not measured.

## Known issues found while preparing

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

The "new" model's numbers in those runs (79.5% and 88.0% exact on
synthetic-eval) come from a few steps on lines from the same generator as
that eval set; they show the plumbing works, nothing about real photos.

## Approvals needed (nothing below has been done)

| item | size | why |
|---|---|---|
| Track A packages into a copy of `paddle_train_env` (`tokenizers==0.19.1`, `ftfy`, `imagesize`, `Wand`) | about 2.3 MB of wheels; the env copy is about the size of `paddle_train_env` (not measured) | formula training |
| ImageMagick for Windows (Wand) | not checked | the Snow augmentation of a real Track A run |
| `PP-FormulaNet_plus-S_pretrained.pdparams` | 244 MiB | Track A checkpoint |
| optional: `PP-FormulaNet_plus-S_infer.tar` | 247 MiB | a second check of the export path |
| optional: formula demo set `ocr_rec_latexocr_dataset_example.tar` | 23 MiB | memory trial before our data |
| WSL2 env: `paddlepaddle-gpu` 3.2.x + ERNIEKit + requirements | not checked (several GB) | Track C laptop memory test |
| `PaddlePaddle/PaddleOCR-VL` (0.9B) to the laptop | 2.00 GiB | Track C laptop test and the base-model baseline |
| im2latex-100k | about 337 MB | preliminary Track A run |
| UniMER-Test (SPE) | whole dataset about 2.13 GB | public held-out check |
| AI service: optional VL model folder settings | code change | demo of a fine-tuned VL model |

Colab installs and downloads happen on Google's machines when you run the
notebook; nothing is installed on the PC for that.
