# TactileLens Model Evaluation Results

This document records quantitative evaluation benchmarks for the TactileLens document recognition and Braille translation pipelines.

> **Status**: In Development  
> **Rule**: All metrics remain marked as `TBD` until formal experiments are executed on verified, frozen test sets. Do not populate placeholder fields with estimated or simulated numbers.

---

## Evaluation Benchmark Template

Every evaluation record must document the following parameters:

* **Experiment ID**: Unique identifier (e.g., `EXP-2026-PILOT-01`)
* **Evaluation Date**: Date of measurement (`YYYY-MM-DD`)
* **Evaluator**: Name / Organization
* **Pipeline Mode**: `Online (PaddleOCR-VL)` or `Offline (Android ONNX)`
* **Model Checkpoint**: Model name, version, and commit/checkpoint SHA
* **Hardware Environment**: Device model, CPU, GPU, thread count, OS version
* **Dataset Identifier**: Dataset name, version, and split (e.g., `tactilelens-pilot-v1:test`)
* **Test Set Size**: Total number of evaluated images / lines / equations

---

## 1. Baseline Evaluation (Pretrained Foundation Models)

*This section records performance of the initial pretrained models prior to any fine-tuning or domain adaptation.*

### 1.1 Summary Overview

| Experiment ID | Date | Pipeline Mode | Checkpoint / Model | Dataset & Split | Test Set Size | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `EXP-BASE-ONLINE-01` | TBD | Online (Modal GPU) | `PaddleOCR-VL-1.6` | TBD | TBD | Pending |
| `EXP-BASE-OFFLINE-01` | TBD | Offline (Android ONNX) | `PP-DocLayoutV3` + `PP-OCRv6` + `PP-FormulaNet_plus-S` | TBD | TBD | Pending |

---

### 1.2 Online Pipeline Baseline (`PaddleOCR-VL-1.6`)

* **Experiment ID**: `EXP-BASE-ONLINE-01`
* **Evaluation Date**: TBD
* **Model Checkpoint**: `PaddleOCR-VL-1.6` (pretrained official release)
* **Dataset & Split**: TBD
* **Test Set Size**: TBD images

#### Quantitative Metrics

| Task Component | Metric | Target | Baseline Result |
| :--- | :--- | :---: | :---: |
| **Printed Text Recognition** | Character Error Rate (CER) | $\le 2.0\%$ | **TBD** |
| | Word Error Rate (WER) | $\le 5.0\%$ | **TBD** |
| **Formula Recognition** | Exact Match (EM) | $\ge 85.0\%$ | **TBD** |
| | Normalized Edit Distance (1 - NED) | $\ge 90.0\%$ | **TBD** |
| | Formula BLEU | $\ge 85.0$ | **TBD** |
| **Layout Analysis** | Document mAP@50 | $\ge 90.0\%$ | **TBD** |
| | Reading Order Accuracy | $\ge 95.0\%$ | **TBD** |
| **Braille Translation** | End-to-End Braille CER | $\le 3.0\%$ | **TBD** |

#### Latency and Resource Metrics

| Metric | Measured Value | Notes |
| :--- | :---: | :--- |
| **Preprocessing Time** | **TBD** ms | Orientation + scaling to 2000px |
| **Inference Time (GPU)** | **TBD** ms | Nvidia L4 on Modal |
| **Serialization & Braille Time** | **TBD** ms | Liblouis translation |
| **Total End-to-End Latency** | **TBD** ms | |
| **Peak GPU VRAM Usage** | **TBD** MB | |

#### Observations & Failure Modes
* Text errors: TBD
* Formula errors: TBD
* Reading order errors: TBD

---

### 1.3 Offline Pipeline Baseline (On-Device Android ONNX)

* **Experiment ID**: `EXP-BASE-OFFLINE-01`
* **Evaluation Date**: TBD
* **Device / Environment**: Android Device (TBD), CPU (TBD threads)
* **Model Checkpoints**:
  * Layout: `PP-DocLayoutV3` (`pp_doclayoutv3_nomask.onnx`)
  * Detection: `PP-OCRv6-tiny-det-onnx` (`inference.onnx`)
  * Recognition: `PP-OCRv6-small-rec-onnx` (`inference.onnx`)
  * Formula: `PP-FormulaNet_plus-S` (`pp-formulanet_plus-s.onnx`)
* **Dataset & Split**: TBD
* **Test Set Size**: TBD images

