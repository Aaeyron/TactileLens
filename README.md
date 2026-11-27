# TactileLens

TactileLens is an Android app that helps **teachers of visually impaired
students** turn printed lessons into Braille. Take a photo of a page with
English text, math or a table, and the app gives you:

- **English Braille (UEB)** for the words
- **Nemeth Braille** for the math

You can check the result, copy it, and save it for later.

> **Please note:** this is a school (capstone) project. The Braille has
> **not yet been checked by a Braille expert**, so always review a result
> before giving it to a student.

## What the app can do

- **Scan a page** with the camera or pick a photo from the gallery, and
  crop it if needed.
- **Choose the Braille style** for text: Braille 2 (contracted, the
  default) or Braille 1 (every letter spelled out). Math always uses
  Nemeth.
- **Hold unsure math for review.** If the app is not sure it can turn a
  formula into correct Braille, it shows the formula as text with the
  reason, instead of guessing.
- **Keep a History** of your scans and organize results and files
  (PDF, JPG, PNG) in **Materials** folders.
- **Use it without an account** (guest mode). Everything stays on your
  phone.
- **Sign in** with email or Google, and reset a forgotten password by
  email.

## Online and offline scanning

| | Online | On this phone (offline) |
|---|---|---|
| Who can use it | signed-in users | everyone, including guests |
| Where the page is read | on our server | on the phone itself |
| Needs internet | yes | no |
| Accuracy | better, especially for math | good, but weaker on harder math |

- Signed-in users choose online or offline before each scan; the app
  remembers the choice.
- If the internet drops during an online scan, the app scans the page on
  the phone instead, so you never lose a scan.
- Every result says whether it was scanned online or on the phone.
- Online scans are limited to 30 per hour and 100 per day for each user.

## Keeping results safe

- **Unsure formulas are held.** Before making Braille, the app checks
  every formula. If it contains something the Braille rules here cannot
  handle yet, the app shows it as text with a short reason. A held
  formula only means the teacher should check it; a wrong Braille
  formula could mislead a student.
- **Two readings must agree (offline).** On the phone, each formula is
  read by two models. If they disagree, the formula is held for review.
- **Square roots are always held** until a Braille expert confirms how
  they should be written in Nemeth.
- **Symbols the Braille tables don't know are held**, so they never
  show up as strange Braille codes.

## Privacy

- **Guests:** scans, History and Materials stay on the phone.
- **Online scans:** the photo is sent to our server. When the server uses
  PaddleOCR's hosted service (by Baidu), **the photo is also sent to Baidu,
  which keeps it**. Only scan material you are allowed to share.

## Try it in 5 minutes

You need an Android build of the app that includes the offline models.
Steps 1 to 4 work without a server.

1. Open the app and tap **Continue without an account**.
2. Scan a printed page with a short paragraph and an equation like
   `x² + 3x − 5 = 0`.
3. On the result, switch between **Braille 1** and **Braille 2** for the
   text. The math stays in Nemeth.
4. Scan `√(x + 9) = 5`. It is **held for review** with a reason instead
   of being turned into Braille.
5. With the server running, sign in, choose **Online**, scan again, then
   open **History** and **Materials**.

## Running it yourself

The project has three parts that work together:

1. **App:** the Android app (built with Flutter).
2. **Backend:** handles accounts, History and Materials, and passes
   online scans along (Node.js with a PostgreSQL database).
3. **AI service:** reads the page and makes the Braille (Python).

The step-by-step guide, including every setting, is in
**[docs/setup.md](docs/setup.md)**. The short version:

```
git submodule update --init --recursive

# 1. Backend (needs PostgreSQL and a backend/.env file)
cd backend && npm install && npm run dev

# 2. AI service
cd ai_service && pip install -r requirements.txt
python -m uvicorn app:app --host 127.0.0.1 --port 8000

# 3. App on a phone connected by USB
adb reverse tcp:5000 tcp:5000
cd frontend && flutter run --dart-define=AI_BASE_URL=http://127.0.0.1:5000 --dart-define=BACKEND_BASE_URL=http://127.0.0.1:5000
```

- Offline scanning needs the model files (about 390 MB). They are not in
  this repository; [docs/setup.md](docs/setup.md) explains where they go.
- The backend and AI service can be put online together with the included
  `Dockerfile` and `render.yaml` (for Render).
- Never put passwords, keys or tokens in the repository.

## Running the tests

| Part | Command |
|---|---|
| App | `cd frontend && flutter test` |
| Android (offline scanning) | `cd frontend/android && ./gradlew :app:testDebugUnitTest` |
| Backend | `cd backend && npm test` |
| AI service | `cd ai_service && python -m unittest discover -s services -t . -p "test_*.py"` |
| Training tools | see the README in each `tools/` folder |

No test sends anything to Baidu's hosted service.

## What's in this repository

```
TactileLens/
├── frontend/      the Android app (Flutter), including offline scanning
├── backend/       accounts, History, Materials and online scan limits
├── ai_service/    reads pages and makes Braille
├── docs/          setup guide, how the parts connect, training notes
└── tools/         tools for preparing data and training the models
    ├── dataset/       get new photos ready: check, sort and split them
    ├── model_prep/    train and test the offline math model
    ├── training/      train and test the offline text model
    └── training_vl/   test the online model and prepare its training data
```

Want the technical details? See [docs/architecture.md](docs/architecture.md).

## Training status

- **Online reading** uses PaddleOCR-VL as it comes. It is not retrained
  by us.
- **Offline math:** the app uses PaddleOCR's formula model, plus a second
  copy we trained on our own worksheets to double-check every formula.
  Newer versions are being trained and tested; one only goes into the app
  if it shows fewer wrong formulas than the current app.
- **Offline text:** the app uses PaddleOCR's text model as it comes. A
  version trained on our own pages was tested but is not in the app.
- Results and decisions: [docs/training_runbook.md](docs/training_runbook.md).

## Known limitations

- Square roots are held (no Braille) until a Braille expert checks the
  Nemeth rules.
- Some Nemeth spacing questions and a few UEB symbols are waiting for the
  Braille expert.
- Formulas written over several lines are often only partly read
  offline.
- Tables are written in Nemeth, and offline scans read tables as plain
  text.
- A scan cannot be cancelled once it starts.
- Online scan limits reset when the backend restarts.
- The app's Privacy screen does not yet mention that online photos may be
  sent to Baidu.
- Offline scanning and Braille 1 work on Android only; iPhone is untested.

## Credits and licenses

| Part | Used for | License |
|---|---|---|
| [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) and its models (PaddleOCR-VL, PP-DocLayoutV3, PP-OCRv6, PP-FormulaNet_plus-S) | reading pages online and offline | Apache-2.0 |
| [PaddlePaddle](https://github.com/PaddlePaddle/Paddle) | runs PaddleOCR-VL | Apache-2.0 |
| [ONNX Runtime](https://github.com/microsoft/onnxruntime) | runs the models on the phone | MIT |
| [Liblouis](https://github.com/liblouis/liblouis) | turns text and math into Braille | library: LGPL-2.1-or-later; command-line tools (used by the AI service): GPL-3.0-or-later |
| [llama.cpp](https://github.com/ggml-org/llama.cpp) | an earlier offline experiment (still built, not used by the app) | MIT |

The training tools use open fonts to draw practice images (DejaVu, STIX,
Liberation, TeX Gyre, Latin Modern; each under its own open font
license). The app itself includes no fonts.

PaddleOCR's hosted service is run by Baidu AI Studio under its own terms.
