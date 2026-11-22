# PaddleOCR-VL on the phone: GPU vs CPU bench (lever 1)

Bench only. Nothing here goes into the app. It answers one question: can the online-style
reading (3e: the VL model for formula blocks and for text blocks with math; or 3c: the VL model
for every block) finish a worksheet page in under about 60 s on the test phone?

The PC results it builds on are in
`tactilelens-training/evaluations/vl_gguf_20261122/RESULT.md`.

## Files (outside git)

| What | Where |
|---|---|
| Model files: Q4_K_M language model (300 MB) and Q8_0 vision file (598 MB) | `C:\Projects\Capstone\vl_gguf` |
| Android arm64 tools with Vulkan (`llama-server`, `llama-mtmd-cli`; stripped, 39 + 34 MB) | `C:\Projects\Capstone\vl_gguf\android\bin` |
| Bench images: app-style crops and online-style regions of the 40 tuning pages | `C:\Projects\Capstone\tactilelens-training\evaluations\vl_gguf_20261122` |
| Results | `C:\Projects\Capstone\vl_gguf\android\results\{cpu,gpu}` |

## Build

`build_android_vulkan.bat` builds the bundled llama.cpp for arm64 with Vulkan and CPU. It uses:

- **Android NDK 28.2:** the Vulkan C headers, `libvulkan.so` and `glslc`;
- **Vulkan-Headers v1.3.275:** `vulkan.hpp`, matching the NDK's headers;
- **SPIRV-Headers vulkan-sdk-1.3.275.0;**
- **MSVC:** builds the shader generator, which runs on this PC during the build.

The two header packages are small downloads (29 MB and 4 MB) in `vl_gguf\android`.

OpenCL is not built. llama.cpp's OpenCL backend targets Qualcomm Adreno GPUs, and the test phone
(Xiaomi 22071219CG) is believed to have a MediaTek chip with a Mali GPU. `info` checks this. If
the phone turns out to have an Adreno GPU, an OpenCL build is the next step.

## Run (phone connected, USB debugging on)

```
python phone_bench.py info               # SoC, GPU, memory, free space
python phone_bench.py push               # about 970 MB to /data/local/tmp/vlbench
python phone_bench.py run --mode cpu
python phone_bench.py run --mode gpu
python phone_bench.py report
```

Run it with the `paddle_onnx_env` Python, which has OpenCV.

**Bench items:** 90, at 4 threads:

| Items | What they are | Prompt |
|---|---|---|
| 30 | formula crops as the app cuts them | "Formula Recognition:", 512 tokens |
| 20 | online-style formula blocks | "Formula Recognition:" |
| 20 | text blocks with math (what 3e sends to the model) | "OCR:" |
| 20 | plain text blocks (3c also sends these) | "OCR:" |

**Logged:**

- **Each request:** wall time, plus the server's prompt and predict times.
- **Every second:** the server's VmRSS and VmHWM, battery temperature and level, and the thermal
  zones the shell can read.

**The report gives:**

- the mean seconds per item type, and the peak memory;
- how many GPU readings are identical to the CPU's (some mobile GPU drivers compute differently);
- an estimated time per page. It adds the measured phone layout time (5.1 s) and text-model time
  (4.7 s) to the measured model time per block, multiplied by the blocks per page from stage 3:
  2.55 formula blocks, 1.78 text blocks with math and 6.7 plain text blocks.

## Decision (fixed before measuring)

If 3e or 3c is estimated under about 60 s per page on the phone, it is built behind the existing
safety holds, and the 118-formula confirmation set is scored once. Otherwise the work stops and
PR #31 stays.
