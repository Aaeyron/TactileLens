"""The 35-block Braille baseline of the AI service.

Runs 11 self-written blocks and every block of the four saved hosted-API
test pages (paddleocr-api-test/results/*/*/raw.jsonl) through one copy of
the AI service's own block code (PaddleOcrVlService._serialize_block) and
records, per block, the input, the display text, the Braille and whether it
is held. Comparing two runs shows whether a change moved any Braille.

This is the comparison used since October 2026 (first in a scratchpad
script, recovered on 2026-11-17); the inputs and the block code path are
unchanged.

Usage (from the repo root):
  python -m tools.braille_check.baseline35 run  <ai_service dir> <out.json>
         [--kit <paddleocr-api-test/results>] [--liblouis <liblouis root>]
  python -m tools.braille_check.baseline35 compare <before.json> <after.json>

<ai_service dir> can be a git worktree of another branch. The test pages
are not in this repository (they are from the hosted service); without
them only the 11 self-written blocks run.
"""

import argparse
import json
import os
import subprocess
import sys
import types
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DEFAULT_KIT = REPO.parent / "paddleocr-api-test" / "results"
DEFAULT_LIBLOUIS = REPO / "ai_service" / "vendor" / "liblouis"

# Order matters: the keys are self/0 ... self/10 in this order.
SELF_WRITTEN = [
    ("display_formula", r"$$ \begin{aligned}x+1&=4\\x&=3\end{aligned} $$"),
    ("display_formula", r"$$ f^{\prime}(x)=2x $$"),
    ("display_formula", r"$$ \bigg(\frac{a}{b}\bigg)^{2} $$"),
    ("display_formula", r"$$ x=1\quad y=2 $$"),
    ("display_formula", r"$$ \textbf{A}=\mbox{area} $$"),
    ("display_formula", r"$$ \left(x\right)+1 $$"),
    (
        "display_formula",
        r"$$ Example: Perform the division and simplify your answer. "
        r"\frac{2\sqrt{5}-4}{7} $$",
    ),
    (
        "display_formula",
        r"$$ \text{Example: Perform the division.} \quad \frac{2\sqrt{5}-4}{7} $$",
    ),
    ("text", r"Read \textbf{all} questions and simplify $\sqrt{2}$ first."),
    ("display_formula", r"$$ \mathrm{cm}=10 $$"),
    (
        "table",
        "<table><tr><td>Input</td><td>A</td><td>1</td></tr>"
        "<tr><td>Output</td><td>B</td><td></td></tr>"
        "<tr><td></td><td></td><td></td></tr></table>",
    ),
]


def kit_blocks(kit: Path):
    """(key, block) for every block of the saved hosted-API pages."""

    for raw in sorted(kit.glob("*/*/raw.jsonl")):
        page = json.loads(raw.read_text(encoding="utf-8"))["result"][
            "layoutParsingResults"
        ][0]["prunedResult"]

        for index, block in enumerate(page["parsing_res_list"]):
            yield f"{raw.parent.name}/{index}", block


def run_in_process(service_dir: Path, liblouis_root: Path, kit: Path) -> dict:
    """Run the blocks with the AI service code in [service_dir].

    Call it in a fresh process (see run()): the service's modules are
    imported from [service_dir] and must not be mixed with another copy.
    """

    os.environ["LIBLOUIS_ROOT"] = str(liblouis_root)
    sys.path.insert(0, str(service_dir))

    stub = types.ModuleType("paddleocr")
    stub.PaddleOCRVL = object
    sys.modules.setdefault("paddleocr", stub)

    from services.braille.braille_translation_service import (
        BrailleTranslationService,
    )
    from services.ocr.paddleocr_vl_service import PaddleOcrVlService

    service = PaddleOcrVlService.__new__(PaddleOcrVlService)
    service.debug_blocks = False
    service._braille_translator = BrailleTranslationService()

    def record(content, block):
        return {
            "input": content,
            "normalized": block["normalized_content"],
            "braille": block["braille_content"],
            "held": block.get("needs_review", False),
        }

    results = {}

    for index, (label, content) in enumerate(SELF_WRITTEN):
        block = service._serialize_block(
            {"block_label": label, "block_content": content},
            fallback_id=index,
            fallback_order=index,
        )
        results[f"self/{index}"] = record(content, block)

    for key, block in kit_blocks(kit):
        index = int(key.rsplit("/", 1)[1])
        serialized = service._serialize_block(
            block, fallback_id=index, fallback_order=index
        )
        results[key] = record(block["block_content"], serialized)

    return results


def run(service_dir: Path, out: Path, kit: Path, liblouis_root: Path) -> dict:
    """Run in a separate Python process and write [out]."""

    code = (
        "import json, sys\n"
        "from pathlib import Path\n"
        "from tools.braille_check.baseline35 import run_in_process\n"
        "r = run_in_process(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))\n"
        "Path(sys.argv[4]).write_text(json.dumps(r, ensure_ascii=False), encoding='utf-8')\n"
    )
    subprocess.run(
        [sys.executable, "-B", "-c", code, str(service_dir), str(liblouis_root), str(kit), str(out)],
        cwd=REPO,
        check=True,
    )
    return json.loads(out.read_text(encoding="utf-8"))


def compare(before: dict, after: dict) -> dict:
    """What changed between two runs, by kind."""

    if before.keys() != after.keys():
        raise ValueError("The two runs have different blocks.")

    return {
        "braille_changed": [
            key
            for key in before
            if not after[key]["held"]
            and not before[key]["held"]
            and before[key]["braille"] != after[key]["braille"]
        ],
        "newly_held": [
            key for key in before if after[key]["held"] and not before[key]["held"]
        ],
        "no_longer_held": [
            key for key in before if before[key]["held"] and not after[key]["held"]
        ],
        "text_changed": [
            key
            for key in before
            if before[key]["normalized"] != after[key]["normalized"]
        ],
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    run_parser = commands.add_parser("run")
    run_parser.add_argument("service_dir", type=Path)
    run_parser.add_argument("out", type=Path)
    run_parser.add_argument("--kit", type=Path, default=DEFAULT_KIT)
    run_parser.add_argument("--liblouis", type=Path, default=DEFAULT_LIBLOUIS)

    compare_parser = commands.add_parser("compare")
    compare_parser.add_argument("before", type=Path)
    compare_parser.add_argument("after", type=Path)

    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    if args.command == "run":
        results = run(args.service_dir, args.out, args.kit, args.liblouis)
        held = sum(entry["held"] for entry in results.values())
        print(f"{len(results)} blocks, {held} held -> {args.out}")
    else:
        load = lambda path: json.loads(path.read_text(encoding="utf-8"))  # noqa: E731
        changes = compare(load(args.before), load(args.after))

        for kind, keys in changes.items():
            print(f"{kind}: {len(keys)} {keys if keys else ''}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
