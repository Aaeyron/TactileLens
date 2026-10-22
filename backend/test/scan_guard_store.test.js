const { test } = require("node:test");
const assert = require("node:assert/strict");

const {
  DEFAULT_LIMITS,
  InMemoryScanGuardStore,
} = require("../src/services/scan/scan_guard_store");

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;

// Starts and completes one scan, as the controller does.
const scan = async (store, now, { userId = 1, idempotencyKey } = {}) => {
  const decision = await store.beginScan({ userId, idempotencyKey, now });

  if (decision.outcome === "started") {
    await store.completeScan({
      userId,
      idempotencyKey,
      statusCode: 200,
      body: { success: true, at: now },
      now,
    });
  }

  return decision;
};

test("defaults are 30 an hour and 100 a day", () => {
  assert.equal(DEFAULT_LIMITS.perHour, 30);
  assert.equal(DEFAULT_LIMITS.perDay, 100);
});

test("the 31st scan in an hour is limited until the oldest is an hour old", async () => {
  const store = new InMemoryScanGuardStore();

  for (let index = 0; index < 30; index++) {
    assert.equal((await scan(store, index * MINUTE)).outcome, "started");
  }

  const decision = await scan(store, 30 * MINUTE);
  assert.deepEqual(decision, {
    outcome: "limited",
    code: "scan_hourly_limit",
    retryAfterSeconds: 30 * 60,
  });

  // An hour after the first scan, one slot is free again.
  assert.equal((await scan(store, HOUR + 1)).outcome, "started");
});

test("the 101st scan in 24 hours is limited", async () => {
  const store = new InMemoryScanGuardStore();

  // 100 scans spread over 20 hours, never more than 30 in an hour.
  for (let index = 0; index < 100; index++) {
    assert.equal((await scan(store, index * 12 * MINUTE)).outcome, "started");
  }

  const decision = await scan(store, 100 * 12 * MINUTE);
  assert.equal(decision.outcome, "limited");
  assert.equal(decision.code, "scan_daily_limit");

  // 24 hours after the first scan it is allowed again.
  assert.equal((await scan(store, 24 * HOUR + 1)).outcome, "started");
});

test("only one scan at a time per user", async () => {
  const store = new InMemoryScanGuardStore();

  assert.equal((await store.beginScan({ userId: 1, now: 0 })).outcome, "started");
  assert.equal((await store.beginScan({ userId: 1, now: 1 })).outcome, "in_progress");

  // Other users are not affected.
  assert.equal((await store.beginScan({ userId: 2, now: 1 })).outcome, "started");

  await store.completeScan({ userId: 1, statusCode: 200, body: {}, now: 2 });
  assert.equal((await store.beginScan({ userId: 1, now: 3 })).outcome, "started");
});

test("an abandoned scan releases the lock but still counts", async () => {
  const store = new InMemoryScanGuardStore({ perHour: 1 });

  await store.beginScan({ userId: 1, now: 0 });
  await store.abandonScan({ userId: 1 });

  const decision = await store.beginScan({ userId: 1, now: 1 });
  assert.equal(decision.code, "scan_hourly_limit");
});

test("the same Idempotency-Key replays the saved answer without counting", async () => {
  const store = new InMemoryScanGuardStore({ perHour: 1 });
  const key = "scan-key-0001";

  assert.equal((await scan(store, 0, { idempotencyKey: key })).outcome, "started");

  const replay = await store.beginScan({ userId: 1, idempotencyKey: key, now: 5 });
  assert.deepEqual(replay, {
    outcome: "replay",
    statusCode: 200,
    body: { success: true, at: 0 },
  });

  // A new key is a new scan, and the hourly limit of 1 still applies.
  const fresh = await store.beginScan({ userId: 1, idempotencyKey: "scan-key-0002", now: 6 });
  assert.equal(fresh.outcome, "limited");
});

test("a key that is still running answers in_progress", async () => {
  const store = new InMemoryScanGuardStore();
  const key = "scan-key-0001";

  await store.beginScan({ userId: 1, idempotencyKey: key, now: 0 });

  const again = await store.beginScan({ userId: 1, idempotencyKey: key, now: 1 });
  assert.equal(again.outcome, "in_progress");
});

test("keys belong to one user", async () => {
  const store = new InMemoryScanGuardStore();
  const key = "shared-key-01";

  await scan(store, 0, { userId: 1, idempotencyKey: key });

  const other = await store.beginScan({ userId: 2, idempotencyKey: key, now: 1 });
  assert.equal(other.outcome, "started");
});

test("an abandoned key can be used again", async () => {
  const store = new InMemoryScanGuardStore();
  const key = "scan-key-0001";

  await store.beginScan({ userId: 1, idempotencyKey: key, now: 0 });
  await store.abandonScan({ userId: 1, idempotencyKey: key });

  const again = await store.beginScan({ userId: 1, idempotencyKey: key, now: 1 });
  assert.equal(again.outcome, "started");
});

test("saved answers expire and only the newest are kept", async () => {
  const store = new InMemoryScanGuardStore({
    perHour: 100,
    perDay: 100,
    savedResultsPerUser: 2,
    resultTtlMs: HOUR,
  });

  for (const [index, key] of ["key-aaaaaaa1", "key-aaaaaaa2", "key-aaaaaaa3"].entries()) {
    await scan(store, index, { idempotencyKey: key });
  }

  // The oldest of three was dropped (only two kept).
  const oldest = await store.beginScan({ userId: 1, idempotencyKey: "key-aaaaaaa1", now: 10 });
  assert.equal(oldest.outcome, "started");
  await store.abandonScan({ userId: 1, idempotencyKey: "key-aaaaaaa1" });

  const kept = await store.beginScan({ userId: 1, idempotencyKey: "key-aaaaaaa3", now: 11 });
  assert.equal(kept.outcome, "replay");

  // After the TTL the answer is no longer replayed.
  const expired = await store.beginScan({
    userId: 1,
    idempotencyKey: "key-aaaaaaa3",
    now: HOUR + 10,
  });
  assert.equal(expired.outcome, "started");
});

test("a restart forgets everything (in-memory store)", async () => {
  let store = new InMemoryScanGuardStore({ perHour: 1 });
  await scan(store, 0);
  assert.equal((await scan(store, 1)).outcome, "limited");

  store = new InMemoryScanGuardStore({ perHour: 1 });
  assert.equal((await scan(store, 2)).outcome, "started");
});
