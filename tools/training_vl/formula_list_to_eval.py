"""A formula list (<image><TAB><latex>, the Track A format) -> the eval set
evaluate_vl.py reads (eval.jsonl + eval_meta.jsonl), so the online model is
scored on exactly the images and targets the offline formula model was.

  python formula_list_to_eval.py --labels <list.txt> --out <folder>

Image names follow topic_source_kind_number (e.g.
fractions_pub_i2l-test_00012.png); topic, source and kind come from the
name. Image links are absolute. The folder must not exist yet.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

from vl_common import DEFAULT_CONFIG, load_config

NAME = re.compile(r"(?P<topic>.+?)_(?P<source>ss|cap|pub)_(?P<kind>[^_]+)_")


def parse_name(name: str) -> dict:
    match = NAME.match(Path(name).name)
    if not match:
        raise ValueError(f"{name}: expected topic_source_kind_number")
    return match.groupdict()


def build(labels: Path, prompt: str) -> tuple[list[dict], list[dict]]:
    records, metas = [], []
    for line in labels.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        image, target = line.split("\t", 1)
        path = (labels.parent / image).resolve()
        records.append({"image_info": [{"matched_text_index": 0, "image_url": str(path)}],
                        "text_info": [{"text": prompt, "tag": "mask"}, {"text": target, "tag": "no_mask"}]})
        metas.append({"filename": image, **parse_name(image), "task": "formula",
                      "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    return records, metas


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--labels", required=True, help="<image><TAB><latex>, image paths relative to the file")
    parser.add_argument("--out", required=True)
    parser.add_argument("--config", default=str(DEFAULT_CONFIG))
    args = parser.parse_args()
    out = Path(args.out)
    if out.exists():
        raise SystemExit(f"{out} exists; choose a new folder")
    records, metas = build(Path(args.labels), load_config(Path(args.config))["tasks"]["formula"]["prompt"])
    if not records:
        raise SystemExit("no lines in the list")
    out.mkdir(parents=True)
    for name, rows in (("eval.jsonl", records), ("eval_meta.jsonl", metas)):
        (out / name).write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8",
                                newline="\n")
    print(f"{len(records)} items -> {out}")


if __name__ == "__main__":
    main()
