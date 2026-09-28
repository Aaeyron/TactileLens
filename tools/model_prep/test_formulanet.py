"""Test PP-FormulaNet_plus-S (ONNX) on one formula image.

Usage:  python test_formulanet.py path\\to\\formula.png
Preprocessing/decoding follow PaddleX's UniMERNetImgDecode,
UniMERNetTestTransform, UniMERNetImageFormat and UniMERNetDecode.
"""
import json
import re
import sys
import time
from pathlib import Path

import numpy as np
import onnxruntime as ort
from PIL import Image, ImageOps
from tokenizers import Tokenizer

HERE = Path(__file__).resolve().parent
MODEL = HERE / "PP-FormulaNet_plus-S" / "pp-formulanet_plus-s.onnx"
TOKENIZER = HERE / "PP-FormulaNet_plus-S" / "pp-formulanet-tokenizer.json"

INPUT_SIZE = 384
MEAN = 0.7931
STD = 0.1738
EOS_ID = 2


def crop_margin(img):
    data = np.array(img.convert("L")).astype(np.float32)
    lo, hi = data.min(), data.max()
    if hi == lo:
        return img
    data = (data - lo) / (hi - lo) * 255
    ys, xs = np.nonzero(data < 200)
    if len(xs) == 0:
        return img
    return img.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))


def preprocess(path):
    img = Image.open(path).convert("RGB")
    img = crop_margin(img)
    w, h = img.size
    # Resize so the SHORT side is 384, then shrink to fit inside 384x384.
    if w <= h:
        new_w, new_h = INPUT_SIZE, int(INPUT_SIZE * h / w)
    else:
        new_w, new_h = int(INPUT_SIZE * w / h), INPUT_SIZE
    img = img.resize((new_w, new_h), resample=Image.BILINEAR)
    img.thumbnail((INPUT_SIZE, INPUT_SIZE))
    dw, dh = INPUT_SIZE - img.width, INPUT_SIZE - img.height
    padding = (dw // 2, dh // 2, dw - dw // 2, dh - dh // 2)
    img = ImageOps.expand(img, padding)  # black border, same as PaddleX
    img.save(HERE / "last_formula_input.png")  # what the model actually sees

    arr = np.asarray(img).astype(np.float32) / 255.0
    arr = (arr - MEAN) / STD
    gray = arr[..., 0] * 0.299 + arr[..., 1] * 0.587 + arr[..., 2] * 0.114
    return gray[np.newaxis, np.newaxis, :, :].astype(np.float32)


TEXT_REG = r"(\\(operatorname|mathrm|text|mathbf)\s?\*? {.*?})"
LETTER = r"[a-zA-Z]"
NOLETTER = r"[\W_^\d]"


def normalize(s):
    names = []
    for x in re.findall(TEXT_REG, s):
        pattern = r"(\\[a-zA-Z]+)\s(?=\w)|\\[a-zA-Z]+\s(?=})"
        for m in re.findall(pattern, x[0]):
            if m not in ["\\operatorname", "\\mathrm", "\\text", "\\mathbf"] and m.strip() != "":
                s = s.replace(m, m + "XXXXXXX")
                s = s.replace(" ", "")
                names.append(s)
    if names:
        s = re.sub(TEXT_REG, lambda match: str(names.pop(0)), s)
    news = s
    while True:
        s = news
        news = re.sub(r"(?!\\ )(%s)\s+?(%s)" % (NOLETTER, NOLETTER), r"\1\2", s)
        news = re.sub(r"(?!\\ )(%s)\s+?(%s)" % (NOLETTER, LETTER), r"\1\2", news)
        news = re.sub(r"(%s)\s+?(%s)" % (LETTER, NOLETTER), r"\1\2", news)
        if news == s:
            break
    return s.replace("XXXXXXX", " ")


def load_tokenizer(path):
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if "fast_tokenizer_file" in data:
        data = data["fast_tokenizer_file"]
    return Tokenizer.from_str(json.dumps(data))


def decode(tokenizer, ids):
    ids = [int(i) for i in ids]
    if EOS_ID in ids:
        ids = ids[: ids.index(EOS_ID) + 1]
    return normalize(tokenizer.decode(ids, skip_special_tokens=True)), len(ids)


def main():
    if len(sys.argv) != 2:
        print("Usage: python test_formulanet.py path\\to\\formula.png")
        sys.exit(1)

    options = ort.SessionOptions()
    options.intra_op_num_threads = 4  # same as the phone

    t0 = time.perf_counter()
    session = ort.InferenceSession(str(MODEL), options, providers=["CPUExecutionProvider"])
    tokenizer = load_tokenizer(TOKENIZER)
    print(f"Load: {(time.perf_counter() - t0) * 1000:.0f} ms")

    x = preprocess(sys.argv[1])
    input_name = session.get_inputs()[0].name

    latex = ""
    for run in range(1, 4):
        t1 = time.perf_counter()
        ids = session.run(None, {input_name: x})[0][0]
        ms = (time.perf_counter() - t1) * 1000
        latex, count = decode(tokenizer, ids)
        print(f"Run {run}: {ms:.0f} ms, {count} tokens")

    print("\nLaTeX:", latex)
    print("Model input saved to:", HERE / "last_formula_input.png")


if __name__ == "__main__":
    main()
