"""Export the PP-FormulaNet tokenizer vocabulary for Android and verify
that a simple byte-level decode (the same logic the Kotlin code will use)
matches the real Hugging Face tokenizer.

Usage (from C:\\Projects\\Capstone\\models, in the .venv):
    python export_formula_vocab.py test_images\\sqrt2_crop.png
"""
import json
import sys
from pathlib import Path

import onnxruntime as ort

import test_formulanet as tf  # reuse MODEL, TOKENIZER, preprocess, EOS_ID

HERE = Path(__file__).resolve().parent
OUT = HERE / "PP-FormulaNet_plus-S" / "pp-formulanet_vocab.json"


def bytes_to_unicode():
    """GPT-2 byte-level mapping (byte -> printable unicode char)."""
    bs = (
        list(range(ord("!"), ord("~") + 1))
        + list(range(ord("\u00a1"), ord("\u00ac") + 1))
        + list(range(ord("\u00ae"), ord("\u00ff") + 1))
    )
    cs = bs[:]
    n = 0
    for b in range(256):
        if b not in bs:
            bs.append(b)
            cs.append(256 + n)
            n += 1
    return dict(zip(bs, [chr(c) for c in cs]))


def main():
    data = json.loads(tf.TOKENIZER.read_text(encoding="utf-8"))
    if "fast_tokenizer_file" in data:
        data = data["fast_tokenizer_file"]

    model = data.get("model", {})
    print("Tokenizer model type:", model.get("type"))
    print("Decoder:", json.dumps(data.get("decoder"))[:300])

    vocab = model.get("vocab")
    if not isinstance(vocab, dict):
        print("Vocab is not a token->id map; send this output to Claude.")
        sys.exit(1)

    added = data.get("added_tokens", [])
    size = max(
        max(vocab.values()),
        max((t["id"] for t in added), default=0),
    ) + 1

    tokens = [""] * size
    for token, index in vocab.items():
        tokens[index] = token

    special_ids = []
    for token in added:
        tokens[token["id"]] = token["content"]
        if token.get("special"):
            special_ids.append(token["id"])

    print("Vocab size:", size)
    print("Special token ids:", special_ids, [tokens[i] for i in special_ids])

    OUT.write_text(
        json.dumps({"tokens": tokens, "special_ids": special_ids}, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"Wrote {OUT} ({OUT.stat().st_size / 1e6:.2f} MB)")

    if len(sys.argv) < 2:
        print("\n(No image given - skipped the decode check.)")
        return

    tokenizer = tf.load_tokenizer(tf.TOKENIZER)
    session = ort.InferenceSession(str(tf.MODEL), providers=["CPUExecutionProvider"])
    x = tf.preprocess(sys.argv[1])
    ids = [int(i) for i in session.run(None, {session.get_inputs()[0].name: x})[0][0]]
    if tf.EOS_ID in ids:
        ids = ids[: ids.index(tf.EOS_ID) + 1]

    byte_decoder = {char: byte for byte, char in bytes_to_unicode().items()}
    joined = "".join(tokens[i] for i in ids if i not in special_ids)
    simple = bytes(
        byte_decoder[ch] if ch in byte_decoder else ord(ch) & 0xFF for ch in joined
    ).decode("utf-8", errors="replace")
    real = tokenizer.decode(ids, skip_special_tokens=True)

    print("\nToken ids:", ids)
    print("Real decode:  ", repr(real))
    print("Simple decode:", repr(simple))
    print("RESULT:", "MATCH" if simple == real else "DIFFERENT")


if __name__ == "__main__":
    main()