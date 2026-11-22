"""Phone bench for PaddleOCR-VL 1.6 GGUF (Q4_K_M + vision Q8_0) with llama.cpp on Android:
GPU (Vulkan) vs CPU, per formula crop and per whole layout block. Bench only, not the app.

The phone runs llama-server (built by build_android_vulkan.bat) from /data/local/tmp/vlbench;
this PC sends the images over adb port forwarding, with the same prompts and per-block pixel
limits as the online pipeline. Logged per request: wall time and the server's prompt/predict
times. Logged every second: the server's VmRSS/VmHWM, battery temperature and level, CPU/GPU
thermal zones the shell can read.

  python phone_bench.py info                       device, SoC, GPU, free space
  python phone_bench.py push                       binaries + model files (about 970 MB)
  python phone_bench.py run --mode gpu|cpu         formulas + blocks, results in results/<mode>/
  python phone_bench.py report                     per-formula / per-block / per-page estimates

Uses only %LOCALAPPDATA%\\Android\\Sdk\\platform-tools\\adb.exe.
"""
import argparse
import base64
import json
import os
import statistics
import subprocess
import threading
import time
import urllib.request
from pathlib import Path

import cv2

ADB = Path(os.environ["LOCALAPPDATA"]) / "Android" / "Sdk" / "platform-tools" / "adb.exe"
HERE = Path(__file__).parent
RESULTS = Path(r"C:\Projects\Capstone\vl_gguf\android\results")
GGUF = Path(r"C:\Projects\Capstone\vl_gguf")
ANDROID_BIN = GGUF / "android" / "bin"
EVAL = Path(r"C:\Projects\Capstone\tactilelens-training\evaluations\vl_gguf_20261122")
REMOTE = "/data/local/tmp/vlbench"
PORT = 8094
LLM = "paddleocr-vl-1.6-q4_k_m.gguf"
MMPROJ = "paddleocr-vl-1.6-mmproj-q8_0.gguf"
FORMULA_TOKENS = 512  # stage 2 choice
PIXELS_PER_TOKEN = 28 * 28
THREADS = 4


def adb(*args, check=True, timeout=600):
    r = subprocess.run([str(ADB), *args], capture_output=True, text=True, timeout=timeout)
    if check and r.returncode != 0:
        raise SystemExit(f"adb {' '.join(args)} failed: {r.stderr.strip()}")
    return r.stdout.strip()


def shell(cmd, check=True, timeout=600):
    return adb("shell", cmd, check=check, timeout=timeout)


def info():
    props = {k: shell(f"getprop {k}", check=False) for k in
             ("ro.product.model", "ro.soc.manufacturer", "ro.soc.model", "ro.hardware", "ro.board.platform",
              "ro.build.version.release")}
    gles = shell("dumpsys SurfaceFlinger | grep -i GLES | head -1", check=False)
    vulkan = shell("cmd gpu vkjson 2>/dev/null | head -c 400", check=False)
    mem = shell("grep -E 'MemTotal|MemAvailable' /proc/meminfo", check=False)
    free = shell("df -h /data | tail -1", check=False)
    out = {**props, "gles": gles, "vulkan": vulkan[:400], "meminfo": mem, "data_free": free}
    print(json.dumps(out, indent=1))
    return out


def push():
    shell(f"mkdir -p {REMOTE}")
    for f in (ANDROID_BIN / "llama-server", ANDROID_BIN / "llama-mtmd-cli", GGUF / LLM, GGUF / MMPROJ):
        print("push", f.name, round(f.stat().st_size / 2**20), "MB", flush=True)
        adb("push", str(f), f"{REMOTE}/{f.name}", timeout=1800)
    shell(f"chmod 755 {REMOTE}/llama-server {REMOTE}/llama-mtmd-cli")
    print(shell(f"ls -l {REMOTE}"))


