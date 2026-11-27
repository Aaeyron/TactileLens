import sys
from collections import Counter

import onnx
import onnxruntime as ort

path = sys.argv[1]

model = onnx.load(path, load_external_data=False)
print("Model:", path)
print("Opsets:", ", ".join(f"{o.domain or 'ai.onnx'}:{o.version}" for o in model.opset_import))

ops = Counter(node.op_type for node in model.graph.node)
control = {op: n for op, n in ops.items() if op in ("Loop", "If", "Scan")}
print("Nodes:", sum(ops.values()), " control flow:", control or "none")

session = ort.InferenceSession(path, providers=["CPUExecutionProvider"])

print("\nINPUTS")
for item in session.get_inputs():
    print(f"  {item.name:30s} shape={item.shape}  type={item.type}")

print("\nOUTPUTS")
for item in session.get_outputs():
    print(f"  {item.name:30s} shape={item.shape}  type={item.type}")
