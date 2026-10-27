# Architecture

How a scan becomes Braille, online and on the device. Everything here is
taken from the code on `main`; file names are given so it can be checked.

## Components

| Part | Code | Role |
|---|---|---|
| Flutter app (Android) | `frontend/` | camera and gallery, crop, scan mode, result view, Braille 1 / Braille 2, History, Materials, guest mode, on-device scanning |
| Node backend | `backend/` (Express 5, PostgreSQL) | accounts (email + Google sign-in), JWT, scan proxy with limits, history, materials and folders |
| AI service | `ai_service/` (FastAPI) | recognition (local PaddleOCR-VL or the hosted API), normalisation, formula guard, Braille via Liblouis |
| On-device pipeline | `frontend/android/app/src/main/kotlin/com/tactilelens/app/` | ONNX Runtime models and Liblouis (JNI), used for guests and the On-device mode |

The app talks only to the backend. The backend calls the AI service with
the shared `X-Service-Key` header (`ai_service/services/security/service_key.py`);
only `/health` is open.

## Scan modes: who can use what

| | Online | On-device |
|---|---|---|
| Guest (**Continue without an account**) | not available | always |
| Signed-in user | chosen before each scan | chosen before each scan |

From `frontend/lib/screens/scan/scan_screen.dart`,
`frontend/lib/widgets/scan/scan_mode_widgets.dart` and
`frontend/lib/services/ai/ai_service.dart`:

- **Guests** always scan on the device with the offline models. The
  confirmation sheet shows "Guest scans are always processed on this
  phone." instead of a choice, and `AIService` routes a guest to the
  device even if Online were requested. There is no online option.
- **Signed-in users** pick **Online** or **On-device** in the
  confirmation sheet before each scan. The choice is saved
  (`SettingsService.setScanMode`) and preselected next time; a new
  install starts on Online.
- **Privacy notice**: before a signed-in user's first online scan the app
  shows "Online scanning: Online scans are processed by a third-party
  service. For sensitive documents, use On-device." with **Continue
  online** or **Use On-device**; closing it cancels the scan. Once Online
  is accepted it is not shown again, until the settings are reset.
- **Online path**: every online scan goes through the backend, which
  requires login and allows **one scan at a time per user** (a second one
  gets "A scan is already running…") and **30 scans per hour and 100 per
  day per user** (`SCAN_LIMIT_PER_HOUR`, `SCAN_LIMIT_PER_DAY`; counted in
  memory, reset when the backend restarts).
- **When an online scan fails** (no connection, timeout, AI service or
  hosted API error, hosted daily cap, or the user's scan limit), the app
  shows why and offers **Scan on this device** or **Not now**. Each scan
  is sent online at most once, with its own `Idempotency-Key`; there is no
  automatic online retry and no switch without the teacher's choice. A
  running scan or an invalid image gets only a message.
- **Every result screen** states how the page was processed: "Processed
  online (PaddleOCR-VL).", "Processed on this device." or "Processed on
  this device, because the online scan did not finish." (The label is on
  the result screen after a scan; History does not show it.)
- `AI_SCAN_MODE` (`--dart-define`) is read by `AIService`, but the scan
  screen creates its `AIService` with `session` explicitly, so the define
  does not change these rules.

## Online pipeline (signed-in users, "Online")

1. **App**: sends the image once to `POST /api/scan-document` with an
   `Idempotency-Key` (`frontend/lib/services/ai/ai_service.dart`).
2. **Backend** (`backend/src/routes/scan/`, `services/scan/`): login
   required; image type and size checked (20 MB); one scan in flight per
   user; 30 scans per hour and 100 per day per user (in memory, reset on
   restart); a repeated key replays the saved answer instead of scanning
   again. Errors carry a code and whether an on-device scan is worth
   offering.