#### Quantitative Metrics

| Task Component | Metric | Target | Baseline Result |
| :--- | :--- | :---: | :---: |
| **Printed Text Recognition** | Character Error Rate (CER) | $\le 3.0\%$ | **TBD** |
| | Word Error Rate (WER) | $\le 7.0\%$ | **TBD** |
| **Formula Recognition** | Exact Match (EM) | $\ge 80.0\%$ | **TBD** |
| | Normalized Edit Distance (1 - NED) | $\ge 88.0\%$ | **TBD** |
| | Formula BLEU | $\ge 80.0$ | **TBD** |
| **Layout Analysis** | Document mAP@50 | $\ge 85.0\%$ | **TBD** |
| | Reading Order Accuracy | $\ge 90.0\%$ | **TBD** |
| **Braille Translation** | End-to-End Braille CER | $\le 4.0\%$ | **TBD** |

#### Latency and Resource Metrics

| Metric | Measured Value | Notes |
| :--- | :---: | :--- |
| **Layout Detection Time** | **TBD** ms | 800×800 input |
| **Text Detection & Recognition Time** | **TBD** ms | Full page lines |
| **Formula Recognition Time** | **TBD** ms | Per formula box |
| **On-Device Liblouis Translation Time** | **TBD** ms | Native JNI `.so` |
| **Total End-to-End Latency** | **TBD** ms | Measured on device |
| **Peak RAM Consumption** | **TBD** MB | Mobile RAM footprint |
| **Total On-Device Model Size** | ~389 MB | Uncompressed asset sum |

#### Observations & Failure Modes
* Text errors: TBD
* Formula errors: TBD
* Reading order errors: TBD

---

## 2. Post-Training / Fine-Tuning Evaluation

*This section will record performance after real training or domain adaptation runs have completed and updated checkpoints have been verified via ONNX export testing.*

### 2.1 Post-Training Summary Overview

| Experiment ID | Date | Target Component | Checkpoint / Epoch | Dataset & Split | Test Set Size | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `EXP-FT-REC-01` | TBD | `PP-OCRv6-small-rec` | TBD | TBD | TBD | Not Started |
| `EXP-FT-FORMULA-01` | TBD | `PP-FormulaNet_plus-S` | TBD | TBD | TBD | Not Started |
| `EXP-FT-LAYOUT-01` | TBD | `PP-DocLayoutV3` | TBD | TBD | TBD | Not Started |

---

### 2.2 Text Recognizer Fine-Tuning (`EXP-FT-REC-01`)
* **Evaluation Date**: TBD
* **Training Epoch / Step**: TBD
* **Verified Checkpoint Hash**: TBD
* **ONNX Export Verified**: [ ] Yes / [ ] No

| Metric | Baseline | Post-Training | Delta |
| :--- | :---: | :---: | :---: |
| Character Error Rate (CER) | TBD | **TBD** | TBD |
| Word Error Rate (WER) | TBD | **TBD** | TBD |
| On-Device Rec Latency (ms) | TBD | **TBD** | TBD |

---

### 2.3 Formula Recognizer Fine-Tuning (`EXP-FT-FORMULA-01`)
* **Evaluation Date**: TBD
* **Training Epoch / Step**: TBD
* **Verified Checkpoint Hash**: TBD
* **ONNX Export Verified (Autoregressive Loop)**: [ ] Yes / [ ] No

| Metric | Baseline | Post-Training | Delta |
| :--- | :---: | :---: | :---: |
| Exact Match (EM) | TBD | **TBD** | TBD |
| Normalized Edit Distance (1 - NED) | TBD | **TBD** | TBD |
| Formula BLEU | TBD | **TBD** | TBD |
| On-Device Latency (ms) | TBD | **TBD** | TBD |

---

### 2.4 Layout Detector Fine-Tuning (`EXP-FT-LAYOUT-01`)
* **Evaluation Date**: TBD
* **Training Epoch / Step**: TBD
* **Verified Checkpoint Hash**: TBD
* **ONNX Export Verified (800×800, 25 classes)**: [ ] Yes / [ ] No

| Metric | Baseline | Post-Training | Delta |
| :--- | :---: | :---: | :---: |
| Layout mAP@50 | TBD | **TBD** | TBD |
| Reading Order Accuracy | TBD | **TBD** | TBD |
| On-Device Latency (ms) | TBD | **TBD** | TBD |
