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
| Signed-in user | always, when the server answers | automatically, when there is no connection |

From `frontend/lib/screens/scan/scan_screen.dart`,
`frontend/lib/widgets/scan/scan_mode_widgets.dart` and
`frontend/lib/services/ai/ai_service.dart`:

- **The mode is automatic**: there are no Online / On-device buttons.
  The confirmation sheet shows a read-only label (`ScanModeLabel`):
  "Scanning online" for a signed-in user, "Scanning on this device" for a
  guest, each with one screen-reader label. The old choice
  (`ScanModeSelector`, remembered with `SettingsService.setScanMode`) is
  kept behind a build flag that is off by default:
  `--dart-define=SCAN_MODE_CHOICE=true`.
- **Guests** always scan on the device with the offline models, and
  `AIService` routes a guest to the device even if Online were requested.
  There is no online option.
- **Signed-in users** scan online. Before the upload, `AIService` checks
  that the backend answers at all (`GET /`, 8-second
  `reachabilityTimeout`). No answer, a dropped connection, a 502/503/504
  without a server reason, `hosted_ocr_timeout`, or no answer within the
  3-minute `requestTimeout`: the page is scanned on the device instead,
  automatically, and the result says "No connection: scanned on-device."
  The scanning overlay switches to on-device when that happens. If the
  online scan timed out, the server may still finish it and save it to
  History, so the page can appear twice.
- **Privacy notice**: before a signed-in user's first online scan the app
  shows "Online scanning: Online scans are processed by a third-party
  service. For sensitive documents, scan on this device." with **Continue
  online** or **Scan on this device** (that scan only; the notice comes
  back next time); closing it cancels the scan. Once Online is accepted it
  is not shown again, until the settings are reset.
- **Online path**: every online scan goes through the backend, which
  requires login and allows **one scan at a time per user** (a second one
  gets "A scan is already running…") and **30 scans per hour and 100 per
  day per user** (`SCAN_LIMIT_PER_HOUR`, `SCAN_LIMIT_PER_DAY`; counted in
  memory, reset when the backend restarts).
