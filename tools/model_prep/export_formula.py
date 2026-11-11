"""Export a PP-FormulaNet_plus-S checkpoint to a static model that
paddle2onnx (2.0.2rc3, paddle_onnx_env) can convert, then to ONNX.

From tools/model_prep, with C:\\Projects\\Capstone\\paddle_formula_env:
  python export_formula.py --checkpoint <dir>\\best_accuracy --out <dir>

Why: Paddle 3.2.1 records Tensor.masked_fill_ as its own masked_fill
operator, which paddle2onnx 2.0.2rc3 cannot convert ("unsupported
operators"). The official inference model (exported with Paddle 3.0.0)
has where + full_like there instead. During export only, masked_fill and
masked_fill_ are written as paddle.where(mask, full_like(x, value), x),
which computes the same values. PaddleOCR's tools/export_model.py then
runs unchanged with the repo's config.

Output: <out>/infer/ (inference.json, .pdiparams, .yml) and
<out>/onnx/inference.onnx (PaddleX paddle2onnx, opset 17 requested).
"""

from __future__ import annotations

import argparse
import os
import runpy
import subprocess
import sys
from pathlib import Path

PADDLEOCR = Path(r"C:\Projects\Capstone\PaddleOCR-official")
CONFIG = PADDLEOCR / "configs" / "rec" / "PP-FormuaNet" / "PP-FormulaNet_plus-S.yaml"
ONNX_SCRIPTS = Path(r"C:\Projects\Capstone\paddle_onnx_env\Scripts")


def patch_masked_fill() -> None:
    import paddle

    def masked_fill(x, mask, value, name=None):
        return paddle.where(mask, paddle.full_like(x, value), x)

    def masked_fill_(x, mask, value, name=None):
        paddle.assign(masked_fill(x, mask, value), x)
        return x

    paddle.masked_fill = masked_fill
    # Eager tensors and the static-graph values export traces with.
    for cls in (paddle.Tensor, getattr(paddle.pir, "Value", None)):
        if cls is not None:
            cls.masked_fill = masked_fill
            cls.masked_fill_ = masked_fill_


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--checkpoint", required=True, help="checkpoint path without .pdparams")
    parser.add_argument("--out", required=True)
    parser.add_argument("--config", default=str(CONFIG))
    parser.add_argument("--no-onnx", action="store_true")
    args = parser.parse_args()

    out = Path(args.out).resolve()
    infer = out / "infer"
    if not args.no_onnx and (out / "onnx").exists():
        raise SystemExit(f"{out / 'onnx'} exists; choose another --out")

    patch_masked_fill()
    os.chdir(PADDLEOCR)
    sys.path.insert(0, str(PADDLEOCR))
    sys.argv = ["tools/export_model.py", "-c", args.config, "-o",
                f"Global.pretrained_model={args.checkpoint}", f"Global.save_inference_dir={infer}"]
    runpy.run_path(str(PADDLEOCR / "tools" / "export_model.py"), run_name="__main__")

    if args.no_onnx:
        return
    env = dict(os.environ, PATH=str(ONNX_SCRIPTS) + os.pathsep + os.environ.get("PATH", ""), PYTHONIOENCODING="utf-8")
    code = subprocess.run([str(ONNX_SCRIPTS / "paddlex.exe"), "--paddle2onnx", "--paddle_model_dir", str(infer),
                           "--onnx_model_dir", str(out / "onnx"), "--opset_version", "17"], env=env).returncode
    if code or not (out / "onnx" / "inference.onnx").exists():
        raise SystemExit(f"ONNX conversion failed (exit {code})")
    print(f"ONNX: {out / 'onnx' / 'inference.onnx'}")


if __name__ == "__main__":
    main()
