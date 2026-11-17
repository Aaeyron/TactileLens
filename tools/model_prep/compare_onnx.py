"""Compare two ONNX models: inputs/outputs, opset, operator counts (incl.
the decoding Loop), weights (by value, names ignored) and, optionally,
the token ids they produce on the same formula images.

From tools/model_prep, with C:\\Projects\\Capstone\\paddle_onnx_env:
  python compare_onnx.py A.onnx B.onnx [--images <formula list or folder>] [--limit 50]

Weights: every initializer (also inside Loop/If bodies) is hashed by
dtype, shape and bytes; the two multisets are compared, so renamed
tensors still match. Outputs: the greedy token ids from both models on
each image (preprocessing of evaluate_formula.py).
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path

import numpy as np
import onnx
from onnx import numpy_helper


def graphs(graph):
    yield graph
    for node in graph.node:
        for attr in node.attribute:
            if attr.type == onnx.AttributeProto.GRAPH:
                yield from graphs(attr.g)
            elif attr.type == onnx.AttributeProto.GRAPHS:
                for g in attr.graphs:
                    yield from graphs(g)


def describe(path: Path) -> dict:
    model = onnx.load(str(path))
    ops, weights = Counter(), Counter()
    for g in graphs(model.graph):
        ops.update(n.op_type for n in g.node)
        for init in g.initializer:
            array = numpy_helper.to_array(init)
            weights[(str(array.dtype), array.shape, hashlib.sha256(array.tobytes()).hexdigest())] += 1
    for g in graphs(model.graph):  # Constant nodes holding tensors
        for n in g.node:
            if n.op_type == "Constant":
                for attr in n.attribute:
                    if attr.type == onnx.AttributeProto.TENSOR:
                        array = numpy_helper.to_array(attr.t)
                        if array.size > 16:
                            weights[(str(array.dtype), array.shape, hashlib.sha256(array.tobytes()).hexdigest())] += 1
    io = lambda vs: [[v.name, [d.dim_param or d.dim_value for d in v.type.tensor_type.shape.dim], v.type.tensor_type.elem_type] for v in vs]  # noqa: E731
    return {
        "inputs": io(model.graph.input), "outputs": io(model.graph.output),
        "opset": {o.domain or "ai.onnx": o.version for o in model.opset_import},
        "ops": ops, "weights": weights,
        "weight_values": sum(int(np.prod(shape)) * count for (_, shape, _), count in weights.items()),
    }


def token_ids(model_path: Path, images: list[Path]) -> list[list[int]]:
    import onnxruntime as ort

    from evaluate_formula import preprocess

    options = ort.SessionOptions()
    options.intra_op_num_threads = 4
    session = ort.InferenceSession(str(model_path), options, providers=["CPUExecutionProvider"])
    name = session.get_inputs()[0].name
    return [[int(i) for i in session.run(None, {name: preprocess(p)})[0][0]] for p in images]


def image_list(source: Path, limit: int) -> list[Path]:
    if source.is_dir():
        found = sorted(p for p in source.rglob("*") if p.suffix.lower() in (".png", ".jpg", ".jpeg"))
    else:
        found = [source.parent / line.split("\t")[0] for line in source.read_text(encoding="utf-8").splitlines() if line.strip()]
    return found[:limit]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("a")
    parser.add_argument("b")
    parser.add_argument("--images", help="a label list (<image><TAB>...) or a folder of formula images")
    parser.add_argument("--limit", type=int, default=50)
    parser.add_argument("--json", help="write the comparison here")
    args = parser.parse_args()

    a, b = describe(Path(args.a)), describe(Path(args.b))
    result = {
        "same_inputs_outputs": [(n, s, t) for n, s, t in a["inputs"]] == [(n, s, t) for n, s, t in b["inputs"]]
                               and [(len(s), t) for _, s, t in a["outputs"]] == [(len(s), t) for _, s, t in b["outputs"]],
        "inputs": {"a": a["inputs"], "b": b["inputs"]}, "outputs": {"a": a["outputs"], "b": b["outputs"]},
        "opset": {"a": a["opset"], "b": b["opset"]},
        "loop_ops": {"a": a["ops"].get("Loop", 0), "b": b["ops"].get("Loop", 0)},
        "node_count": {"a": sum(a["ops"].values()), "b": sum(b["ops"].values())},
        "ops_differ": {op: (a["ops"].get(op, 0), b["ops"].get(op, 0)) for op in sorted(set(a["ops"]) | set(b["ops"]))
                       if a["ops"].get(op, 0) != b["ops"].get(op, 0)},
        "weight_tensors": {"a": sum(a["weights"].values()), "b": sum(b["weights"].values())},
        "weight_values": {"a": a["weight_values"], "b": b["weight_values"]},
        "weights_identical": a["weights"] == b["weights"],
        "weight_tensors_only_in_a": sum((a["weights"] - b["weights"]).values()),
        "weight_tensors_only_in_b": sum((b["weights"] - a["weights"]).values()),
    }
    if args.images:
        images = image_list(Path(args.images), args.limit)
        ids_a, ids_b = token_ids(Path(args.a), images), token_ids(Path(args.b), images)
        same = [x == y for x, y in zip(ids_a, ids_b)]
        result["images_compared"] = len(images)
        result["identical_token_ids"] = sum(same)
        result["first_difference"] = next((str(images[i]) for i, s in enumerate(same) if not s), None)
    text = json.dumps(result, indent=1, default=str)
    print(text)
    if args.json:
        Path(args.json).write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
