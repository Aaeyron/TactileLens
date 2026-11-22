# Design: re-read on-device scans online when connected (lever 2)

Status: design and effort estimate only, not built (2026-11-22).

## Goal

A signed-in teacher who scans without a connection gets the on-device reading at once, as today.
Once the phone is online again, the app reads the same page online and offers that reading, which
is usually better for formulas. On the 40 tuning pages, the online service read 82 of 115
formulas; the on-device path read 38. The teacher decides whether to keep it: Braille output
never changes on its own.

Guests are out of scope. They have no server account, and online scans need one.

## What happens today (code read on main)

- An online scan is saved to History by the server (`historySavedByServer`).
- An on-device scan is saved by the app with `HistoryService.createHistory`. For signed-in users
  this is a server call.
- **Gap:** with no connection, that save fails ("History save failed"). The teacher sees the
  result, but **the scan is not kept anywhere**, so there is nothing to re-read later. The scanned
  image is also not kept: History for signed-in users stores no image (`source_image_path` is
  null on the server).
- The scan endpoint already supports an `Idempotency-Key`, so a repeated request returns the
  first answer and isn't counted twice. Per-user limits are 30 scans per hour and 100 per day.
  The hosted engine also has a daily page cap.
- There is no connectivity package in the app. Adding one would be a new dependency, which needs
  your OK.

## Design

1. **Local outbox (prerequisite).** For signed-in users, every on-device result is first written
   to a local SQLite outbox: the result, a copy of the scanned image in app storage, the time, and
   an idempotency key. The History save is retried from the outbox when the server answers. This
   alone fixes the lost-scan gap.
2. **Re-read queue.** Outbox items scanned on the device and marked `noConnection` are queued for
   an online re-read. It's a setting, on by default, with a "Wi-Fi only" option, since pages are
   uploaded.
3. **When it runs.** With no connectivity package, the queue runs:
   - on app start and resume;
   - when History opens;
   - after any successful server call;
   - from a "Read online now" button.

   It reads one page at a time with the item's idempotency key, and stops on a refusal with a
   reason (limits, quota). It never runs while a scan is in progress.
4. **Result.** The online scan creates its own History record on the server, as today, linked to
   the on-device record. A new field such as `replaces_history_id` would need a backend migration.
   The on-device record gets an "Online reading ready" badge.
5. **Teacher review.** Opening the badge shows both readings side by side, with the differences in
   formulas marked. "Use online reading" keeps the online record and archives the on-device one.
   "Keep" discards the online one. Nothing is replaced automatically. The online result goes
   through the same safety holds (formula guard, meaning holds) as any online scan.
6. **Clean-up.** Once a decision is made, or after 7 days, the local image copy is deleted.
   Images never stay on the phone longer than needed.

## Effort estimate (working days, including tests)

| Part | Days |
|---|---|
| Local outbox for signed-in on-device results + History save retry | 1.5-2 |
| Re-read queue and runner (triggers, limits, idempotency, Wi-Fi option) | 1.5-2 |
| Backend: link field + migration + tests | 1 |
| History UI: badge, side-by-side review, keep/use, archive | 1.5-2 |
| Docs, phone test (offline scan, reconnect, limits, quota refusal) | 1-1.5 |
| **Total** | **6.5-8.5** |

The outbox alone (about 2 days) is worth doing first: it fixes the lost on-device scans for
signed-in users without connection, whether or not the re-read is built.

## Risks and open points

- **Quota.** Re-reads count against the 30/hour and 100/day limits and the hosted daily page
  cap. A large backlog takes days; the queue shows what is waiting.
- **Privacy.** Page images are uploaded later than the teacher may expect. The setting and a
  first-time notice cover this.
- **Braille changes.** These are never automatic (project rule); the review step keeps the
  teacher in control.
- **Inline math.** The online gain comes partly from math inside sentences. The review view must
  show text blocks too, not only formulas.