3. **AI service** (`ai_service/services/ocr/paddleocr_vl_service.py`):
   - prepare: EXIF orientation fixed, longest edge above 2000 px scaled
     down (Lanczos), re-encoded as JPEG quality 88;
   - recognise, one image at a time, with one of two engines
     (`PADDLEOCR_ENGINE`):
     - `local` (default): PaddleOCR-VL pipeline v1.6 on this machine's GPU
       (`paddleocr[doc-parser]` 3.7.0, `paddlepaddle-gpu` 3.2.1);
     - `official_api`: PaddleOCR's hosted API (Baidu AI Studio), through
       `official_api_client.py`: one asynchronous job per image, never
       resubmitted, a daily page cap below Baidu's 3,000 pages, and only
       the block fields kept (Baidu's image links are dropped);
   - structure: blocks get a unique reading order and id
     (`block_ordering.py`); tables are parsed from HTML into rows
     (`table_content_parser.py`); text is normalised
     (`ocr_content_normalizer.py`);
   - check formulas with the guard (below), then translate with Liblouis:
     text to UEB Grade 2 (`en-ueb-g2.ctb`), formulas and table rows to
     Nemeth (`en-us-mathtext.ctb`, after `braille_math_normalizer.py`).
4. **Backend** saves the result in the user's history (PostgreSQL) and
   returns it.

Timeouts are ordered so each layer reports why it stopped: hosted job
150 s, backend waiting for the AI service 170 s, app waiting for the
backend 180 s (marked provisional in `ai_service_client.js`).

If an online scan fails with a code that allows it, the app **offers**
to scan on the device; it never switches without the teacher choosing
it (`frontend/lib/screens/scan/scan_screen.dart`).

## On-device pipeline (guests, and "On-device" for signed-in users)

Runs on the phone's CPU with ONNX Runtime Android 1.21.1, 4 threads
(`OfflineDocumentPipeline.kt`, `offline_ocr_service.dart`):

1. `PP-DocLayoutV3`: page regions and reading order.
2. `PP-OCRv6` tiny detector + small recogniser: text lines.
3. Lines inside formula regions are set aside; formula regions are
   cropped and read by `PP-FormulaNet_plus-S` (LaTeX).
4. Text that looks like algebra is rerouted to the formula model.
5. Liblouis 3.38.0, built from `frontend/third_party/liblouis` and called
   through JNI: UEB Grade 2 for text, Nemeth for formulas.

Nothing leaves the phone. Results, History and Materials of guests are
kept in a local SQLite database.

## What differs

| | Online | On-device |
|---|---|---|
| who | signed-in users (default) | guests always; signed-in users by choice |
| recogniser | PaddleOCR-VL 1.6 (local GPU) or the hosted API | PP-DocLayoutV3 + PP-OCRv6 + PP-FormulaNet_plus-S |
| tables | parsed into rows, Braille per row (Nemeth) | read as text |
| held for review (no Braille) | roots, unsupported LaTeX, alignment markup, English words in formulas, leftover markup | roots only |
| flagged for a check (Braille kept) | — | low OCR confidence, a formula that failed or did not finish, fallback blocks |
| where the image goes | backend, AI service and, with the hosted engine, Baidu | nowhere |
| history | PostgreSQL, per account | SQLite on the phone |

## Braille 1 and Braille 2

Both services produce UEB Grade 2 (contracted). The app can show text as
**Braille 2** (contracted, the default) or **Braille 1** (uncontracted,
every letter spelled out); it re-translates the source text on the phone
with Liblouis (`frontend/lib/services/braille/braille_mode_translator.dart`).
Nemeth math and tables are never changed by this setting.

## Not part of the app

- `frontend/third_party/llama.cpp` and `PaddleOcrVlNative.kt` /
  `paddleocr_vl_bridge.cpp` are an on-device PaddleOCR-VL experiment.
  Its Dart benchmark screen (`paddle_onnx_benchmark.dart` and
  `paddleocr_vl_native_service.dart`) has been removed, so nothing in the
  app calls it any more. The native code (the Kotlin VL channel, the C++
  bridge and the llama.cpp CMake section) is still compiled into the
  Android build; removing it is a separate change.
- `tools/` holds evaluation and training tools; nothing there changes the
  app.
