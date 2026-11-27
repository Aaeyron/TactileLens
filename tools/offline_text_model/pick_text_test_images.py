"""Choose the source images of the frozen text test sets, before any line is labeled.

From tools/offline_text_model (any Python 3):
  python pick_text_test_images.py --working <root>\\datasets\\own\\working\\20261118_all

T and W images only (M images are mostly formulas). For each topic x ss/cap
stratum, --eval-per-stratum images go to eval and --val-per-stratum to
validation, drawn with a fixed seed. Every line of these images is held out:
no line of a test image is ever used for training. Writes
<working>/text_lines_mtw/test_sources.json and test_sources.txt (the names, to
cut them first). Refuses to overwrite an existing choice.
"""

from __future__ import annotations

import argparse
import json
import random
import re
from collections import defaultdict
from pathlib import Path

NAME = re.compile(r"^(?P<topic>.+?)_(?P<source>cap|ss)_(?P<kind>[TW])_\d+\.\w+$")
SEED = 20261119


def pick(names: list[str], eval_n: int, val_n: int, seed: int = SEED) -> dict[str, list[str]]:
    strata = defaultdict(list)
    for name in sorted(names):
        if m := NAME.match(name):
            strata[(m["topic"], m["source"])].append(name)
    rng = random.Random(seed)
    chosen = {"eval": [], "val": []}
    for key in sorted(strata):
        group = strata[key][:]
        rng.shuffle(group)
        chosen["eval"] += sorted(group[:eval_n])
        chosen["val"] += sorted(group[eval_n:eval_n + val_n])
    return chosen


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--working", required=True)
    parser.add_argument("--eval-per-stratum", type=int, default=4)
    parser.add_argument("--val-per-stratum", type=int, default=5)
    args = parser.parse_args()
    working = Path(args.working)
    out = working / "text_lines_mtw"
    target = out / "test_sources.json"
    if target.exists():
        raise SystemExit(f"{target} exists: the test images are already chosen")
    chosen = pick([p.name for p in (working / "images").iterdir()], args.eval_per_stratum, args.val_per_stratum)
    out.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps({"seed": SEED, **chosen}, indent=1), encoding="utf-8")
    (out / "test_sources.txt").write_text("\n".join(chosen["eval"] + chosen["val"]) + "\n", encoding="utf-8")
    print(f"eval {len(chosen['eval'])} images, validation {len(chosen['val'])} images -> {target}")


if __name__ == "__main__":
    main()