def bench_items():
    """30 app-style formula crops, then up to 20 each of online-style formula blocks, text blocks
    the hybrid (3e) sent to the model, and plain text blocks, from the 40 tuning pages in a fixed
    order (same images every run)."""
    items = []
    for line in (EVAL / "tune_crops.tsv").read_text(encoding="utf-8").splitlines()[:30]:
        if line.strip():
            items.append({"kind": "formula_crop", "image": line.split("\t")[0], "prompt": "Formula Recognition:",
                          "max_pixels": FORMULA_TOKENS * PIXELS_PER_TOKEN})
    pages = sorted(p for p in (EVAL / "regions").iterdir() if p.is_dir())
    cap = {"formula_block": 20, "math_text_block": 20, "text_block": 20}
    count = dict.fromkeys(cap, 0)
    hybrid = EVAL / "runs" / "pipeline_3e"
    for page in pages:
        to_vl = set()
        hf = hybrid / f"{page.name}.png.json"
        if hf.exists():
            for b in json.loads(hf.read_text(encoding="utf-8"))["blocks"]:
                if b["label"] != "display_formula" and "$" in (b.get("content") or ""):
                    to_vl.add(tuple(round(v) for v in b["bbox"]))
        for line in (page / "entries.jsonl").read_text(encoding="utf-8").splitlines():
            e = json.loads(line)
            img = str(page / e["name"])
            if e["prompt"] == "Formula Recognition:":
                kind = "formula_block"
            else:
                kind = "math_text_block" if tuple(round(v) for v in e["box"]) in to_vl else "text_block"
            if count[kind] >= cap[kind]:
                continue
            count[kind] += 1
            items.append({"kind": kind, "image": img, "prompt": e["prompt"] if kind == "formula_block" else "OCR:",
                          "max_pixels": e["max_pixels"], "page": page.name})
    return items


def encode(path, max_pixels):
    bgr = cv2.imread(path)
    h, w = bgr.shape[:2]
    if h * w > max_pixels:
        f = (max_pixels / (h * w)) ** 0.5
        bgr = cv2.resize(bgr, (max(1, int(w * f)), max(1, int(h * f))), interpolation=cv2.INTER_AREA)
    return base64.b64encode(cv2.imencode(".png", bgr)[1].tobytes()).decode()


def read_thermals():
    batt = shell("dumpsys battery | grep -E ' level:| temperature:'", check=False)
    zones = shell("for z in /sys/class/thermal/thermal_zone*; do t=$(cat $z/type 2>/dev/null); "
                  "v=$(cat $z/temp 2>/dev/null); [ -n \"$v\" ] && echo \"$t=$v\"; done | head -40", check=False)
    return batt, zones


def run(mode):
    out = RESULTS / mode
    out.mkdir(parents=True, exist_ok=True)
    shell("pkill -f llama-server", check=False)
    gpu = ["-ngl", "99"] if mode == "gpu" else ["-ngl", "0", "--no-mmproj-offload"]
    cmd = (f"cd {REMOTE} && nohup ./llama-server -m {LLM} --mmproj {MMPROJ} --port {PORT} --host 127.0.0.1 "
           f"-t {THREADS} -tb {THREADS} -c 8192 -np 1 --temp 0 --jinja --no-warmup {' '.join(gpu)} "
           f"> server_{mode}.log 2>&1 &")
    shell(cmd)
    adb("forward", f"tcp:{PORT}", f"tcp:{PORT}")
    base = f"http://127.0.0.1:{PORT}"
    t0 = time.time()
    for _ in range(600):
        try:
            if json.loads(urllib.request.urlopen(base + "/health", timeout=2).read()).get("status") == "ok":
                break
        except Exception:
            pass
        time.sleep(1)
    load_s = time.time() - t0
    pid = shell("pidof llama-server", check=False).split()[0]

    samples, stop = [], threading.Event()

    def sample():
        while not stop.is_set():
            status = shell(f"grep -E 'VmRSS|VmHWM' /proc/{pid}/status", check=False)
            batt, zones = read_thermals()
            samples.append({"t": round(time.time() - t0, 1), "status": status, "battery": batt, "zones": zones})
            time.sleep(1)

    threading.Thread(target=sample, daemon=True).start()
    rows = []
    try:
        for i, it in enumerate(bench_items()):
            body = {"messages": [{"role": "user", "content": [
                {"type": "image_url", "image_url": {"url": "data:image/png;base64," + encode(it["image"], it["max_pixels"])}},
                {"type": "text", "text": it["prompt"]}]}], "temperature": 0, "max_tokens": 1024, "cache_prompt": False}
            ts = time.time()
            req = urllib.request.Request(base + "/v1/chat/completions", data=json.dumps(body).encode(),
                                         headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=1800) as r:
                resp = json.loads(r.read())
            tm = resp.get("timings", {})
            rows.append({**it, "wall_s": round(time.time() - ts, 2), "prompt_ms": tm.get("prompt_ms"),
                         "predicted_ms": tm.get("predicted_ms"), "n_prompt": tm.get("prompt_n"),
                         "n_predicted": tm.get("predicted_n"), "text": resp["choices"][0]["message"]["content"]})
            print(i, it["kind"], rows[-1]["wall_s"], "s", flush=True)
            (out / "items.json").write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")
    finally:
        stop.set()
        shell("pkill -f llama-server", check=False)
        adb("forward", "--remove", f"tcp:{PORT}", check=False)
        adb("pull", f"{REMOTE}/server_{mode}.log", str(out / "server.log"), check=False)
        (out / "samples.json").write_text(json.dumps({"load_s": round(load_s, 1), "samples": samples}, indent=1),
                                          encoding="utf-8")


