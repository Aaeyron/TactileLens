# TactileLens Dataset and Evaluation Plan

**Status**: In Development  
**Document Version**: 1.0.0  
**Target Repository**: TactileLens  

---

## 1. Executive Summary and Purpose

TactileLens is an accessibility application converting printed instructional materials into Unified English Braille (UEB Grade 2) and Nemeth Braille Code for educators and visually impaired students.

Currently, TactileLens operates using **pretrained foundation models** (PaddleOCR-VL online, and PP-OCRv6, PP-DocLayoutV3, and PP-FormulaNet_plus-S offline on Android) coupled with custom layout-parsing, heuristic routing, and translation pipelines. 

To improve recognition accuracy on localized curriculum materials (e.g., secondary school mathematics textbooks, worksheets, and printed examinations), this plan outlines the dataset collection, annotation standards, quality verification, and experimental evaluation protocol.

---

## 2. Technical Audit & Architecture Verification

Before collecting data or attempting model fine-tuning, the runtime and model interchange requirements were audited against the production codebase:

### 2.1 On-Device Android ONNX Requirements
* **Text Detection & Recognition (`PP-OCRv6`)**: Loaded via the official PaddleOCR Android SDK (`com.paddle.ocr:paddle-ocr-android`). A retrained model must be exported via `paddle2onnx` and can replace `inference.onnx` accompanied by an updated `inference.yml` character dictionary.
* **Page Layout Detection (`PP-DocLayoutV3`)**:
  * **Architecture**: Identified as **RT-DocLayout** (a real-time DETR-based document layout architecture).
  * **Enforced Input Shape**: `[1, 3, 800, 800]` Float32 RGB tensor normalized to $[0, 1]$ (explicitly enforced in `PaddleOnnxLayoutDetector.kt`).
  * **Required Output Tensors**:
    * `"logits"`: shape `[1, 300, 25]` (300 query slots, 25 semantic categories).
    * `"pred_boxes"`: shape `[1, 300, 4]` (normalized bounding boxes in $cx, cy, w, h$ format).
    * `"order_logits"`: shape `[1, 300, 300]` (pairwise reading order voting matrix).
  * **Class Definitions**: 25 categories in fixed alphabetical order (Index 5: `display_formula`, Index 15: `inline_formula`, Index 21: `table`, Index 22: `text`).
* **Formula Recognition (`PP-FormulaNet_plus-S`)**:
  * **Architecture**: UniMERNet derivative.
  * **Enforced Input Shape**: `[1, 1, 384, 384]` Float32 1-channel grayscale tensor normalized with $\text{mean}=0.7931$, $\text{std}=0.1738$ (enforced in `PaddleOnnxFormulaRecognizer.kt`).
  * **Required Output**: Token IDs decoded via GPT-2 byte-level mapping and `pp-formulanet_vocab.json`.
  * **ONNX Control Flow Constraint**: The exported ONNX model **must include the autoregressive greedy decoding `Loop` operator within the graph**. An encoder-decoder checkpoint lacking this graph loop cannot be executed by the Android Kotlin runtime.

### 2.2 Mandatory Pre-Training Check: ONNX Export Smoke Test
> **Critical Prerequisite**: Prior to undertaking full model training or fine-tuning, an ONNX export smoke test must be conducted on an initial checkpoint. This confirms that the converted `.onnx` graph strictly complies with the tensor names, dimensions, opsets, and control-flow loops expected by `PaddleOnnxLayoutDetector.kt` and `PaddleOnnxFormulaRecognizer.kt`.

