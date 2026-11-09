"""Score a PP-FormulaNet_plus-S ONNX model on a formula list (Track A).

From tools/model_prep, with C:\\Projects\\Capstone\\paddle_onnx_env:
  python evaluate_formula.py --labels <root>\\splits\\<id>\\formula_eval.txt
  python evaluate_formula.py --labels ... --model C:\\path\\retrained.onnx --tag retrained

Default model: the app's (frontend/android/.../PP-FormulaNet_plus-S/pp-formulanet_plus-s.onnx).
Preprocessing and decoding are test_formulanet.py's (PaddleX UniMERNet
transforms, as ported to the app): crop margin, short side 384, fit in
384 x 384, black padding, gray, mean 0.7931 / std 0.1738; greedy ids from
the graph, GPT-2 byte-level tokenizer, PaddleX normalisation.

Metrics, overall, per topic (from names like radicals_cap_S_005.png or
fractions_pub_i2l-test_00012.png) and per formula length (LaTeX tokens;
"simple" = at most 20): exact match after removing delimiters and spaces
(the VL evaluator's comparison), and mean normalised edit distance.
compare_formula.py compares two runs. Output:
<root>/outputs/formula/<tag>/<date>_<model sha8>_<list>/ results.md,
results.csv, predictions.tsv.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import re
import sys
import time
from collections import defaultdict
from pathlib import Path

import numpy as np
import onnxruntime as ort
from PIL import Image, ImageOps

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "tools" / "training_vl"))
sys.path.insert(0, str(REPO / "tools" / "training"))

import test_formulanet as tf  # noqa: E402  (normalize, decode, load_tokenizer, constants)
import vl_common  # noqa: E402
from common import read_labels, root_dir, sha256_of  # noqa: E402

APP_MODEL = REPO / "frontend" / "android" / "app" / "src" / "main" / "assets" / "paddle_onnx" / "PP-FormulaNet_plus-S" / "pp-formulanet_plus-s.onnx"
TOKENIZERS = [
    Path(r"C:\Projects\Capstone\models\PP-FormulaNet_plus-S\pp-formulanet-tokenizer.json"),
    Path(r"C:\Projects\Capstone\PaddleOCR-official\ppocr\utils\dict\unimernet_tokenizer\tokenizer.json"),
]


def preprocess(path: Path) -> np.ndarray:
    """test_formulanet.preprocess without writing the debug image."""

    image = tf.crop_margin(ImageOps.exif_transpose(Image.open(path)).convert("RGB"))
    w, h = image.size
    size = tf.INPUT_SIZE
    new = (size, int(size * h / w)) if w <= h else (int(size * w / h), size)
    image = image.resize(new, resample=Image.BILINEAR)
    image.thumbnail((size, size))
    dw, dh = size - image.width, size - image.height
    image = ImageOps.expand(image, (dw // 2, dh // 2, dw - dw // 2, dh - dh // 2))
    arr = (np.asarray(image).astype(np.float32) / 255.0 - tf.MEAN) / tf.STD
    gray = arr[..., 0] * 0.299 + arr[..., 1] * 0.587 + arr[..., 2] * 0.114
    return gray[np.newaxis, np.newaxis].astype(np.float32)


def topic_of(name: str) -> str:
    """radicals_cap_S_005.png -> radicals; fractions_pub_i2l-test_00012.png -> fractions."""

    return re.split(r"_(?:ss|cap|pub)_", Path(name).name)[0]


SIMPLE_MAX_TOKENS = 20
TOKEN = re.compile(r"\\[A-Za-z]+|\\.|[{}^_]|[A-Za-z]|\d|[^\sA-Za-z\d]")  # algebra_filter.py's


def length_group(target: str) -> str:
    """Formula length in LaTeX tokens (algebra_filter.py's count)."""

    n = len(TOKEN.findall(target))
    if n <= SIMPLE_MAX_TOKENS:
        return f"length <={SIMPLE_MAX_TOKENS} (simple)"
    return "length 21-40" if n <= 40 else "length >40"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--labels", required=True, help="<image><TAB><latex>, paths relative to the file")
    parser.add_argument("--model", default=str(APP_MODEL))
    parser.add_argument("--tokenizer", help="tokenizer.json (default: the one the app's vocabulary came from)")
    parser.add_argument("--root")
    parser.add_argument("--tag", default="baseline")
    parser.add_argument("--threads", type=int, default=4, help="4 = the phone's setting")
    args = parser.parse_args()

    label_file = Path(args.labels)
    rows = read_labels(label_file)
    if not rows:
        raise SystemExit(f"No lines in {label_file}")
    tokenizer_path = Path(args.tokenizer) if args.tokenizer else next(p for p in TOKENIZERS if p.exists())
    tokenizer = tf.load_tokenizer(tokenizer_path)
    options = ort.SessionOptions()
    options.intra_op_num_threads = args.threads
    session = ort.InferenceSession(args.model, options, providers=["CPUExecutionProvider"])
    input_name = session.get_inputs()[0].name

    overall, by_topic, by_length, predictions, times = [], defaultdict(list), defaultdict(list), [], []
    for image, target in rows:
        start = time.perf_counter()
        ids = session.run(None, {input_name: preprocess(label_file.parent / image)})[0][0]
        times.append((time.perf_counter() - start) * 1000)
        latex, _ = tf.decode(tokenizer, ids)
        a, b = vl_common.normalize_for_compare("formula", target), vl_common.normalize_for_compare("formula", latex)
        score = (a == b, vl_common.normalized_edit_distance(a, b))
        overall.append(score)
        by_topic[topic_of(image)].append(score)
        by_length[length_group(target)].append(score)
        predictions.append((image, topic_of(image), target, latex, score[0], round(score[1], 4)))

    def row(name, scores):
        return {"group": name, "items": len(scores), "exact_pct": round(100 * sum(s[0] for s in scores) / len(scores), 1),
                "mean_ned": round(sum(s[1] for s in scores) / len(scores), 4)}

    table = ([row("ALL", overall)] + [row(t, s) for t, s in sorted(by_topic.items())]
             + [row(g, s) for g, s in sorted(by_length.items())])
    model_hash = sha256_of(Path(args.model))
    labels_hash = hashlib.sha256(label_file.read_bytes()).hexdigest()
    today = dt.date.today().isoformat()
    out = root_dir(args.root) / "outputs" / "formula" / args.tag / f"{today}_{model_hash[:8]}_{label_file.parent.name}-{label_file.stem}"
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "results.csv", "w", encoding="utf-8", newline="") as handle:
        handle.write(f"# date={today} model_sha256={model_hash} labels={label_file} labels_sha256={labels_hash}\n")
        writer = csv.DictWriter(handle, fieldnames=list(table[0]))
        writer.writeheader()
        writer.writerows(table)
    with open(out / "predictions.tsv", "w", encoding="utf-8", newline="\n") as handle:
        handle.write("image\ttopic\ttarget\tprediction\texact\tned\n")
        for p in predictions:
            handle.write("\t".join(str(v) for v in p) + "\n")
    lines = [f"# Formula results: {label_file.parent.name}/{label_file.name}", "",
             f"- Date: {today}", f"- Model: `{Path(args.model).name}` sha256 `{model_hash}`",
             f"- Tokenizer: `{tokenizer_path}`", f"- Items: {len(rows)}, labels sha256 `{labels_hash}`",
             f"- CPU, {args.threads} threads: median {sorted(times)[len(times) // 2]:.0f} ms per formula",
             "- Comparison: delimiters and spaces ignored (as evaluate_vl.py).", "",
             "| Group | Items | Exact % | Mean NED |", "|---|---|---|---|"]
    lines += [f"| {r['group']} | {r['items']} | {r['exact_pct']} | {r['mean_ned']} |" for r in table]
    (out / "results.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    print(f"\nWritten to {out}")


if __name__ == "__main__":
    main()