def report():
    cpu_f, gpu_f = RESULTS / "cpu" / "items.json", RESULTS / "gpu" / "items.json"
    if cpu_f.exists() and gpu_f.exists():
        cpu = {r["image"]: r["text"] for r in json.loads(cpu_f.read_text(encoding="utf-8"))}
        gpu = {r["image"]: r["text"] for r in json.loads(gpu_f.read_text(encoding="utf-8"))}
        both = [k for k in cpu if k in gpu]
        same = sum(cpu[k].strip() == gpu[k].strip() for k in both)
        # Some mobile GPU drivers compute differently; readings must match before GPU is trusted.
        print(f"GPU readings identical to CPU: {same} of {len(both)}")
    layout_s, ocr_s = 5.1, 4.7  # phone, measured (PR #31 bench, median per page)
    per_page = {"formula_block": 2.55, "math_text_block": 1.78, "text_block": 6.7}  # from stage 3 (40 pages)
    for mode in ("cpu", "gpu"):
        f = RESULTS / mode / "items.json"
        if not f.exists():
            continue
        rows = json.loads(f.read_text(encoding="utf-8"))
        by = {}
        for r in rows:
            by.setdefault(r["kind"], []).append(r["wall_s"])
        means = {k: round(statistics.mean(v), 1) for k, v in by.items()}
        s = json.loads((RESULTS / mode / "samples.json").read_text(encoding="utf-8"))
        hwm = max((int(x["status"].split("VmHWM:")[1].split()[0]) for x in s["samples"] if "VmHWM" in x["status"]),
                  default=0)
        est_3e_formulas = layout_s + ocr_s + per_page["formula_block"] * means.get("formula_block", 0)
        est_3e = est_3e_formulas + per_page["math_text_block"] * means.get("math_text_block", 0)
        est_3c = layout_s + sum(per_page[k] * means.get(k, 0) for k in per_page)
        print(json.dumps({"mode": mode, "load_s": s["load_s"], "mean_s": means, "n": {k: len(v) for k, v in by.items()},
                          "peak_rss_mb": round(hwm / 1024),
                          "est_page_s": {"3e_formulas_only": round(est_3e_formulas), "3e": round(est_3e),
                                         "3c": round(est_3c)}}, indent=1))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["info", "push", "run", "report"])
    ap.add_argument("--mode", choices=["gpu", "cpu"], default="gpu")
    a = ap.parse_args()
    {"info": info, "push": push, "report": report}.get(a.cmd, lambda: run(a.mode))()
