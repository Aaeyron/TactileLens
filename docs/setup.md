# Setup

Run the backend, the AI service and the app on one PC with an Android
phone on USB. Paths are relative to the repository root. **Never commit
`.env` files, tokens or keys.**

## Prerequisites

Versions this was last run with (2026-10-26), not minimums:

| Tool | Version used | For |
|---|---|---|
| Node.js | 22.18 | backend |
| PostgreSQL | not recorded | backend |
| Python | 3.11.9 | AI service |
| PaddlePaddle GPU / PaddleOCR | 3.2.1 (CUDA 12.6) / `paddleocr[doc-parser]` 3.7.0 | AI service, local engine only |
| Liblouis | 3.38.0 | AI service (`lou_translate`) and app (built from the submodule) |
| Flutter | 3.44.7 (Dart SDK ^3.12.2) | app |
| Android | compileSdk 36, minSdk 26, NDK and CMake 3.22.1+ | app |

```
git clone <repo-url> && cd TactileLens
git submodule update --init --recursive   # Liblouis and llama.cpp, both compiled by the Android build
```

## 1. Database and backend

```
cd backend
npm install
```

Create `backend/.env` (no template is committed; see the variables
below), then apply the migrations in `backend/src/database/migrations/`
with `psql`:

```
psql -U <db_user> -d <db_name> -f src/database/migrations/create_scan_history.sql
psql -U <db_user> -d <db_name> -f src/database/migrations/create_material_folders.sql
psql -U <db_user> -d <db_name> -f src/database/migrations/001_create_password_reset_tokens.sql
psql -U <db_user> -d <db_name> -f src/database/migrations/extend_materials_for_scan_results.sql
psql -U <db_user> -d <db_name> -f src/database/migrations/extend_scan_layout_storage.sql
psql -U <db_user> -d <db_name> -f src/database/migrations/extend_users_for_google_auth.sql
```

**Gap:** no migration creates the `users` or `materials` tables, which
the other migrations extend. They must already exist; their schema is
not in the repository.

```
npm run dev      # or: npm start   (port 5000 by default)
```

## 2. AI service

The service reads **environment variables only** (no `.env` loader). Set
them in the shell that starts it.

```
cd ai_service
python -m venv .venv && .venv\Scripts\activate      # Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
```

Liblouis: on Windows put a Liblouis 3.38.0 build in `ai_service/vendor/liblouis/`
(`bin/lou_translate.exe`, `share/liblouis/tables/`; not in git) or set
`LIBLOUIS_ROOT`. On Linux: `apt install liblouis-bin liblouis-data` and
`LIBLOUIS_ROOT=/usr`.

**Local engine** (default, needs an NVIDIA GPU; the 1.6 model is
downloaded by PaddleOCR on first use, about 1.8 GB):

```
pip install paddlepaddle-gpu==3.2.1 -i https://www.paddlepaddle.org.cn/packages/stable/cu126/
pip install "paddleocr[doc-parser]==3.7.0" python-docx==1.2.0
python -m uvicorn app:app --host 127.0.0.1 --port 8000
```

