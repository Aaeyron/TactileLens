"""Offline formula-model readings of the formula crops, with or without confidence.

The ORIGINAL model (not a fine-tuned one), so its readings stay independent of
the PaddleOCR-VL labels that the fine-tuned models learned from.

  --engine paddle  the original checkpoint in PaddleOCR (paddle_formula_env, GPU),
                   evaluation transforms of the given run's config; gives each
                   symbol's probability ("weakest" = the lowest one)
  --engine onnx    the app's ONNX file with the app's preprocessing
                   (paddle_onnx_env, CPU); no confidence

  python suggest_crop_labels.py --engine paddle --crops <crops_mtw> --run <run folder> [--limit 100]

Appends one JSON line per crop to <crops>/offline_<engine>.jsonl and skips crops
already there, so a stopped run continues.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def crop_names(crops: Path, limit: int | None) -> list[str]:
    with (crops / "crops.csv").open(encoding="utf-8", newline="") as handle:
        names = [r["crop"] for r in csv.DictReader(handle)]
    return names[:: max(len(names) // limit, 1)][:limit] if limit else names


def done_names(path: Path) -> set[str]:
    if not path.exists():
        return set()
    data = path.read_bytes()
    if data and not data.endswith(b"\n"):  # a line cut off by an interruption
        path.write_bytes(data[: data.rfind(b"\n") + 1])
    return {json.loads(line)["crop"] for line in path.read_text(encoding="utf-8").splitlines() if line.strip()}


def paddle_reader(run: Path):
    from finetune_changes import PADDLEOCR, run_paths, sequence_confidence, trim_at_eos

    weights, config_path = run_paths(run)["before"], run_paths(run)["config"]
    os.chdir(PADDLEOCR)
    sys.path.insert(0, str(PADDLEOCR))
    import numpy as np
    import paddle
    import ppocr.data.imaug.unimernet_aug as aug
    aug.Snow.apply = lambda self, img, **params: img
    from ppocr.data import create_operators, transform
    from ppocr.modeling.architectures import build_model
    from ppocr.postprocess import build_post_process
    from tools.program import load_config

    paddle.set_device("gpu")
    config = load_config(str(config_path))
    ops = [op for op in config["Eval"]["dataset"]["transforms"]
           if not any(k in op for k in ("UniMERNetLabelEncode", "KeepKeys"))] + [{"KeepKeys": {"keep_keys": ["image"]}}]
    ops = create_operators(ops, config["Global"])
    post = build_post_process(config["PostProcess"], config["Global"])
    model = build_model(config["Architecture"])
    model.set_state_dict(paddle.load(str(weights)))
    model.eval()
    head, steps = model.head, []
    processor = head.logits_processor

    def record(input_ids, scores):
        scores = processor(input_ids, scores)
        steps.append(paddle.nn.functional.softmax(scores.astype("float32"), axis=-1).max(axis=-1).numpy())
        return scores

    head.logits_processor = record

    def read(path: Path) -> dict:
        with open(path, "rb") as handle:
            batch = transform({"img_path": str(path), "filename": str(path), "label": "x", "image": handle.read()}, ops)
        steps.clear()
        with paddle.no_grad():
            ids = np.array(model(paddle.to_tensor(np.expand_dims(batch[0], 0))))
        probs = np.concatenate([s.reshape(1, -1) for s in steps], axis=1)[0].tolist()
        tokens, probs = trim_at_eos(ids[0, -len(probs):].tolist(), probs)
        confidence = sequence_confidence(probs)
        return {"prediction": post(ids)[0], "weakest": round(confidence["weakest"], 5),
                "geomean": round(confidence["geomean"], 5), "tokens": confidence["tokens"]}

    return read, str(weights)


def onnx_reader(threads: int):
    import onnxruntime as ort

    import evaluate_formula as ef

    options = ort.SessionOptions()
    options.intra_op_num_threads = threads
    options.enable_cpu_mem_arena = False
    session = ort.InferenceSession(str(ef.APP_MODEL), options, providers=["CPUExecutionProvider"])
    tokenizer = ef.tf.load_tokenizer(next(p for p in ef.TOKENIZERS if p.exists()))
    name = session.get_inputs()[0].name

    def read(path: Path) -> dict:
        ids = session.run(None, {name: ef.preprocess(path)})[0][0]
        return {"prediction": ef.tf.decode(tokenizer, ids)[0]}

    return read, str(ef.APP_MODEL)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--engine", required=True, choices=["paddle", "onnx"])
    parser.add_argument("--crops", required=True, type=Path)
    parser.add_argument("--run", type=Path, help="a Track A run folder (paddle: its config and pretrained weights)")
    parser.add_argument("--threads", type=int, default=4)
    parser.add_argument("--limit", type=int, help="only this many crops, spread over the list (timing)")
    parser.add_argument("--out", type=Path, help="default: <crops>/offline_<engine>.jsonl")
    args = parser.parse_args()
    crops = args.crops.resolve()
    out = (args.out or crops / f"offline_{args.engine}.jsonl").resolve()
    names = crop_names(crops, args.limit)
    done = done_names(out)
    todo = [n for n in names if n not in done]
    read, model = paddle_reader(args.run.resolve()) if args.engine == "paddle" else onnx_reader(args.threads)
    print(f"{args.engine}: {model}; {len(todo)} of {len(names)} crops to read", flush=True)
    started = time.perf_counter()
    with out.open("a", encoding="utf-8", newline="\n") as handle:
        for n, name in enumerate(todo, 1):
            t = time.perf_counter()
            try:
                row = {"crop": name, **read(crops / "images" / name)}
            except Exception as error:  # noqa: BLE001  (recorded, not retried)
                row = {"crop": name, "error": f"{type(error).__name__}: {error}"}
            row["seconds"] = round(time.perf_counter() - t, 4)
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
            handle.flush()
            if n % 500 == 0:
                rate = (time.perf_counter() - started) / n
                print(f"{n}/{len(todo)}  {rate:.3f} s per crop  about {(len(todo) - n) * rate / 60:.0f} min left", flush=True)
    print(f"finished: {len(todo)} crops in {time.perf_counter() - started:.0f} s", flush=True)


if __name__ == "__main__":
    main()