- **When the server refuses an online scan with a reason** (hosted daily
  cap, the user's scan limit, another hosted API error), the app shows why
  and offers **Scan on this device** or **Not now**. Each scan is sent
  online at most once, with its own `Idempotency-Key`; there is no
  automatic online retry. A running scan or an invalid image gets only a
  message.
- **Cancelling a scan** (online only): the scanning overlay has a
  **Cancel** button. It only stops the app waiting: the request is not
  aborted, the server finishes the scan and saves it to History, and the
  app shows "This scan will finish in the background; you can scan again in
  up to 3 minutes. It may still appear in History when it finishes." A result or error that arrives later for the
  cancelled scan is dropped (`ScanRun`). Until the server finishes, a new
  online scan gets "A scan is already running…" (the server holds its
  one-scan lock until the AI service answers, at most 170 s). On-device
  scans have no Cancel: the native scan cannot be stopped and a second one
  must not run beside it. The confirmation sheet before a scan states the
  same limit: "Processing can take up to 3 minutes."
- **While a scan runs** (`ScanProgressOverlay`): four Braille cells
  spelling "scan" are written dot by dot (white on the navy card; the finish check mark is gold), fade, and repeat.
  Under them, one line names the real step, reported by `AIService.stage`
  (`ScanStage`):
  - online: "Checking the connection…", then "Reading the page online…";
  - on this device: "Preparing the scanner…" (first scan only), then
    "Reading text and math…" (one native call, so text and math are not
    separate steps), then "Converting to Braille…".

  There are no percentages. When the result is ready, all dots fill and a
  check mark is drawn (about 0.3 s), then the result opens. TalkBack reads
  the step line when it changes and "Scan complete" at the end, never the
  animation. With reduce motion the cells are still and only the step line
  changes.
  (`ScanRun.processingTimeMessage`). A full cancel is proposed in
  [Full scan cancel (proposal)](#full-scan-cancel-proposal).
- **Every result screen** states how the page was processed: "Processed
  online (PaddleOCR-VL).", "Processed on this device." or "Processed on
  this device, because the online scan did not finish."
- **History** shows each saved scan as **Online** or **On this device**
  (and "Processed online" / "Processed on this device" in its details).
  It is read from the saved `pipeline_version`: on-device scans save
  `offline-onnx-v1` (`OfflineOcrService.pipelineVersion`), anything else
  came from the server (`ScanProcessingMode.fromPipelineVersion`). No
  database change; records saved without a version show no label. Whether
  an on-device scan was a fallback after a failed online scan is not
  saved, so History does not say so.
- `AI_SCAN_MODE` (`--dart-define`) is read by `AIService`, but the scan
  screen creates its `AIService` with `session` explicitly, so the define
  does not change these rules.

## Online pipeline (signed-in users, "Online")

1. **App**: sends the image once to `POST /api/scan-document` with an
   `Idempotency-Key` (`frontend/lib/services/ai/ai_service.dart`). An
   image larger than 2000 px on its long side is first scaled down to
   2000 px (lossless PNG; `AIService.onlineUploadMaxDimension`, the same
   size the AI service scales to, checked by a test); on-device scans are
   never scaled.
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
| held for review (no Braille) | roots, unsupported LaTeX, alignment markup, English words in formulas, leftover markup; any block whose Braille contains an undefined-symbol escape (a dot-7/8 cell) | the same, except leftover markup (the app does not see the server's normalized text); same rules and reason text, kept in sync by `ai_service/services/braille/fixtures/formula_guard_shared.json` |
| flagged for a check (Braille kept) | — | low OCR confidence, a formula that failed or did not finish, fallback blocks |
| where the image goes | backend, AI service and, with the hosted engine, Baidu | nowhere |
| history | PostgreSQL, per account | SQLite on the phone |

## Image orientation

The scan screen stays portrait; turning the phone rotates the preview,
the crop box and the messages, not the layout.

- **Once, on the phone, right after capture or pick**
  (`frontend/lib/services/scan/image_orientation_service.dart`): the EXIF
  orientation is applied to the pixels, then all EXIF is removed
  (orientation, location, camera make), and the image is saved as a PNG.
  For the camera only, when the camera wrote no rotation, a photo taken
  sideways with portrait pixels is turned 90 degrees and one taken
  upside-down 180 degrees, from how the phone was held. If the camera
  wrote a rotation, it is trusted. Camera behaviour differs between
  phones; these rules are tested with generated images, not verified on
  every device.
- **Crop:** the teacher's crop is kept in image pixels, so rotating the
  phone keeps it; sideways the preview shows the part that fits.
- **Server, again before OCR** (`_prepare_image` in
  `ai_service/services/ocr/paddleocr_vl_service.py`): `ImageOps.exif_transpose`,
  since any client can send a rotated image. All 8 EXIF orientations are
  tested (`services/ocr/test_prepare_image_orientation.py`, generated
  images). The on-device pipeline also
  applies EXIF before its models.

## Braille 1 and Braille 2

Both services produce UEB Grade 2 (contracted). The app can show text as
**Braille 2** (contracted, the default) or **Braille 1** (uncontracted,
every letter spelled out); it re-translates the source text on the phone
with Liblouis (`frontend/lib/services/braille/braille_mode_translator.dart`).
Nemeth math and tables are never changed by this setting.

- If Braille 1 cannot be made, Braille 2 is shown with a visible banner
  ("Braille 1 could not be created for this page. Showing Braille 2
  (Contracted) instead."), which screen readers announce.
- Saved records say which grade they were saved in, under the mode
  buttons: History always saves Braille 2; a material saves the mode that
  was on screen (`saved_braille_mode` in each block; missing means
  Braille 2, the only grade before modes existed).

## Full scan cancel (proposal)

Not built. Today's Cancel (above) only stops the app waiting. A real
cancel needs all three layers, in this order:

1. **App**: abort the HTTP request (an `http.Client` per scan, closed on
   Cancel) and send `DELETE /api/scan-document/{Idempotency-Key}` so the
   server knows even if the connection drop is not noticed.
2. **Backend (Node)**: on the delete or a client disconnect
   (`req.on("close")`), abort the call to the AI service with an
   `AbortController`, release the user's scan lock (`abandonScan`) and do
   not save to History. The scan still counts toward the hourly and daily
   limits, since it may already have reached the hosted service.
3. **AI service (Python)**: a request that is cancelled stops between
   steps (before OCR, before Braille). A hosted PaddleOCR call already
   sent cannot be recalled and is still billed against the daily quota;
   the local engine can stop between pages only.

Open questions: whether a cancelled scan should count toward the limits
(proposed: yes), and whether History should show a scan the teacher
cancelled (proposed: no). On-device cancel would need a native stop flag
in the ONNX pipeline (an Android native change).

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
