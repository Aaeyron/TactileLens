# TactileLens

TactileLens is an accessibility mobile application designed for teachers of visually impaired students. It converts printed instructional materials—including English text, mathematical equations, and structured tables—into Grade 2 Unified English Braille (UEB) and Nemeth Braille Code.

---

## Architecture Overview

TactileLens consists of three coordinated subsystems:

```
[ Flutter Mobile App ] ──(Online: HTTPS / JWT)──> [ Node.js Express Backend ]
        │                                                     │
   (Offline: ONNX)                                     (Modal / HTTPS)
        │                                                     │
        ▼                                                     ▼
[ On-Device ONNX Models ]                             [ Python AI Service ]
(PP-DocLayoutV3 + PP-OCRv6 +                         (PaddleOCR-VL v1.6 on
 PP-FormulaNet + Liblouis)                            Nvidia L4 GPU + Liblouis)
```

1. **Frontend (Flutter / Android)**: Provides camera capture, document cropping, Braille rendering, library management, and an on-device offline OCR engine.
2. **Backend (Node.js / Express / PostgreSQL)**: Authenticates users, validates uploads, proxies document scans to the AI service, and persists scan history and materials.
3. **AI Service (Python / FastAPI / Modal GPU)**: Executes the multimodal PaddleOCR-VL document pipeline, normalizes formulas, translates content to Braille via Liblouis, and returns structured block coordinates and timings.

---

## OCR Models

The application relies on two distinct OCR pathways depending on network connectivity and authentication state.

> **Model Training Status**: All models currently used in TactileLens are **pretrained foundation models**. No models were trained or fine-tuned by our team. Current recognition accuracy is achieved by combining these pretrained models with custom preprocessing, layout reordering, heuristic safety nets, and normalization pipelines. Domain-specific fine-tuning on local curriculum materials is **planned future work**.

| Characteristic | Online Pipeline (PaddleOCR-VL) | Offline Pipeline (On-Device ONNX) |
| :--- | :--- | :--- |
| **Model Name** | `PaddleOCR-VL` (pipeline `v1.6`) | `PP-DocLayoutV3`, `PP-OCRv6`, `PP-FormulaNet_plus-S` |
| **Runtime / Engine** | Remote Python FastAPI (`paddleocr[doc-parser]==3.7.0`, `paddlepaddle-gpu==3.2.1`) | On-device CPU via ONNX Runtime Android (`1.21.1`) |
| **Execution Target** | Nvidia L4 GPU (Modal Cloud) or local CUDA GPU | Mobile device CPU (multi-threaded, default 4 threads) |
| **What It Reads** | Printed English text, inline/display math formulas (LaTeX), and structured tables | Printed English text and algebraic equations (LaTeX) |
| **Input** | Image bytes (`.jpg`, `.png`, `.webp`, `.bmp`, `.tiff`) up to 20 MB | Camera or gallery image file path on the device |
| **Output** | Structured JSON with bounding boxes, typed blocks (`text`, `formula`, `table`), normalized text, Braille Unicode, and execution timings | `OfflineDocumentResult` with ordered text/LaTeX blocks, bounding boxes, and on-device Braille Unicode |
| **Model Assets / Path** | Downloaded and managed by PaddleOCR runtime | Bundled in APK assets (`android/app/src/main/assets/paddle_onnx/`) |

### Model Details

#### 1. Online: PaddleOCR-VL (`v1.6`)
* **Text & Layout**: Identifies text regions, heading structures, and tables.
* **Math Formulas**: Extracts inline and display mathematical formulas into clean LaTeX.
* **Tables**: Parsed into rows, columns, and cell coordinates via `TableContentParser`.

#### 2. Offline: On-Device ONNX Suite
* **Layout Detection (`PP-DocLayoutV3`)**: Model file `pp_doclayoutv3_nomask.onnx` (~134 MB). Identifies document regions and natural reading order.
* **Text Detection (`PP-OCRv6-tiny-det`)**: Model file `inference.onnx` (~1.8 MB). Detects text bounding boxes.
* **Text Recognition (`PP-OCRv6-small-rec`)**: Model file `inference.onnx` (~21.2 MB). Recognizes text characters from detected boxes.
* **Formula Recognition (`PP-FormulaNet_plus-S`)**: Model file `pp-formulanet_plus-s.onnx` (~231.9 MB) and vocabulary `pp-formulanet_vocab.json`. Recognizes algebraic crops and outputs LaTeX equations.

---

## Processing Pipeline

Both online and offline flows follow a unified 6-step pipeline:

```
[ 1. Capture ] ──> [ 2. Prepare ] ──> [ 3. Recognize ] ──> [ 4. Structure ] ──> [ 5. Translate ] ──> [ 6. Deliver ]
```

