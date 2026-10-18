# Dataset Card: TactileLens Algebra Dataset

## Dataset Description

* **Dataset Name**: TactileLens Algebra Dataset
* **Current Status**: In Development (Target: 8,000 images; Pilot: 200 images)
* **Dataset Release Version**: TBD
* **Primary Language**: English (printed mathematical and instructional text)
* **Target Output Formats**: Plain Text, LaTeX, Unified English Braille (UEB Grade 2), Nemeth Braille Code
* **Point of Contact**: TBD

---

## 1. Dataset Purpose & Intended Use

### 1.1 Purpose
The TactileLens Algebra Dataset is being designed to benchmark and adapt optical character recognition (OCR), document layout analysis, and mathematical formula recognition models for accessible learning materials used by teachers of visually impaired students.

### 1.2 Intended Applications
* Training and evaluating document layout detection on multi-column and mixed-content educational worksheets.
* Evaluating printed text line recognition on secondary school instructional text.
* Evaluating formula recognition on secondary school algebra equations (fractions, exponents, radicals, linear/quadratic equations, inequalities).
* End-to-end evaluation of automated translation into Unified English Braille (UEB Grade 2) and Nemeth Braille Code.

### 1.3 Out-of-Scope & Prohibited Uses
* Facial recognition, surveillance, or biometric analysis.
* Processing handwritten examinations without consent.
* Commercial redistribution of proprietary educational content without permission.

---

## 2. Image Sources & Collection Process

### 2.1 Sources
* **Open Educational Resources (OER)**: TBD (e.g., OpenStax textbooks under Creative Commons licenses)
* **Public Domain / DepEd Philippines Materials**: TBD (verified for educational distribution permissions)
* **Original Curriculum Artifacts**: TBD (created specifically for TactileLens)

### 2.2 Modalities & Collection Methods
* **Digital Screenshots**: High-resolution screen captures from digital textbooks/PDFs.
* **Camera Captures**: Smartphone photographs of printed paper sheets under varied lighting, angles, distances, and focal planes.

---

## 3. Dataset Distribution & Inventory

### 3.1 Topic Distribution

| Topic | Planned Target | Collected | Annotated | Usable |
| :--- | :---:| :---:| :---:| :---:|
| 1. Fractions & Rational Expressions | 1,000 | TBD | TBD | TBD |
| 2. Exponents & Scientific Notation | 1,000 | TBD | TBD | TBD |
| 3. Radicals & Roots | 1,000 | TBD | TBD | TBD |
| 4. Linear Equations & Systems | 1,000 | TBD | TBD | TBD |
| 5. Quadratic Equations | 1,000 | TBD | TBD | TBD |
| 6. Inequalities (Linear & Compound) | 1,000 | TBD | TBD | TBD |
| 7. Polynomial Expressions & Factoring | 1,000 | TBD | TBD | TBD |
| 8. Basic Algebraic Function Notation | 1,000 | TBD | TBD | TBD |
| **Total** | **8,000** | **TBD** | **TBD** | **TBD** |

### 3.2 Capture Modality Distribution

| Modality | Planned Target | Collected | Usable |
| :--- | :---:| :---:| :---:|
| Digital Screenshots | 4,000 | TBD | TBD |
| Camera-Captured Photographs | 4,000 | TBD | TBD |
| **Total** | **8,000** | **TBD** | **TBD** |

### 3.3 Initial Pilot Benchmark Subset
* **Pilot Target**: 200 images (25 images $\times$ 8 topics)
* **Collected**: TBD
* **Annotated**: TBD
* **Usable**: TBD

---

## 4. Annotation Process & Ground Truth Verification

### 4.1 Annotation Layers
1. **Layout Bounding Boxes**: Annotated in COCO JSON format across the 25 semantic categories required by `PP-DocLayoutV3` (RT-DocLayout).
2. **Text Lines**: Line-level bounding boxes and verbatim English text transcriptions.
3. **Formulas**: Formula crops paired with clean LaTeX strings matching the `PP-FormulaNet_plus-S` command vocabulary.
4. **Braille Transcriptions**:
   * Text blocks: UEB Grade 2 Braille Unicode.
   * Math blocks: Nemeth Braille Code.

### 4.2 Independent Ground Truth Policy
* Automated Liblouis translation output is **never** accepted as ground truth without human verification.
* All reference Braille files must be reviewed by a qualified UEB/Nemeth proofreader.
* Unreviewed translations are explicitly marked as `pending_human_verification`.

### 4.3 Reviewers & Annotators
* **Annotation Personnel**: TBD
* **Braille Validation Reviewer**: TBD
* **Inter-Annotator Agreement Score**: TBD

---

## 5. Quality Control & Dataset Splits

### 5.1 Quality Control Procedure
* **Visual Integrity**: Images with severe blur, occluded characters, or corrupted crops are removed.
* **LaTeX Compilability**: Every annotated LaTeX string is checked for syntax balance.
* **Bounding Box Containment**: Box coordinates are validated to ensure non-negative bounds and proper dimension limits.

### 5.2 Planned Splits

| Split | Percentage | Planned Count | Actual Count | Notes |
| :--- | :---:| :---:| :---:| :--- |
| **Train** | 80% | 6,400 | TBD | For model training / fine-tuning |
| **Validation** | 10% | 800 | TBD | For hyperparameter tuning |
| **Test** | 10% | 800 | TBD | Held out strictly for evaluation |
| **Total** | 100% | 8,000 | TBD | |

---

## 6. Licensing, Ethics, and Privacy

* **Image Licensing**: TBD (must specify open access / OER licenses per document source).
* **Annotation Licensing**: TBD (e.g., CC BY 4.0).
* **Personally Identifiable Information (PII)**: All collected materials are screened to ensure no student names, instructor identities, grades, or personal contact details are contained in images or metadata.
* **Repository Policy**: Raw image files are hosted outside the primary git codebase. Only structured annotation JSON/TSV metadata files are version-controlled in the repository.

---

## 7. Known Limitations & Potential Biases

* **Domain Restriction**: Focuses strictly on secondary-level algebra; calculus, geometry with complex figures, and organic chemistry are currently unrepresented.
* **Language Scope**: English-language instructional text only; regional Philippine languages (Tagalog, Cebuano) are not yet represented in the formula explanations.
* **Hardware Bias**: Pilot camera images are captured with specific test smartphone models; wider optical device variance will be required in subsequent expansions.
