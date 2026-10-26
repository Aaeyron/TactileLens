# PaddleOCR-VL fine-tuning tools (online engine)

Tooling only. **No model has been fine-tuned and there are no fine-tuning
results.**

What this can and cannot do:

- The hosted official API (Baidu AI Studio, used by the app's online
  scans) **cannot be fine-tuned**. These tools never train through it.
- Only our own copy of the open model can be fine-tuned, with ERNIEKit
  (guide: https://ernie.readthedocs.io/en/develop/paddleocr_vl_sft.html;
  the `/en/latest/` address returns 404). ERNIEKit documents this for
  `PaddlePaddle/PaddleOCR-VL` (0.9B). The app uses PaddleOCR-VL-1.6;
  fine-tuning 1.6 with ERNIEKit is **not verified**.
- A fine-tuned model would have to run on **our own GPU hosting**; the
  app's hosted engine would not use it.

Python: `C:\Projects\Capstone\paddle_onnx_env` (Pillow). Run from this folder.

## Data format

Images named `topic_source_kind_number.ext`, e.g. `radicals_ss_S_001.png`,
anywhere under a data folder (topic folders are fine). From the name
(mappings in `config.json`):

- source: `ss` screenshot, `cap` phone capture
- kind: `S` single equation/notation, `M` multi notation, `T` text +
  notation, `W` full worksheet/document (T is not "table")

Labels CSV: `filename,task,target,split`

- task: `formula` (target in LaTeX), `table` (target in OTSL: `<fcel>`,
  `<ecel>`, `<lcel>`, `<ucel>`, `<xcel>`, `<nl>`), `text`
- split: `train`, `val`, `eval` (eval is held out, never trained on)

## 1. Convert to ERNIEKit SFT JSONL

```
python convert_to_sft.py --data D:\vl_data --labels D:\vl_data\labels.csv --out D:\vl_data\sft
```

Writes `train.jsonl`, `val.jsonl`, `eval.jsonl` (ERNIEKit records: prompt
`OCR:` / `Formula Recognition:` / `Table Recognition:` tagged `mask`,
target tagged `no_mask`, `image_info` with `matched_text_index` 0),
`<split>_meta.jsonl` (topic, source, kind, task, sha256) and
`report.json` / `report.md` (counts per split, topic, kind, source, task).
Formula targets without delimiters are wrapped as `\[...\]`, as in the
ERNIEKit example. `image_url` is relative to `--out` (run ERNIEKit from
there) or absolute with `--absolute-urls`.

Every record is checked (name, task, split, image opens, target not
empty, LaTeX braces / `\left`-`\right` / `\begin`-`\end` balanced, OTSL
tokens valid and rows even, mask/no_mask alternating). **If anything is
wrong, or an eval image leaks, nothing is written.**

Leak guard: no train/val image may have the same bytes (sha256) as an
eval image of the dataset or of the recognizer tools' eval sets
(`tools/training`: `eval/real`, `eval/synthetic`), and no file name may
be in two splits.

## 2. Evaluate engines on the held-out eval set

```
python evaluate_vl.py --eval D:\vl_data\sft --engine local                 # PaddleOCR-VL-1.6 on this PC
python evaluate_vl.py --eval D:\vl_data\sft --engine local --mode layout   # with layout detection, as the app
python evaluate_vl.py --eval D:\vl_data\sft --engine finetuned --model-dir D:\vl_ft\export --vl-model-name PaddleOCR-VL-0.9B --pipeline-version v1
python evaluate_vl.py --eval D:\vl_data\sft --engine hosted --confirm-own-material --max-pages 50
```

- `local` / `finetuned` run `local_vl_worker.py` with
  `paddleocr_vl_env` (used as is, nothing installed). **Stop the AI
  service first** so the 6 GB GPU is free. `--mode prompt` (default)
  reads the whole image with the task prompt; `--mode layout` runs layout
  detection as the app does. `--vl-model-name` / `--pipeline-version`
  choose the model: `PaddleOCR-VL-1.6-0.9B` with `v1.6` (default) or
  `PaddleOCR-VL-0.9B` with `v1` (the model ERNIEKit fine-tunes; a
  fine-tuned folder loaded this way is not verified).
- `hosted` uses the AI service's client. The client reads
  `PADDLEOCR_ACCESS_TOKEN` from the environment; this script never reads,
  prints or stores it. **Images sent are stored by Baidu: only your own
  material, no third-party pages or personal data.** It counts pages with
  the daily cap (`PADDLEOCR_DAILY_PAGE_CAP`, below 3000) and stops at the
  cap or `--max-pages`; failed jobs are not resubmitted. Set
  `PADDLEOCR_PAGE_COUNT_FILE` to the AI service's file to share its count
  (otherwise `outputs/vl_eval/hosted_page_count.json`). The hosted API
  always runs layout detection (no task prompt). Only label and text of
  each block are kept; image links are dropped.

Metrics overall and per task, topic, kind and source: exact match after
normalisation (LaTeX delimiters and spaces ignored, tables compared as
OTSL), mean normalised edit distance, and how often the app's formula
guard would hold the block (prediction, and target for reference).
Output: `tactilelens-training\outputs\vl_eval\<time>_<engine>_<hash>\`
(`results.md`, `results.csv`, `predictions.tsv`, `run.json`).

## 3. Fine-tuning (not run)

Feasibility and memory estimates: [docs/vl_finetuning_feasibility.md](../../docs/vl_finetuning_feasibility.md).
In short: not on our 6 GB card or a free Colab T4; a Colab A100 is the
realistic option. `colab_sft.ipynb` follows the ERNIEKit guide (full
fine-tuning of PaddleOCR-VL-0.9B on `train.jsonl`, `val.jsonl` for eval,
`eval.jsonl` never used); it stops on GPUs below compute 8.0 / 39 GB.
**It has never been run.** Its data-check cell (absolute image links,
hashes, eval leak guard) was run locally on the fake dataset.

## Tests and dry run

```
python -m unittest discover -s tests -t .
python make_fake_dataset.py --out C:\temp\vl_fake            # 12 generated images
python make_fake_dataset.py --out C:\temp\vl_fake_leak --leak  # + a planted leak
```

Verified: the unit tests pass (15); the fake dataset converts (6 train,
2 val, 4 eval) and the planted leak is refused with nothing written; the
local engine ran on the 4 fake eval images in both modes (prompt mode:
2/4 exact, layout mode: 3/4; the table differed only in `n²` vs
`$ n^{2} $`). This is a plumbing check on generated images, not a
measure of accuracy. Not verified: the hosted engine (not run by us),
the `finetuned` engine (no fine-tuned model), ERNIEKit training on
these files (no training run).