### Step 1: Capture
* The user snaps a photo using the custom camera viewfinder or selects an image from the local gallery.
* Optional interactive crop adjusts the bounding frame to the intended printed material.

### Step 2: Prepare
* **Orientation Correction**: Applies EXIF transposition to correct camera orientation (`ImageOps.exif_transpose` in Python; `img.bakeOrientation` in Flutter).
* **Dimension Normalization**: Downscales images where the longest edge exceeds 2000 pixels using Lanczos resampling.
* **Optimization**: Re-encodes the image as an optimized RGB JPEG (quality 88) to minimize transfer time and memory overhead.

### Step 3: Recognize
* **Online**: PaddleOCR-VL runs layout analysis and vision-language token recognition in a single locked GPU pass.
* **Offline**:
  1. `PP-DocLayoutV3` segments the page into regions.
  2. `PP-OCRv6` reads text lines across the entire page.
  3. Lines falling inside formula bounding boxes are filtered out.
  4. Formula regions are cropped and passed to `PP-FormulaNet_plus-S`.
  5. **Safety Net**: Text blocks containing algebraic syntax (e.g., `=` or operators without standard English words) are dynamically rerouted to the formula model.

### Step 4: Structure
* Blocks are ordered top-to-bottom and left-to-right following document reading flow.
* Regions are categorized into semantic block types:
  * `text`: Paragraphs, headings, labels.
  * `formula` / `display_formula` / `inline_formula`: Mathematical equations.
  * `table`: Tabular data rows and columns.
* Bounding box coordinates and polygon vertices are preserved for UI rendering.

### Step 5: Translate
* **Text Content**: Normalized and translated to **Unified English Braille (UEB Grade 2)** using Liblouis with the `en-ueb-g2.ctb` translation table.
* **Mathematical Expressions**: LaTeX formulas are normalized via `BrailleMathNormalizer` and translated to **Nemeth Braille Code** using Liblouis with the `en-us-mathtext.ctb` table.
* **Tables**: Flattened or formatted into structured rows with individual cell Braille translations.

### Step 6: Deliver
* **Online Mode**: The backend saves the structured document, Braille translation, and metadata to PostgreSQL under the user's history and returns the saved record to the app.
* **Offline Mode**: The app constructs the result entirely in memory, displays it on the result screen, and persists it to local device storage without transmitting data externally.

---

## Operational Modes

| Aspect | Online Mode (Signed-In Users) | Offline Mode (Guests / No Internet) |
| :--- | :--- | :--- |
| **Trigger** | User logs into an account (`AI_SCAN_MODE=session` or `remote`) | User selects "Continue as Guest" (`AI_SCAN_MODE=session` or `offline`) |
| **Network Requirement** | Internet connection required | Zero internet connection required |
| **Compute Location** | Cloud GPU (Modal Nvidia L4) or self-hosted GPU | On-device mobile CPU |
| **Data Privacy** | Images sent securely to backend over HTTPS | Nothing leaves the device; processed in sandbox |
| **History & Storage** | Synced to PostgreSQL database under account | Saved in device local SQLite / preferences |
| **Table Support** | Full table layout parsing | Tabular blocks treated as structured text |

---

## Dataset and Evaluation

**Status**: In Development

TactileLens is developing an evaluation and domain-adaptation dataset focused on secondary-school General Algebra learning materials across 8 core topics (fractions, exponents, radicals, linear equations, quadratic equations, inequalities, polynomials, and function notation).

* **Long-Term Target**: 8,000 images (500 digital screenshots and 500 camera-captured photographs per topic).
* **Initial Pilot Milestone**: 200 images (25 images per topic) to debug data pipelines and establish baseline measurements on pretrained models.
* **Independent Ground Truth**: Reference text and LaTeX are manually transcribed, and reference Braille must be verified by a qualified reviewer rather than using automated Liblouis output.
* **Status Distinction**: Targets represent planned milestones, not completed collections. Models are pretrained; no fine-tuning has taken place yet.

Detailed documentation:
* [docs/evaluation/DATASET_PLAN.md](docs/evaluation/DATASET_PLAN.md): Complete data collection, component-specific annotation formats, and evaluation protocols.
* [docs/evaluation/RESULTS.md](docs/evaluation/RESULTS.md): Benchmark results template for baseline and post-training metrics.
* [dataset_card.md](dataset_card.md): Dataset card documenting scope, licensing, distributions, quality control, and limitations.

---

## Project Structure

