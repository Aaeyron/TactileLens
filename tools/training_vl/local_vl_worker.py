"""Runs PaddleOCR-VL on a list of images. Started by evaluate_vl.py with
the paddleocr_vl_env Python (used as is; nothing is installed there).

  python local_vl_worker.py --jobs jobs.json --out predictions.json [--model-dir DIR] [--mode prompt|layout]

jobs.json: [{"id": ..., "image": <path>, "prompt_label": "formula"|"table"|"ocr"}, ...]
The pipeline is built as the AI service builds it (pipeline v1.6,
gpu:0, paddle engine, native VL backend, no orientation/unwarping, no
queues). --model-dir points the VL model at a fine-tuned folder.

Modes:
  prompt  no layout detection; the whole image is read with the task's
          prompt (ocr / formula / table)
  layout  layout detection on, as the app's online pipeline does
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def blocks_of(result) -> list[dict]:
    data = result.json
    data = data.get("res", data)
    blocks = data.get("parsing_res_list") or []
    return [{"label": b.get("block_label", ""), "content": b.get("block_content", "")} for b in blocks if isinstance(b, dict)]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--jobs", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--model-dir")
    parser.add_argument("--mode", choices=["prompt", "layout"], default="prompt")
    parser.add_argument("--pipeline-version", default="v1.6")
    parser.add_argument("--device", default="gpu:0")
    args = parser.parse_args()

    from paddleocr import PaddleOCRVL  # only in paddleocr_vl_env

    options = dict(
        pipeline_version=args.pipeline_version,
        device=args.device,
        engine="paddle",
        vl_rec_backend="native",
        use_layout_detection=args.mode == "layout",
        use_doc_orientation_classify=False,
        use_doc_unwarping=False,
        use_queues=False,
    )
    if args.model_dir:
        options["vl_rec_model_dir"] = args.model_dir
    started = time.perf_counter()
    pipeline = PaddleOCRVL(**options)
    load_seconds = time.perf_counter() - started

    jobs = json.loads(Path(args.jobs).read_text(encoding="utf-8"))
    predictions = []
    for job in jobs:
        t0 = time.perf_counter()
        try:
            if args.mode == "prompt":
                results = pipeline.predict(input=job["image"], use_layout_detection=False,
                                           prompt_label=job["prompt_label"], use_queues=False)
            else:
                results = pipeline.predict(input=job["image"], use_layout_detection=True, use_queues=False)
            blocks = [b for r in results for b in blocks_of(r)]
            predictions.append({"id": job["id"], "blocks": blocks, "seconds": round(time.perf_counter() - t0, 3)})
        except Exception as error:  # noqa: BLE001
            predictions.append({"id": job["id"], "blocks": [], "error": f"{type(error).__name__}: {error}"})
        print(f"{len(predictions)}/{len(jobs)} {job['id']}", flush=True)

    Path(args.out).write_text(json.dumps({"load_seconds": round(load_seconds, 2), "options": {k: v for k, v in options.items()},
                                          "predictions": predictions}, ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
