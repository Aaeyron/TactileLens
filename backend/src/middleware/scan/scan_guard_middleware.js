// ==========================
// Scan guard: per-user limits, one scan at a time, Idempotency-Key
// ==========================
//
// Runs before the upload is read. The store decides; see
// services/scan/scan_guard_store.js. With the in-memory store, counts and
// saved answers reset when Node restarts, until the PostgreSQL version is
// added with the hosting changes.
//
// The app sends a new Idempotency-Key for each scan the teacher starts.
// A repeated request with the same key gets the saved answer instead of a
// second scan. Requests without a key are still limited and locked.

const IDEMPOTENCY_KEY = /^[A-Za-z0-9_-]{8,128}$/;

const LIMIT_MESSAGES = {
  scan_hourly_limit: "You have reached the online scan limit for this hour.",
  scan_daily_limit: "You have reached the online scan limit for today.",
};

const createScanGuard = ({ store, now = Date.now }) =>
  async function scanGuard(req, res, next) {
    const userId = req.user.id;
    const idempotencyKey = req.get("Idempotency-Key");

    if (idempotencyKey !== undefined && !IDEMPOTENCY_KEY.test(idempotencyKey)) {
      return res.status(400).json({
        success: false,
        message: "The Idempotency-Key header is not valid.",
        code: "invalid_idempotency_key",
        fallback_recommended: false,
      });
    }

    const decision = await store.beginScan({ userId, idempotencyKey, now: now() });

    if (decision.outcome === "replay") {
      res.set("Idempotent-Replay", "true");
      return res.status(decision.statusCode).json(decision.body);
    }

    if (decision.outcome === "in_progress") {
      return res.status(409).json({
        success: false,
        message: "A scan is already in progress for this account.",
        code: "scan_in_progress",
        fallback_recommended: false,
      });
    }

    if (decision.outcome === "limited") {
      res.set("Retry-After", String(decision.retryAfterSeconds));

      return res.status(429).json({
        success: false,
        message: LIMIT_MESSAGES[decision.code],
        code: decision.code,
        fallback_recommended: true,
        retry_after_seconds: decision.retryAfterSeconds,
      });
    }

    let settled = false;

    req.scanGuard = {
      // Called by the controller with the answer it sends.
      complete: async (statusCode, body) => {
        if (settled) return;
        settled = true;
        await store.completeScan({ userId, idempotencyKey, statusCode, body, now: now() });
      },
    };

    // If the request ends before the controller answers (for example an
    // upload error), release the lock without saving anything. Once the
    // controller has started a scan it always calls complete, even if the
    // app disconnects, so the lock is held until the AI call is over.
    const release = () => {
      if (settled || req.scanStarted) return;
      settled = true;
      store.abandonScan({ userId, idempotencyKey });
    };

    res.on("finish", release);
    res.on("close", release);

    return next();
  };

module.exports = {
  createScanGuard,
};