**Hosted engine** (PaddleOCR's official API, no GPU): set
`PADDLEOCR_ENGINE=official_api` and `PADDLEOCR_ACCESS_TOKEN` (your own
token, from your own environment; never written to a file in the repo),
then start uvicorn as above. Paddle is imported only by the local engine
(covered by a test). The service also imports `numpy` and `Pillow`,
which `requirements.txt` does not list (they come with PaddleOCR); install
them for a hosted-only setup. Images sent to the hosted API are stored by
Baidu: use only material you may share.

Cloud GPU: `ai_service/modal_app.py` deploys the same app to Modal on an
NVIDIA L4 (one scan at a time, scales to zero after 2 idle minutes). It
does not set `PADDLEOCR_ENGINE`, so it runs the local engine.

## 3. App on a USB phone

```
adb devices
adb reverse tcp:5000 tcp:5000     # the phone's 127.0.0.1:5000 reaches the PC's backend
cd frontend
flutter pub get
flutter run --dart-define=AI_BASE_URL=http://127.0.0.1:5000 ^
            --dart-define=BACKEND_BASE_URL=http://127.0.0.1:5000 ^
            --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
```

(`^` is the Windows line continuation; use `\` on Linux/macOS.) The app
allows plain HTTP (`usesCleartextTraffic`), which is for local
development only.

On-device scanning needs the ONNX models, which are **not in git**
(about 390 MB). Place them before building:

```
frontend/android/app/src/main/assets/paddle_onnx/
  PP-DocLayoutV3/pp_doclayoutv3_nomask.onnx
  PP-FormulaNet_plus-S/pp-formulanet_plus-s.onnx, pp-formulanet_vocab.json
  PP-OCRv6-small-rec-onnx/inference.onnx, inference.yml
  PP-OCRv6-tiny-det-onnx/inference.onnx, inference.yml
```

The repository has no download script for them; `tools/model_prep/` has
scripts to inspect and test the exports.

## Environment variables

Names, purpose and defaults only. Secrets have no default and must never
be committed.

### Backend (`backend/.env`, loaded with dotenv)

| Name | What it does | Default |
|---|---|---|
| `PORT` | HTTP port | `5000` |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | PostgreSQL connection | none (pg library defaults) |
| `JWT_SECRET` | signs login tokens | none, required |
| `JWT_EXPIRES_IN` | login token lifetime | `7d` |
| `GOOGLE_CLIENT_ID` | verifies Google sign-in tokens | none, needed for Google sign-in |
| `PASSWORD_RESET_SECRET` | signs password-reset codes | none, required for resets |
| `PASSWORD_RESET_CODE_TTL_MINUTES` | reset code lifetime | `10` |
| `PASSWORD_RESET_REQUEST_COOLDOWN_SECONDS` | wait between reset emails | `60` |
| `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD` | mail server for reset emails | none, required for email |
| `SMTP_PORT` | mail server port | `587` |
| `SMTP_SECURE` | TLS from the start | `true` only when the port is 465 |
| `SMTP_FROM_EMAIL`, `SMTP_FROM_NAME` | sender | `SMTP_USER`, `TactileLens` |
| `AI_SERVICE_URL` | base URL of the AI service | none, scans fail without it |
| `AI_SERVICE_SECRET` | sent as `X-Service-Key`; must match the AI service | none (warning; local development only) |
| `AI_SCAN_TIMEOUT_MS` | wait for the AI service | `170000` |
| `AI_MAX_UPLOAD_MB` | largest scan image | `20` |
| `SCAN_LIMIT_PER_HOUR`, `SCAN_LIMIT_PER_DAY` | online scans per user | `30`, `100` |

### AI service (shell environment)

| Name | What it does | Default |
|---|---|---|
| `AI_SERVICE_SECRET` | required `X-Service-Key` value | none (no check; warning) |
| `MAX_UPLOAD_MB` | largest image | `20` |
| `LOG_LEVEL` | logging level | `INFO` |
| `LIBLOUIS_ROOT` | Liblouis folder (`bin/`, `share/liblouis/tables/`) | `ai_service/vendor/liblouis` |
| `LIBLOUIS_TRANSLATE` | path of `lou_translate` | `<LIBLOUIS_ROOT>/bin/lou_translate[.exe]` |
| `PADDLEOCR_ENGINE` | `local` or `official_api` | `local` |
| `PADDLEOCR_PIPELINE_VERSION` | local pipeline version | `v1.6` |
| `PADDLEOCR_DEVICE` | local device | `gpu:0` |
| `PADDLEOCR_MAX_IMAGE_DIMENSION` | longest edge before scaling down | `2000` |
| `PADDLEOCR_JPEG_QUALITY` | re-encode quality (70–95) | `88` |
| `PADDLEOCR_DEBUG_BLOCKS` | log raw blocks | `false` |
| `PADDLEOCR_ACCESS_TOKEN` | hosted API token (secret) | none, required for `official_api` |
| `PADDLEOCR_DAILY_PAGE_CAP` | pages per day, 1–2999 | `2500` |
| `PADDLEOCR_PAGE_COUNT_FILE` | keeps the day's count across restarts | none (count kept in memory) |
| `PADDLEOCR_API_URL`, `PADDLEOCR_API_MODEL`, `PADDLEOCR_API_AUTH_SCHEME` | hosted endpoint, model, auth | AI Studio jobs URL, `PaddleOCR-VL-1.6`, `bearer` |
| `PADDLEOCR_API_DEADLINE_SECONDS` | longest wait for one hosted job | `150` |

### App (`--dart-define`)

| Name | What it does | Default |
|---|---|---|
| `AI_BASE_URL` | backend URL for scans | `http://10.0.2.2:5000` (emulator) |
| `BACKEND_BASE_URL` | backend URL for sign-in and accounts | `http://10.0.2.2:5000` |
| `AI_SCAN_MODE` | `session`, `offline`, `remote` or `hybrid` for `AIService`; the scan screen creates its `AIService` with `session` explicitly, so this define currently has no effect on scans (see [scan modes](architecture.md#scan-modes-who-can-use-what)) | `session` |
| `GOOGLE_SERVER_CLIENT_ID` | Google sign-in server client id | none |
