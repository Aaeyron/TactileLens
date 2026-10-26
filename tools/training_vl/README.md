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

## Tests and dry run

```
python -m unittest discover -s tests -t .
python make_fake_dataset.py --out C:\temp\vl_fake            # 12 generated images
python make_fake_dataset.py --out C:\temp\vl_fake_leak --leak  # + a planted leak
```

Verified: the unit tests pass; the fake dataset converts (6 train, 2 val,
4 eval) and the planted leak is refused with nothing written. Not
verified: ERNIEKit actually training on these files (no training run).
