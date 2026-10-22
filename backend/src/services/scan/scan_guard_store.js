// ==========================
// Scan guard storage
// ==========================
//
// What the per-user scan limits, the one-scan-at-a-time lock and the
// Idempotency-Key need from storage. Every method is async so a
// PostgreSQL version can replace InMemoryScanGuardStore without changing
// the callers.
//
// IMPORTANT: InMemoryScanGuardStore keeps everything in Node's memory, so
// counts, locks and saved results reset whenever Node restarts (on
// Render's free tier: after every sleep and every redeploy). Until the
// PostgreSQL version is added with the hosting changes, the limits only
// hold within one running period of the server. Nothing can cost money
// because of this: the AI service's daily page cap and Baidu's own
// limit still apply.
//
// Interface:
//   beginScan({ userId, idempotencyKey, now }) resolves to one of
//     { outcome: "replay", statusCode, body }  same key already answered
//     { outcome: "in_progress" }               a scan is already running
//     { outcome: "limited", code, retryAfterSeconds }
//     { outcome: "started" }                   counted and locked
//   completeScan({ userId, idempotencyKey, statusCode, body, now })
//     saves the answer for the key (if any) and releases the lock.
//   abandonScan({ userId, idempotencyKey })
//     releases the lock without saving (the scan never reached the AI).

const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

const DEFAULT_LIMITS = {
  perHour: 30,
  perDay: 100,
  // How long an answer is replayed for the same Idempotency-Key.
  resultTtlMs: DAY_MS,
  // Answers kept per user; the oldest is dropped first.
  savedResultsPerUser: 20,
};

class InMemoryScanGuardStore {
  constructor(limits = {}) {
    this.limits = { ...DEFAULT_LIMITS, ...limits };
    this.users = new Map();
  }

  async beginScan({ userId, idempotencyKey, now }) {
    const user = this.#user(userId, now);

    if (idempotencyKey) {
      const saved = user.keys.get(idempotencyKey);

      if (saved?.state === "done") {
        return { outcome: "replay", statusCode: saved.statusCode, body: saved.body };
      }

      if (saved?.state === "in_progress") {
        return { outcome: "in_progress" };
      }
    }

    if (user.inFlight) {
      return { outcome: "in_progress" };
    }

    const lastHour = user.attempts.filter((time) => time > now - HOUR_MS);

    if (lastHour.length >= this.limits.perHour) {
      return limited("scan_hourly_limit", lastHour[0] + HOUR_MS - now);
    }

    if (user.attempts.length >= this.limits.perDay) {
      return limited("scan_daily_limit", user.attempts[0] + DAY_MS - now);
    }

    // Counted when started, whatever the outcome: every started scan may
    // have reached the hosted OCR service.
    user.attempts.push(now);
    user.inFlight = true;

    if (idempotencyKey) {
      user.keys.set(idempotencyKey, { state: "in_progress", savedAt: now });
    }

    return { outcome: "started" };
  }

  async completeScan({ userId, idempotencyKey, statusCode, body, now }) {
    const user = this.#user(userId, now);
    user.inFlight = false;

    if (!idempotencyKey) {
      return;
    }

    user.keys.delete(idempotencyKey);
    user.keys.set(idempotencyKey, { state: "done", statusCode, body, savedAt: now });

    const done = [...user.keys].filter(([, entry]) => entry.state === "done");

    for (const [key] of done.slice(0, -this.limits.savedResultsPerUser)) {
      user.keys.delete(key);
    }
  }

  async abandonScan({ userId, idempotencyKey }) {
    const user = this.users.get(userId);

    if (!user) {
      return;
    }

    user.inFlight = false;

    if (idempotencyKey && user.keys.get(idempotencyKey)?.state === "in_progress") {
      user.keys.delete(idempotencyKey);
    }
  }

  #user(userId, now) {
    let user = this.users.get(userId);

    if (!user) {
      user = { inFlight: false, attempts: [], keys: new Map() };
      this.users.set(userId, user);
    }

    // Forget what no longer matters, so memory stays small.
    user.attempts = user.attempts.filter((time) => time > now - DAY_MS);

    for (const [key, entry] of user.keys) {
      if (entry.state === "done" && entry.savedAt <= now - this.limits.resultTtlMs) {
        user.keys.delete(key);
      }
    }

    return user;
  }
}

const limited = (code, retryAfterMs) => ({
  outcome: "limited",
  code,
  retryAfterSeconds: Math.max(1, Math.ceil(retryAfterMs / 1000)),
});

const limitsFromEnvironment = () => {
  const read = (name, fallback) => {
    const value = Number(process.env[name]);
    return Number.isInteger(value) && value > 0 ? value : fallback;
  };

  return {
    perHour: read("SCAN_LIMIT_PER_HOUR", DEFAULT_LIMITS.perHour),
    perDay: read("SCAN_LIMIT_PER_DAY", DEFAULT_LIMITS.perDay),
  };
};

module.exports = {
  DEFAULT_LIMITS,
  InMemoryScanGuardStore,
  limitsFromEnvironment,
};
