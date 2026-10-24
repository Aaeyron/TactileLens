// The real scan guard and controller over HTTP, with the scan service
// replaced, so no database or AI service is needed.

const { test, beforeEach, after } = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");

const { ScanServiceError } = require("../src/services/scan/ai_service_client");

const scanServicePath = path.resolve(__dirname, "../src/services/scan/scan_service.js");

let calls = 0;
let nextScan = async () => ({ success: true, blocks: [] });

require.cache[scanServicePath] = {
  id: scanServicePath,
  filename: scanServicePath,
  loaded: true,
  exports: {
    ScanServiceError,
    scanDocument: async (options) => {
      calls += 1;
      return nextScan(options);
    },
  },
};

const express = require("express");
const scanController = require("../src/controllers/scan/scan_controller");
const { createScanGuard } = require("../src/middleware/scan/scan_guard_middleware");
const { InMemoryScanGuardStore } = require("../src/services/scan/scan_guard_store");

let server;
let baseUrl;
let store;

const start = async () => {
  const app = express();

  app.post(
    "/scan",
    (req, res, next) => {
      req.user = { id: Number(req.get("X-Test-User") || 1) };
      next();
    },
    (req, res, next) => createScanGuard({ store })(req, res, next),
    // Stands in for the upload middleware.
    (req, res, next) => {
      if (req.get("X-Test-Upload-Error")) {
        return res.status(400).json({ success: false, message: "bad upload" });
      }
      req.body = {};
      return next();
    },
    scanController.scanDocument,
  );

  await new Promise((resolve) => {
    server = app.listen(0, "127.0.0.1", resolve);
  });

  baseUrl = `http://127.0.0.1:${server.address().port}`;
};

// A scan that stays running until finish() is called. started resolves
// once the controller has really begun it, so tests never race.
const blockingScan = () => {
  let finish;
  let markStarted;
  const started = new Promise((resolve) => {
    markStarted = resolve;
  });

  nextScan = () =>
    new Promise((resolve) => {
      finish = () => resolve({ success: true, blocks: [] });
      markStarted();
    });

  return { started, finish: () => finish() };
};

const post = (headers = {}) =>
  fetch(`${baseUrl}/scan`, { method: "POST", headers }).then(async (response) => ({
    status: response.status,
    headers: response.headers,
    body: await response.json(),
  }));

beforeEach(async () => {
  calls = 0;
  nextScan = async () => ({ success: true, blocks: [] });
  store = new InMemoryScanGuardStore({ perHour: 30, perDay: 100 });

  if (!server) {
    await start();
  }
});

after(() => server?.close());

test("the same Idempotency-Key gets the saved answer, not a second scan", async () => {
  nextScan = async () => ({ success: true, blocks: [], scan: calls });
  const headers = { "Idempotency-Key": "scan-5f0c9a7e" };

  const first = await post(headers);
  const second = await post(headers);

  assert.equal(first.status, 200);
  assert.deepEqual(second.body, first.body);
  assert.equal(second.headers.get("Idempotent-Replay"), "true");
  assert.equal(calls, 1);
});

test("a failed scan is replayed too, so it is never resent", async () => {
  nextScan = async () => {
    throw new ScanServiceError("The online OCR service is unavailable.", 503, "hosted_ocr_unavailable", true);
  };
  const headers = { "Idempotency-Key": "scan-0b1c2d3e" };

  const first = await post(headers);
  const second = await post(headers);

  assert.equal(first.status, 503);
  assert.equal(first.body.code, "hosted_ocr_unavailable");
  assert.equal(first.body.fallback_recommended, true);
  assert.deepEqual([second.status, second.body], [first.status, first.body]);
  assert.equal(calls, 1);
});

test("a second scan while one is running gets 409", async () => {
  const scan = blockingScan();

  const running = post();
  await scan.started;

  const second = await post();
  assert.equal(second.status, 409);
  assert.equal(second.body.code, "scan_in_progress");
  assert.equal(second.body.fallback_recommended, false);

  scan.finish();
  assert.equal((await running).status, 200);

  nextScan = async () => ({ success: true, blocks: [] });
  assert.equal((await post()).status, 200);
  assert.equal(calls, 2);
});

test("the lock is held until the AI call ends, even if the app disconnects", async () => {
  const scan = blockingScan();
  const abort = new AbortController();

  const running = fetch(`${baseUrl}/scan`, { method: "POST", signal: abort.signal }).catch(
    () => "aborted",
  );
  await scan.started;

  abort.abort();
  assert.equal(await running, "aborted");

  // The first scan is still running at the AI service: no second job.
  const second = await post();
  assert.equal(second.status, 409);

  scan.finish();
  await new Promise((resolve) => setTimeout(resolve, 50));

  nextScan = async () => ({ success: true, blocks: [] });
  assert.equal((await post()).status, 200);
  assert.equal(calls, 2);
});

test("other users can scan at the same time", async () => {
  const scan = blockingScan();

  const running = post({ "X-Test-User": "1" });
  await scan.started;

  nextScan = async () => ({ success: true, blocks: [] });
  assert.equal((await post({ "X-Test-User": "2" })).status, 200);

  scan.finish();
  assert.equal((await running).status, 200);
});

test("the hourly limit answers 429 with Retry-After and the fallback flag", async () => {
  store = new InMemoryScanGuardStore({ perHour: 2, perDay: 100 });

  assert.equal((await post()).status, 200);
  assert.equal((await post()).status, 200);

  const limited = await post();
  assert.equal(limited.status, 429);
  assert.equal(limited.body.code, "scan_hourly_limit");
  assert.equal(limited.body.fallback_recommended, true);
  assert.ok(Number(limited.headers.get("Retry-After")) > 0);
  assert.equal(calls, 2);
});

test("an upload error releases the lock and saves nothing for the key", async () => {
  const headers = { "Idempotency-Key": "scan-upload-01" };

  const failed = await post({ ...headers, "X-Test-Upload-Error": "1" });
  assert.equal(failed.status, 400);

  const retried = await post(headers);
  assert.equal(retried.status, 200);
  assert.equal(calls, 1);
});

test("a malformed Idempotency-Key is rejected before anything runs", async () => {
  const response = await post({ "Idempotency-Key": "bad key!" });

  assert.equal(response.status, 400);
  assert.equal(response.body.code, "invalid_idempotency_key");
  assert.equal(calls, 0);
});

test("requests without a key are still limited and locked", async () => {
  store = new InMemoryScanGuardStore({ perHour: 1, perDay: 100 });

  assert.equal((await post()).status, 200);
  assert.equal((await post()).status, 429);
});