### 2.3 Official Training Support Status
* **PP-OCRv6 (Detection & Recognition)**: Official training and fine-tuning scripts are supported via PaddleOCR (`tools/train.py`).
* **PP-DocLayoutV3**: Supported via PaddleX Layout Detection / RT-DETR training recipes with COCO annotations.
* **PP-FormulaNet_plus-S**: Supported via UniMERNet / PaddleX formula recognition recipes.
* **PaddleOCR-VL-1.6 (Online VLM)**: **Training recipe not found in official documentation reviewed**. 
  * *Documentation Reviewed*:
    * [PaddleOCR-VL-1.6 Algorithm Introduction](https://github.com/PaddlePaddle/PaddleOCR/blob/main/docs/version3.x/algorithm/PaddleOCR-VL/PaddleOCR-VL-1.6.en.md)
    * [PaddleOCR-VL Pipeline Usage](https://github.com/PaddlePaddle/PaddleOCR/blob/main/docs/version3.x/pipeline_usage/PaddleOCR-VL.md)
    * [PaddleOCR Main README](https://github.com/PaddlePaddle/PaddleOCR/blob/main/README.md)
  * *Observation*: While inference, deployment, and export to Markdown/DOCX are documented, no public training pipelines, SFT scripts, or data loaders are provided for the 0.9B vision-language model in the reviewed open-source documentation. Consequently, fine-tuning efforts must focus on the modular on-device components or await official PaddleX VLM fine-tuning releases.

---

## 3. Dataset Target & Scope

### 3.1 Long-Term Dataset Target (8,000 Images)
The long-term target is **8,000 images** focused on General Algebra topics across secondary education curricula:

| Topic Area | Target Total Images | Target Digital Screenshots | Target Camera Photographs |
| :--- | :---:| :---:| :---:|
| 1. Fractions & Rational Expressions | 1,000 | 500 | 500 |
| 2. Exponents & Scientific Notation | 1,000 | 500 | 500 |
| 3. Radicals & Roots | 1,000 | 500 | 500 |
| 4. Linear Equations & Systems | 1,000 | 500 | 500 |
| 5. Quadratic Equations | 1,000 | 500 | 500 |
| 6. Inequalities (Linear & Compound) | 1,000 | 500 | 500 |
| 7. Polynomial Expressions & Factoring | 1,000 | 500 | 500 |
| 8. Basic Algebraic Function Notation | 1,000 | 500 | 500 |
| **Total Target** | **8,000** | **4,000** | **4,000** |

> *Note*: These numbers represent target milestones for future collection. They are **not** current inventory counts.

### 3.2 Pilot Dataset Scope (200 Images)
To debug the annotation workflow, validate serialization, and establish a baseline performance benchmark, a small pilot dataset will be collected first:
* **Target Size**: 25 images per topic = **200 images total**.
* **Composition**: Equal balance of digital document clippings (clean renders) and physical camera photographs taken under realistic classroom lighting (varying angles, minor shadows, natural skew).
* **Objective**: Evaluate baseline metrics of the existing pretrained models, test evaluation scripts, and verify data ingestion without incurring large-scale annotation costs.

---

## 4. Dataset Accounting & Progression Criteria

To prevent ambiguity between planned goals and verified assets, all dataset reporting must track five distinct stages:

```
[ Planned ] ──> [ Collected ] ──> [ Annotated ] ──> [ Usable / Verified ] ──> [ Train / Val / Test Split ]
```

1. **Planned Images**: Target counts allocated per topic and modality.
2. **Collected Images**: Raw images ingested into staging storage, pending validation of resolution, focus, and licensing.
3. **Successfully Annotated Images**: Images paired with complete annotations matching the respective sub-model format.
4. **Usable Images**: Annotated images that have passed automated syntax checks (valid LaTeX, well-formed polygons, no NaN values).
5. **Split Images**: Partitioned into fixed sets:
   * **Train Set (70%)**: Used exclusively for training/fine-tuning.
   * **Validation Set (15%)**: Used for hyperparameter tuning and early stopping.
   * **Test Set (15%)**: Held out strictly for benchmark evaluation.

---

## 5. Sub-Component Annotation Specifications

Because TactileLens employs specialized sub-models for offline scanning, annotation schemas are distinct per component:

```
┌────────────────────────────────────────────────────────┐
│                   Full Document Page                   │
├──────────────────────────┬─────────────────────────────┤
│ Component                │ Annotation Schema           │
├──────────────────────────┼─────────────────────────────┤
│ Document Layout          │ COCO JSON [x, y, w, h] + ID │
│ Text Detection           │ Polygons [[x1,y1]..[x4,y4]] │
│ Text Recognition         │ Line Crop Image + Plain Text│
│ Formula Recognition      │ Equation Crop Image + LaTeX │
└──────────────────────────┴─────────────────────────────┘
```

### 5.1 Document Layout Detection (`PP-DocLayoutV3` / RT-DocLayout)
* **Image Format**: Full page image.
* **Annotation Schema**: COCO Object Detection format (`instances.json`).
* **Required Categories**: Must align with the 25 classes defined in `PaddleOnnxLayoutDetector.kt`:
  * Core focus: `text` (22), `display_formula` (5), `inline_formula` (15), `table` (21), `doc_title` (6), `paragraph_title` (17).
* **Reading Order Annotation**: Sequential index (`order_index`) for each bounding region.

### 5.2 Text Detection (`PP-OCRv6-tiny-det`)
* **Image Format**: Full page image or region crop.
* **Annotation Schema**: PaddleOCR Detection format (ICDAR 2015 style):
  ```json
  [
    {"points": [[x1, y1], [x2, y2], [x3, y3], [x4, y4]], "transcription": "Solve for x in the following equation:"}
  ]
  ```

### 5.3 Text Recognition (`PP-OCRv6-small-rec`)
* **Image Format**: Individual cropped text line images (height typically normalized to 48px).
* **Annotation Schema**: Plain text label mapping file (`rec_gt.txt`):
  ```tsv
  line_0001.png	Solve for x in the following equation:
  ```
* **Character Vocabulary**: Must cross-reference against the dictionary embedded in `PP-OCRv6-small-rec-onnx/inference.yml`.

### 5.4 Mathematical Formula Recognition (`PP-FormulaNet_plus-S`)
* **Image Format**: Cropped formula image (isolated expression or equation).
* **Annotation Schema**: LaTeX string mapping file (`formula_gt.txt`):
  ```tsv
  formula_0001.png	\frac{-b \pm \sqrt{b^{2} - 4ac}}{2a}
  ```
* **Formatting Rules**:
  * Standard LaTeX syntax without enclosing `$` or `$$` delimiters.
  * Use standard command vocabulary supported by `KNOWN_LATEX_COMMANDS` in `OfflineDocumentPipeline.kt` (e.g., `\frac`, `\sqrt`, `\pm`, `\leq`, `\geq`).

---

## 6. Independent Ground Truth & Braille Verification

To maintain rigorous scientific validity, **Liblouis output must not be used as the sole ground truth to evaluate a pipeline that itself uses Liblouis**.

### 6.1 Three-Layer Ground Truth Hierarchy
1. **Raw Text Ground Truth**: Verbatim human transcription of English instructional text.
2. **Formula Ground Truth**: Verbatim LaTeX string representing the exact mathematical semantics.
3. **Braille Ground Truth**:
   * Must be created or verified by a qualified Braille reviewer certified in **Unified English Braille (UEB)** and **Nemeth Code for Mathematics**.
   * If a human-verified reference is not yet available, the record must be explicitly tagged as `braille_status: pending_human_verification`.
   * Under no circumstances may automated Liblouis output be silently accepted as true reference Braille during evaluation.

---

## 7. Evaluation Metrics & Protocol

### 7.1 Quantitative Evaluation Metrics
* **Text Recognition**:
  * Character Error Rate (CER): $\frac{S + D + I}{N}$ at character level.
  * Word Error Rate (WER): Word-level Levenshtein error rate.
* **Formula Recognition**:
  * Exact Match (EM): Percentage of expressions matching ground-truth LaTeX token-for-token.
  * Normalized Edit Distance (1 - NED): Character-level similarity between predicted and ground-truth LaTeX.
  * BLEU Score: N-gram overlap of LaTeX tokens.
* **Layout & Reading Order**:
  * Mean Average Precision (mAP@50, mAP@50:95) across document categories.
  * Reading Order Inversion Rate: Proportion of out-of-order block pairs.
* **Braille Translation (End-to-End)**:
  * Braille Character Error Rate (B-CER): Levenshtein distance on Unicode Braille characters ($\text{U+2800}..\text{U+28FF}$).
* **Execution Performance**:
  * Preprocessing, inference, and postprocessing latency (milliseconds).
  * Peak memory consumption (RAM and VRAM).

### 7.2 Benchmark Execution Procedure
1. Run evaluation over the frozen **Held-Out Test Set** (never seen during training or tuning).
2. Record all measurements in `docs/evaluation/RESULTS.md` with timestamp, model checkpoint hash, and dataset split version.
3. Disclose testing environment specifications (CPU model, thread count, GPU type, device model).

---

## 8. Ethics, Licensing, and Limitations

* **Copyright & Permissions**: No copyrighted textbooks or proprietary educational modules may be ingested without explicit permission or applicable educational fair use exemptions. Public-domain and open educational resources (OER, such as OpenStax) under Creative Commons licenses (CC BY, CC BY-SA) are prioritized.
* **Privacy & PII**: All captured documents must be vetted to ensure no student names, teacher notes, or personal identifying information are present in the image data.
* **Repository Policy**: Raw image files are not committed to git. Only annotation files, metadata manifests, and evaluation summaries belong in the version-controlled repository.
