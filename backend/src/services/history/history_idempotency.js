// Idempotency-Key for saving History (POST /api/history), the same idea as
// for scans (scan_guard_store.js): the first answer for a user's key is kept,
// and a repeat with that key gets it back instead of storing the scan again.
// The app sends a key with every save; an offline scan that syncs later uses
// the same key on every attempt, so a save whose answer was lost is not
// stored twice.
//
// Kept in memory for KEEP_MS, like the scan keys: a repeat after a server
// restart is not recognized.

const KEEP_MS = 24 * 60 * 60 * 1000;
const KEY_PATTERN = /^[A-Za-z0-9_-]{8,100}$/;

class HistoryIdempotencyStore {
  constructor({ keepMs = KEEP_MS } = {}) {
    this.keepMs = keepMs;
    this.entries = new Map();
  }

  static isValidKey(key) {
    return typeof key === "string" && KEY_PATTERN.test(key);
  }

  _id(userId, key) {
    return `${userId}:${key}`;
  }

  _prune(now) {
    for (const [id, entry] of this.entries) {
      if (now - entry.savedAt > this.keepMs) {
        this.entries.delete(id);
      }
    }
  }

  /**
   * "new" (go ahead; the key is now in progress), "in_progress" (the same
   * save is running), or "done" with the saved answer.
   */
  begin({ userId, key, now = Date.now() }) {
    this._prune(now);
    const id = this._id(userId, key);
    const entry = this.entries.get(id);

    if (entry?.state === "done") {
      return { outcome: "done", statusCode: entry.statusCode, body: entry.body };
    }

    if (entry?.state === "in_progress") {
      return { outcome: "in_progress" };
    }

    this.entries.set(id, { state: "in_progress", savedAt: now });
    return { outcome: "new" };
  }

  /** Keeps a successful answer; any other answer frees the key for a retry. */
  complete({ userId, key, statusCode, body, now = Date.now() }) {
    const id = this._id(userId, key);

    if (statusCode >= 200 && statusCode < 300) {
      this.entries.set(id, { state: "done", statusCode, body, savedAt: now });
    } else {
      this.entries.delete(id);
    }
  }
}

module.exports = { HistoryIdempotencyStore, KEEP_MS };