```
TactileLens/
├── ai_service/                      # Python AI Service
│   ├── app.py                       # FastAPI application and image endpoints
│   ├── modal_app.py                 # Modal serverless GPU deployment
│   ├── requirements.txt             # Python runtime dependencies
│   ├── services/                    # Tests sit next to the module they cover
│   │   ├── ocr/
│   │   │   ├── paddleocr_vl_service.py    # Scan pipeline (local or hosted engine)
│   │   │   ├── official_api_client.py     # PaddleOCR official hosted API client
│   │   │   ├── block_ordering.py          # Unique block reading order and ids
│   │   │   ├── ocr_content_normalizer.py  # Unicode & spacing normalizer
│   │   │   ├── table_content_parser.py    # Table HTML / matrix parser
│   │   │   └── latex_readable_converter.py # Math formula text formatter
│   │   ├── braille/
│   │   │   ├── braille_translation_service.py # Liblouis UEB & Nemeth translation
│   │   │   ├── braille_math_normalizer.py     # LaTeX-to-Nemeth input sanitizer
│   │   │   └── formula_braille_guard.py       # Holds unsafe formulas for review
│   │   └── security/
│   │       └── service_key.py       # X-Service-Key check for every request
│   └── vendor/liblouis/             # Bundled Liblouis binaries & tables (Windows)
│
├── backend/                         # Node.js API Service
│   ├── package.json                 # Node dependencies and scripts
│   ├── .env.sample                  # Environment template
│   └── src/
│       ├── server.js                # Express entrypoint
│       ├── config/database.js       # PostgreSQL pool connection
│       ├── controllers/             # Auth, history, materials, scan controllers
│       ├── database/migrations/     # SQL schema definitions and migrations
│       ├── middleware/              # JWT auth and file upload filters
│       ├── routes/                  # Express route definitions
│       └── services/scan/           # Scan orchestration and AI service proxy
│
└── frontend/                        # Flutter Mobile Application
    ├── pubspec.yaml                 # Flutter packages and asset declarations
    ├── lib/
    │   ├── main.dart                # App entrypoint
    │   ├── app.dart                 # MaterialApp, themes, routing
    │   ├── screens/                 # Splash, auth, home, scan, materials, profile
    │   ├── services/ai/             # AIService, OfflineOcrService, MethodChannels
    │   └── utils/session_manager.dart # Token and guest state manager
    └── android/
        └── app/src/main/
            ├── assets/paddle_onnx/  # Bundled ONNX models (PP-OCRv6, DocLayout, Formula)
            └── kotlin/com/tactilelens/app/
                ├── MainActivity.kt           # MethodChannel bridge
                ├── OfflineDocumentPipeline.kt# On-device layout + OCR + formula merger
                ├── LiblouisNative.kt         # JNI bridge to libtactilelens_liblouis.so
                └── PaddleOnnx*.kt            # Native ONNX Runtime wrappers
```

---

## Environment Variables

### Backend (`backend/.env`)

| Variable | Description | Default / Example |
| :--- | :--- | :--- |
| `PORT` | Port for the Express backend server | `5000` |
| `DB_HOST` | PostgreSQL host | `localhost` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_NAME` | Database name | `tactilelens_db` |
| `DB_USER` | Database username | `postgres` |
| `DB_PASSWORD` | Database user password | `<database_password>` |
| `JWT_SECRET` | Secret key used to sign and verify user JWTs | `<random_secret>` |
| `JWT_EXPIRES_IN` | Duration before JWT expires | `7d` |
| `GOOGLE_CLIENT_ID`| OAuth client ID for Google Sign-In verification | `<google_client_id>` |
| `PASSWORD_RESET_SECRET` | Secret key used for password recovery tokens | `<random_secret>` |
| `PASSWORD_RESET_CODE_TTL_MINUTES` | Password reset code validity window | `10` |
| `PASSWORD_RESET_REQUEST_COOLDOWN_SECONDS` | Rate limit cooldown between reset emails | `60` |
| `SMTP_HOST` | SMTP server host for sending emails | `smtp.gmail.com` |
| `SMTP_PORT` | SMTP port | `465` |
| `SMTP_SECURE` | Use SSL/TLS for SMTP connection | `true` |
| `SMTP_USER` | Email account for authentication | `you@gmail.com` |
| `SMTP_PASSWORD` | App-specific password for SMTP | `<email_app_password>` |
| `SMTP_FROM_EMAIL` | Sender address shown in outgoing emails | `you@gmail.com` |
| `SMTP_FROM_NAME` | Sender display name | `TactileLens` |
| `AI_SERVICE_URL` | Base URL of the Python AI service | `http://localhost:8000` or Modal URL |
| `AI_SCAN_TIMEOUT_MS` | Max wait time for AI service response | `120000` (2 minutes) |

### AI Service (`ai_service`)

