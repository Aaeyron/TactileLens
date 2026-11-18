"""PaddleOCR-VL label suggestions that survive an interruption.

Same pipeline and options as local_vl_worker.py (prompt mode), but every
reading is appended to a JSONL file at once, and images already in that file
are skipped, so a stopped run continues where it ended. Generation stops at
--max-new-tokens (default 300, far more than one formula needs; the pipeline's
own default of 4096 lets a confused reading run for minutes).

With --supervise the reading runs in a child process that is restarted when it
crashes (Paddle can die in native code). An image that is next in line for two
crashes in a row is recorded with an error and skipped.

  <paddleocr_vl_env python> suggest_vl_resumable.py --jobs jobs.json --out suggest_vl.jsonl
      [--first val_ids.txt] [--supervise]

jobs.json: [{"id": ..., "image": <path>, "prompt_label": "formula"}, ...]
--first:   ids (one per line) to read before the others.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

from local_vl_worker import blocks_of

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

MAX_RESTARTS = 200


def pending(jobs: list[dict], done: set[str], first: set[str]) -> list[dict]:
    todo = [j for j in jobs if j["id"] not in done]
    return sorted(todo, key=lambda j: j["id"] not in first)  # stable: listed order within each group


def read_done(path: Path) -> set[str]:
    if not path.exists():
        return set()
    data = path.read_bytes()
    if data and not data.endswith(b"\n"):  # a line cut off by an interruption
        path.write_bytes(data[: data.rfind(b"\n") + 1])
    done = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        try:
            done.add(json.loads(line)["id"])
        except (ValueError, KeyError):
            continue  # a line cut off by an interruption is read again
    return done


def after_crash(next_id: str, last_crash_id: str | None) -> tuple[bool, str]:
    """(skip this image?, the id to remember): skip on the second crash in a row at the same image."""
    return next_id == last_crash_id, next_id


def supervise(args, jobs: list[dict], first: set[str]) -> int:
    child = [sys.executable, str(Path(__file__).resolve()), "--jobs", str(args.jobs), "--out", str(args.out),
             "--device", args.device, "--max-new-tokens", str(args.max_new_tokens)]
    if args.first:
        child += ["--first", str(args.first)]
    last_crash = None
    for restart in range(MAX_RESTARTS):
        code = subprocess.run(child).returncode
        todo = pending(jobs, read_done(args.out), first)
        if not todo:
            print(f"finished after {restart} restarts", flush=True)
            return 0
        next_id = todo[0]["id"]
        skip, last_crash = after_crash(next_id, last_crash)
        print(f"child stopped (exit {code}); next image {next_id}", flush=True)
        if skip:
            with args.out.open("a", encoding="utf-8", newline="\n") as handle:
                handle.write(json.dumps({"id": next_id, "blocks": [], "error": f"pipeline crashed twice (exit {code})"}) + "\n")
            print(f"skipped {next_id}", flush=True)
            last_crash = None
        time.sleep(5)
    print("too many restarts", flush=True)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--jobs", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--first", type=Path)
    parser.add_argument("--device", default="gpu:0")
    parser.add_argument("--max-new-tokens", type=int, default=300)
    parser.add_argument("--supervise", action="store_true", help="restart after a crash; skip an image that crashes twice")
    args = parser.parse_args()

    jobs = json.loads(args.jobs.read_text(encoding="utf-8"))
    first = set(args.first.read_text(encoding="utf-8").split()) if args.first else set()
    if args.supervise:
        return supervise(args, jobs, first)
    todo = pending(jobs, read_done(args.out), first)
    print(f"{len(jobs)} jobs, {len(todo)} to do", flush=True)
    if not todo:
        return 0

    from paddleocr import PaddleOCRVL  # only in paddleocr_vl_env

    pipeline = PaddleOCRVL(pipeline_version="v1.6", device=args.device, engine="paddle", vl_rec_backend="native",
                           use_layout_detection=False, use_doc_orientation_classify=False,
                           use_doc_unwarping=False, use_queues=False)
    with args.out.open("a", encoding="utf-8", newline="\n") as handle:
        for n, job in enumerate(todo, 1):
            started = time.perf_counter()
            try:
                results = pipeline.predict(input=job["image"], use_layout_detection=False,
                                           prompt_label=job["prompt_label"], use_queues=False,
                                           max_new_tokens=args.max_new_tokens)
                row = {"id": job["id"], "blocks": [b for r in results for b in blocks_of(r)],
                       "seconds": round(time.perf_counter() - started, 3)}
            except Exception as error:  # noqa: BLE001  (recorded; the image is not retried)
                row = {"id": job["id"], "blocks": [], "error": f"{type(error).__name__}: {error}"}
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
            handle.flush()
            if n % 25 == 0:
                print(f"{n}/{len(todo)}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
