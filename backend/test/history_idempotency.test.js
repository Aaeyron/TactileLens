const { test, beforeEach } = require("node:test");
const assert = require("node:assert/strict");

const {
  HistoryIdempotencyStore,
} = require("../src/services/history/history_idempotency");
const historyService = require("../src/services/history/history_service");
const controller = require("../src/controllers/history/history_controller");

const KEY = "a1b2c3d4e5f60718";

const response = () => {
  const res = { statusCode: 0, body: null };
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (body) => {
    res.body = body;
    return res;
  };
  return res;
};

const request = ({ userId = 1, key } = {}) => ({
  user: { id: userId },
  get: (name) => (name === "Idempotency-Key" ? key : undefined),
  body: { title: "Offline scan", recognized_content: "x = 2" },
});

let saved;
let failNext;

beforeEach(() => {
  saved = [];
  failNext = false;
  controller.historyIdempotency.entries.clear();
  historyService.createHistory = async (input) => {
    if (failNext) {
      failNext = false;
      throw new Error("database down");
    }
    const record = { id: saved.length + 1, user_id: input.userId, title: input.title };
    saved.push(record);
    return record;
  };
});

test("keys: letters, digits, - and _, 8 to 100 characters", () => {
  assert.equal(HistoryIdempotencyStore.isValidKey(KEY), true);
  assert.equal(HistoryIdempotencyStore.isValidKey("short"), false);
  assert.equal(HistoryIdempotencyStore.isValidKey("has space here"), false);
  assert.equal(HistoryIdempotencyStore.isValidKey(undefined), false);
});

test("the same key twice stores the scan once and answers the same", async () => {
  const first = response();
  await controller.createHistory(request({ key: KEY }), first);
  const second = response();
  await controller.createHistory(request({ key: KEY }), second);

  assert.equal(saved.length, 1);
  assert.equal(first.statusCode, 201);
  assert.equal(second.statusCode, 201);
  assert.deepEqual(second.body, first.body);
});

test("keys are per user", async () => {
  await controller.createHistory(request({ userId: 1, key: KEY }), response());
  await controller.createHistory(request({ userId: 2, key: KEY }), response());

  assert.equal(saved.length, 2);
});

test("a failed save frees the key, so the retry saves it once", async () => {
  failNext = true;
  const failed = response();
  await controller.createHistory(request({ key: KEY }), failed);
  assert.equal(failed.statusCode, 500);
  assert.equal(saved.length, 0);

  const retry = response();
  await controller.createHistory(request({ key: KEY }), retry);
  assert.equal(retry.statusCode, 201);
  assert.equal(saved.length, 1);
});

test("while the same save is running, a repeat is refused (409), not stored", () => {
  const store = new HistoryIdempotencyStore();
  assert.equal(store.begin({ userId: 1, key: KEY }).outcome, "new");
  assert.equal(store.begin({ userId: 1, key: KEY }).outcome, "in_progress");
});

test("kept answers expire", () => {
  const store = new HistoryIdempotencyStore({ keepMs: 1000 });
  store.begin({ userId: 1, key: KEY, now: 0 });
  store.complete({ userId: 1, key: KEY, statusCode: 201, body: { ok: 1 }, now: 0 });
  assert.equal(store.begin({ userId: 1, key: KEY, now: 500 }).outcome, "done");
  assert.equal(store.begin({ userId: 1, key: KEY, now: 5000 }).outcome, "new");
});

test("a bad key is refused; no key saves as before", async () => {
  const bad = response();
  await controller.createHistory(request({ key: "no spaces allowed" }), bad);
  assert.equal(bad.statusCode, 400);

  await controller.createHistory(request(), response());
  await controller.createHistory(request(), response());
  assert.equal(saved.length, 2);
});