| Variable | Description | Default / Example |
| :--- | :--- | :--- |
| `AI_SERVICE_SECRET` | Shared secret key required in the `X-Service-Key` header | `<shared_secret>` |
| `PADDLEOCR_PIPELINE_VERSION` | Version of the PaddleOCR-VL pipeline | `v1.6` |
| `PADDLEOCR_DEVICE` | Execution device for PaddlePaddle | `gpu:0` (or `cpu`) |
| `PADDLEOCR_MAX_IMAGE_DIMENSION` | Longest edge limit before image resizing | `2000` |
| `PADDLEOCR_JPEG_QUALITY` | JPEG compression level for preprocessed images | `88` |
| `LIBLOUIS_ROOT` | Path containing Liblouis binary and table definitions | `/usr` on Linux; auto-detected on Windows |
| `MAX_UPLOAD_MB` | Maximum permitted file upload size | `20` |
| `LOG_LEVEL` | Logging verbosity | `INFO` |

### Frontend Compile-Time Flags (`--dart-define`)

| Define | Description | Default |
| :--- | :--- | :--- |
| `AI_BASE_URL` | Base URL pointing to the Node.js backend | `http://10.0.2.2:5000` (Android emulator) |
| `AI_SCAN_MODE` | Scan routing behavior (`session`, `offline`, `remote`, `hybrid`) | `session` |

---

## Local Setup & Running

### Prerequisites
* **Node.js**: v18.x or later
* **PostgreSQL**: v14.x or later
* **Python**: 3.10 or 3.11 with CUDA 12.6 support (if running GPU inference locally)
* **Flutter SDK**: 3.24.x or later with Android Studio and NDK

---

### 1. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment configuration
cp .env.sample .env
# Edit .env with your PostgreSQL credentials and secrets

# Run database migrations (connect to tactilelens_db with psql)
psql -U postgres -d tactilelens_db -f src/database/migrations/create_scan_history.sql
psql -U postgres -d tactilelens_db -f src/database/migrations/create_material_folders.sql
psql -U postgres -d tactilelens_db -f src/database/migrations/001_create_password_reset_tokens.sql
psql -U postgres -d tactilelens_db -f src/database/migrations/extend_materials_for_scan_results.sql
psql -U postgres -d tactilelens_db -f src/database/migrations/extend_scan_layout_storage.sql
psql -U postgres -d tactilelens_db -f src/database/migrations/extend_users_for_google_auth.sql

# Start development server
npm run dev
# Or production server
npm start
```

---

### 2. AI Service Setup (Local)

```bash
cd ai_service

# Create and activate virtual environment
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

# Install base dependencies
pip install -r requirements.txt

# Install PaddlePaddle GPU wheel (CUDA 12.6)
pip install paddlepaddle-gpu==3.2.1 -i https://www.paddlepaddle.org.cn/packages/stable/cu126/

# Install PaddleOCR document parser package
pip install "paddleocr[doc-parser]==3.7.0" python-docx==1.2.0

# Start local server
python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

---

### 3. Frontend Setup (Android)

```bash
cd frontend

# Fetch Flutter dependencies
flutter pub get

# Run on connected Android device or emulator
# For emulator connecting to local backend on host:
flutter run --dart-define=AI_BASE_URL=http://10.0.2.2:5000 --dart-define=AI_SCAN_MODE=session

# For physical phone on local Wi-Fi:
flutter run --dart-define=AI_BASE_URL=http://<YOUR_COMPUTER_LOCAL_IP>:5000 --dart-define=AI_SCAN_MODE=session
```

---

## Cloud Deployment (Modal GPU)

The AI service is deployed to Modal serverless GPU infrastructure via `ai_service/modal_app.py`.

### Deployment Specs
* **GPU**: Nvidia `L4` (24 GB VRAM)
* **Base Image**: `nvidia/cuda:12.6.3-cudnn-runtime-ubuntu22.04` with Python 3.11, `libgl1`, `libglib2.0-0`, `liblouis-bin`, and `liblouis-data`
* **Concurrency**: Maximum 1 concurrent scan per GPU instance (`@modal.concurrent(max_inputs=1)`) to avoid GPU memory exhaustion
* **Scale to Zero**: Scales down after 120 seconds of idle time (`scaledown_window=120`)
* **Request Timeout**: 180 seconds

### Authentication & Security
* Every route except `/health` is protected by middleware enforcing a shared secret:
  ```python
  if request.url.path not in PUBLIC_PATHS:
      given = request.headers.get("x-service-key", "")
      if not hmac.compare_digest(given.encode(), expected.encode()):
          return JSONResponse({"detail": "Forbidden"}, status_code=403)
  ```
* The `/health` route is public to allow zero-downtime warmup pings.

### Deploying to Modal

```bash
cd ai_service

# Install Modal CLI and log in
pip install modal
modal setup

# Store the shared secret in Modal
modal secret create tactilelens-ai AI_SERVICE_SECRET=your_long_random_secret_here

# Test the app interactively in the cloud
modal serve modal_app.py

# Deploy to production
modal deploy modal_app.py
```

Once deployed, copy the generated Modal endpoint URL and set it as `AI_SERVICE_URL` in your backend `.env`.
