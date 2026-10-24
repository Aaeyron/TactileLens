const { test, beforeEach, afterEach } = require("node:test");
const assert = require("node:assert/strict");

const {
  APP_TIMEOUT_MS,
  DEFAULT_TIMEOUT_MS,
  ScanServiceError,
  requestDocumentScan,
} = require("../src/services/scan/ai_service_client");

const SECRET = "test-service-key-not-real";
const IMAGE = { buffer: Buffer.from("png"), mimeType: "image/png", fileName: "a.png" };
const SUCCESS = { success: true, blocks: [], pages: [] };

const originalFetch = globalThis.fetch;
const originalEnvironment = { ...process.env };
let calls;

const respondWith = (status, body) => {
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    return new Response(typeof body === "string" ? body : JSON.stringify(body), {
      status,
    });
  };
};

const failWith = (error) => {
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    throw error;
  };
};

const scanError = async () => {
  try {
    await requestDocumentScan(IMAGE);
  } catch (error) {
    assert.ok(error instanceof ScanServiceError, `unexpected ${error}`);
    return error;
  }
  assert.fail("expected a ScanServiceError");
};

beforeEach(() => {
  calls = [];
  process.env.AI_SERVICE_URL = "http://ai.example.invalid/";
  process.env.AI_SERVICE_SECRET = SECRET;
  delete process.env.AI_SCAN_TIMEOUT_MS;
});

afterEach(() => {
  globalThis.fetch = originalFetch;
  process.env = { ...originalEnvironment };
});

test("sends the service key to the AI service", async () => {
  respondWith(200, SUCCESS);

  assert.deepEqual(await requestDocumentScan(IMAGE), SUCCESS);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, "http://ai.example.invalid/api/scan-document");
  assert.equal(calls[0].options.headers["X-Service-Key"], SECRET);
});

test("sends no key header when no secret is configured", async () => {
  delete process.env.AI_SERVICE_SECRET;
  respondWith(200, SUCCESS);

  await requestDocumentScan(IMAGE);
  assert.equal(calls[0].options.headers["X-Service-Key"], undefined);
});

test("timeouts are in order: AI 150 s < Node < app", () => {
  assert.ok(150000 < DEFAULT_TIMEOUT_MS);
  assert.ok(DEFAULT_TIMEOUT_MS < APP_TIMEOUT_MS);
});

test("each hosted OCR code keeps its status and recommends the fallback", async () => {
  const cases = [
    ["hosted_ocr_quota", 503],
    ["hosted_ocr_unavailable", 503],
    ["hosted_ocr_failed", 502],
    ["hosted_ocr_timeout", 504],
  ];

  for (const [code, status] of cases) {
    respondWith(status, { detail: { code, message: `public ${code}` } });

    const error = await scanError();
    assert.equal(error.code, code);
    assert.equal(error.statusCode, status);
    assert.equal(error.message, `public ${code}`);
    assert.equal(error.fallbackRecommended, true);
  }

  // Each scan was sent once; nothing is retried here.
  assert.equal(calls.length, cases.length);
});

test("an unreachable AI service is 503 with the fallback", async () => {
  failWith(new TypeError("fetch failed"));

  const error = await scanError();
  assert.deepEqual(
    [error.statusCode, error.code, error.fallbackRecommended],
    [503, "ai_unavailable", true],
  );
  assert.equal(calls.length, 1);
});

test("Node's own timeout is 504 with the fallback", async () => {
  failWith(Object.assign(new Error("timed out"), { name: "TimeoutError" }));

  const error = await scanError();
  assert.deepEqual(
    [error.statusCode, error.code, error.fallbackRecommended],
    [504, "ai_timeout", true],
  );
});

test("a rejected service key is not passed on as the user's 403", async () => {
  respondWith(403, { detail: "Forbidden" });

  const error = await scanError();
  assert.deepEqual([error.statusCode, error.code], [503, "ai_unavailable"]);
});

test("a bad image keeps its status and does not recommend the fallback", async () => {
  respondWith(415, { detail: "The uploaded file is not a valid image." });

  const error = await scanError();
  assert.deepEqual(
    [error.statusCode, error.code, error.fallbackRecommended],
    [415, "invalid_image", false],
  );
  assert.equal(error.message, "The uploaded file is not a valid image.");
});

test("other AI failures are 502 with the fallback", async () => {
  for (const [status, body] of [
    [500, { detail: "The document could not be processed." }],
    [502, "<html>bad gateway</html>"],
    [200, { success: false }],
  ]) {
    respondWith(status, body);

    const error = await scanError();
    assert.deepEqual(
      [error.statusCode, error.code, error.fallbackRecommended],
      [502, "ai_failed", true],
    );
  }
});

test("a missing AI_SERVICE_URL is reported, not sent", async () => {
  delete process.env.AI_SERVICE_URL;
  respondWith(200, SUCCESS);

  const error = await scanError();
  assert.equal(error.code, "ai_not_configured");
  assert.equal(calls.length, 0);
});

test("AI_SCAN_TIMEOUT_MS overrides the default", async () => {
  process.env.AI_SCAN_TIMEOUT_MS = "5000";
  respondWith(200, SUCCESS);

  await requestDocumentScan(IMAGE);
  assert.ok(calls[0].options.signal instanceof AbortSignal);
});
