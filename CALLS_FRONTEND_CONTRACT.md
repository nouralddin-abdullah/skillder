# Calls — Frontend Contract (post-fix)

**Audience:** Flutter developer
**Status:** Backend changes shipped. Frontend changes required to consume them.
**Context:** Fixes the 18s `POST /api/calls` response → 409-storm bug **and** the "force-killed mid-call → stuck on cold boot" bug. See bottom of doc for the full bug timelines.

---

## TL;DR — what changed

The backend now:

1. **Returns from `POST /api/calls` immediately** (FCM no longer blocks the response).
2. **Honors `Idempotency-Key`** header — retries with the same key replay the same response for 90 seconds.
3. **Returns a richer 409** when caller/callee is busy — includes the existing call so the UI can show "rejoin" or "you're already on a call with X".
4. **Auto-cancels stale own-rings** (>5s old `ringing` rows belonging to the same caller) so a fresh attempt can succeed without manual intervention.
5. **Emits `call.snapshot` on every WS connect** with the user's current ringing/active calls so the client can rebuild UI after a cold boot / force-kill / reconnect. (Solution #3 from the call-resume discussion.)

Your job, in order of priority:

1. **P0** — Generate an `Idempotency-Key` per call attempt and send it on `POST /api/calls`. Reuse it on retries of that attempt.
2. **P0** — Find and fix the source of the 8-retries-in-2.4s storm. The backend logs showed it; it's almost certainly a UI rebuild loop or `Dio` retry interceptor misconfig.
3. **P0** — Handle the new 409 response shape: parse `existing` and route to "rejoin" / "busy" UX.
4. **P0** — Handle the `call.snapshot` WS event on every connect: rebuild ringing/active call UI from it; clear stale local state when it arrives empty.
5. **P1** — Bound retries: max 3 attempts, exponential backoff, only on network errors.
6. **P1** — Add an in-flight guard on the call button so it cannot fire twice in parallel.

---

## 1. `POST /api/calls` — new contract

### Request

```http
POST /api/calls
Authorization: Bearer <jwt>
Content-Type: application/json
Idempotency-Key: 8e9f3b6e-4d6a-4b3a-9a7e-0c2a5b8f2d11   ← NEW, optional but strongly recommended

{ "chatId": "...", "kind": "voice" | "video" }
```

**`Idempotency-Key`**:

- One UUID v4 per **user-initiated call attempt** (a fresh button tap = new key).
- Same key on retries of the same attempt = same response replayed (no new call, no 409).
- Format: 1-128 chars, `[A-Za-z0-9_\-:.]+`. UUID v4 fits.
- Server caches keyed by `(userId, idempotencyKey)` for **90 seconds**. After expiry, the key is forgotten and a fresh request creates a new call.
- If you send a malformed key, the server returns 400 `{ code: 'invalid_idempotency_key' }`. Don't retry blindly — generate a new key.

**Lifecycle rule for the key:**

```
- User taps Call → generate uuidV4 → store on the in-flight attempt
- Retry due to timeout / 5xx / network → reuse same key
- User taps Call again later (new attempt) → generate new key
- After 90s, the key is effectively dead — regenerate on next attempt
```

### Response — 201 success

```json
{
  "success": true,
  "message": "Call initiated",
  "data": {
    "callId": "...",
    "roomName": "call-...",
    "livekitUrl": "wss://...",
    "callerToken": "...",
    "idempotentReplay": true // ← NEW, present only on replayed responses
  }
}
```

`idempotentReplay: true` means "this is the second+ time you asked us with this key; here's the original answer." Treat it identically to a fresh 201 — the `callId` and `callerToken` are valid. **Do not start a second ring.** The backend re-fires the WS event and FCM to the callee in case the original delivery was lost.

### Response — 409 Conflict (richer than before)

The unique partial indexes on `calls` still enforce one active call per user. When violated, the response is now structured:

```json
{
  "statusCode": 409,
  "message": {
    "code": "caller_busy" | "callee_busy" | "busy",
    "message": "You already have an active call.",
    "existing": {
      "callId": "...",
      "status": "ringing" | "active",
      "role": "caller" | "callee",        // YOUR role in the existing call
      "chatId": "...",
      "peerId": "...",
      "peerName": "Jane Doe" | null,
      "peerPhotoUrl": "https://..." | null,
      "kind": "voice" | "video",
      "startedAt": "2026-05-15T16:08:55.756Z",
      "ageSeconds": 47
    }
  },
  "error": "Conflict"
}
```

> ⚠️ Note: `message` is the standard Nest exception shape — for 409 responses the structured payload is **under `body.message`**, not at the top level. Successful 201s use the `{ success, data }` envelope. Don't blindly assume one shape.

**`code` semantics:**

| code          | meaning                                               | UX guidance                                                                                                                                                                                                                                                                    |
| ------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `caller_busy` | You (the requesting user) already have an active call | Auto-recovery: if `existing.status==='ringing'` and `ageSeconds < 5`, retry in 1s with the **same** Idempotency-Key — the backend may auto-cancel it. Otherwise show "You're already on a call" with a "Return to call" button that re-opens the existing call UI by `callId`. |
| `callee_busy` | The user you're calling is on another call            | Show "X is busy" toast or modal. Do **not** retry automatically. Optionally offer "Try again later".                                                                                                                                                                           |
| `busy`        | Generic — couldn't disambiguate                       | Treat like `caller_busy` defensively                                                                                                                                                                                                                                           |

> Backend already auto-cancels stale own-rings before throwing 409, so in practice you should rarely see `caller_busy` for your own stale rings. The retry recommendation is a belt-and-suspenders safety net.

### Response — 400 Bad Request

- `{ code: 'invalid_idempotency_key' }` → Idempotency-Key failed format validation. Regenerate.

### Response — 403 Forbidden

- `{ code: 'chat_removed' }` → unchanged

### Response — 503 Service Unavailable

- `{ code: 'livekit_unavailable' }` → unchanged (LiveKit failed to mint token; call row was rolled back)
- `{ code: 'idempotent_request_pending' }` → **NEW**. Two requests with the same Idempotency-Key landed in parallel and the second timed out waiting (~10s) for the first to finish. Retry with the same key after a short backoff (1-2s); the cached result should be available.

---

## 2. `call.snapshot` — WS event for state recovery

**Why this exists:** When the app gets force-killed mid-call (or crashes, or the OS reaps it), the local `ActiveCallController` state is gone but the **server still has the call as `active`**. On cold boot, the user previously had no way to find their call back and was locked out of starting a new one until the LiveKit disconnect-timeout (~20s) fired server-side.

This event makes recovery proactive: every time your WS socket connects (cold boot, foreground resume, network flap reconnect), the server tells you authoritatively what calls you're currently in.

### When it fires

- **Always, on every WS connect**, immediately after authentication succeeds and the socket joins its user room. Server-side this is fired from `RealtimeGateway.handleConnection`.
- Best-effort: if the snapshot fetch fails server-side, the connect still succeeds — you just won't get the event. Don't gate other connection logic on it.
- **Once per connect.** Not periodic. Reconnect → new event.

### Event payload

The socket.io event name is `call.snapshot`. Payload:

```json
{
  "type": "call.snapshot",
  "calls": [
    {
      "callId": "3924d84f-...",
      "status": "active",                       // or "ringing"
      "role": "caller",                         // YOUR role
      "chatId": "5b4a0e07-...",
      "kind": "voice",                          // or "video"
      "roomName": "call-7fbe...",
      "livekitUrl": "wss://...",
      "livekitToken": "eyJhbGciOi...",         // freshly minted FOR YOU, valid to rejoin the room
      "peerId": "920c3962-...",
      "peerName": "Jane Doe",
      "peerPhotoUrl": "https://..." | null,
      "startedAt": "2026-05-15T17:35:38.943Z",
      "answeredAt": "2026-05-15T17:35:40.173Z", // null for ringing
      "expiresAt": null,                        // ISO for ringing, null for active
      "durationSecondsSoFar": 47                // null for ringing
    }
  ]
}
```

**`calls: []` (empty array)** is the authoritative "you have no active or ringing calls" signal. Treat it as ground truth and **clear any stale local ringing/active call state** in the controller.

### Field guide

| Field                     | When set               | Meaning                                                                                                                       |
| ------------------------- | ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `status`                  | always                 | `'ringing'` or `'active'`                                                                                                     |
| `role`                    | always                 | `'caller'` (you initiated) or `'callee'` (you received)                                                                       |
| `livekitToken`            | always                 | **Fresh** JWT minted for the user on this snapshot. Use it directly to rejoin — don't reuse the original POST response token. |
| `roomName` / `livekitUrl` | always                 | Same room you'd get from POST /api/calls / POST /accept                                                                       |
| `startedAt`               | always                 | When the row was created (ISO)                                                                                                |
| `answeredAt`              | `status === 'active'`  | When the callee accepted (ISO). `null` for `ringing`.                                                                         |
| `expiresAt`               | `status === 'ringing'` | When the ring will timeout (ISO, ~45s after `startedAt`). `null` for active.                                                  |
| `durationSecondsSoFar`    | `status === 'active'`  | Seconds since `answeredAt`. Useful for the in-call timer UI. `null` for ringing.                                              |

### How the client should handle it

```dart
// Pseudo — adapt to your controller / event bus.
socket.on('call.snapshot', (raw) {
  final snapshot = CallSnapshotEvent.fromJson(raw);
  final controller = ref.read(activeCallControllerProvider);

  if (snapshot.calls.isEmpty) {
    // Authoritative: no calls. Clear any stale local state.
    controller.clearIfNotConnected();
    return;
  }

  // For now there's at most 1 entry — backend enforces one active or
  // ringing call per user. But iterate to be safe against future changes.
  for (final call in snapshot.calls) {
    final existing = controller.currentSession;
    if (existing?.callId == call.callId && existing.status == call.status) {
      // We already know about it (e.g. duplicate snapshot after a flap).
      continue;
    }

    if (call.status == 'active') {
      // Resume the active-call UI. Use the FRESH token.
      controller.resumeActive(
        callId: call.callId,
        roomName: call.roomName,
        livekitUrl: call.livekitUrl,
        livekitToken: call.livekitToken,
        kind: call.kind,
        role: call.role,
        peer: ...,
        elapsedSeconds: call.durationSecondsSoFar ?? 0,
      );
    } else {
      // status == 'ringing'
      if (call.role == 'caller') {
        // You're the one who placed the call and it's still ringing.
        // Show the outgoing-call UI.
        controller.resumeOutgoingRing(
          callId: call.callId,
          callerToken: call.livekitToken,
          ...,
          expiresAt: call.expiresAt,
        );
      } else {
        // You're being called and you haven't picked up yet.
        // Show the incoming-call UI (same as call.incoming would).
        controller.resumeIncomingRing(
          callId: call.callId,
          peer: ...,
          expiresAt: call.expiresAt,
        );
      }
    }
  }
});
```

### Dedupe rules

- `call.snapshot` arrives on every WS connect. If you're already in a call when it arrives (e.g. network flap), and the snapshot's call matches your current session by `callId`, **do nothing** — the existing session is fine.
- If the snapshot arrives and the `callId` doesn't match what you have, **trust the server's view**. Tear down whatever you have locally and adopt the server's call (or clear if `calls: []`).
- `call.snapshot` and `call.incoming` may race when you reconnect during a ringing call. The `callId` is the same in both — dedupe on it, same as you do for the `WS + FCM` race.

### Why this doesn't break anything else

- It's **purely additive** — old clients that don't listen to `call.snapshot` keep working exactly as before.
- No new HTTP endpoint, no new permissions, no DB migration.
- Empty snapshot doesn't fire any side-effect on the server.

---

## 3. Required client behavior

### 3.1 Idempotency-Key generation (P0)

```dart
// pseudo — adapt to your HTTP layer
class CallInitiateRequest {
  final String chatId;
  final String kind;
  final String idempotencyKey;   // fresh per attempt

  CallInitiateRequest({required this.chatId, required this.kind})
    : idempotencyKey = const Uuid().v4();
}

// Send via header:
dio.post(
  '/api/calls',
  data: {'chatId': req.chatId, 'kind': req.kind},
  options: Options(headers: {'Idempotency-Key': req.idempotencyKey}),
);
```

**Lifetime:** The key must outlive a single HTTP attempt — if you retry due to timeout / network drop / 5xx, **reuse the same key**. If the user closes the app and re-taps Call later, that's a new attempt → new key.

Store the key alongside the in-flight call attempt state (the same place you're tracking `isCallStarting`). Don't put it in URL params or a global singleton.

### 3.2 In-flight guard (P0)

While a `POST /api/calls` is pending **for the current attempt**, the call button must be disabled and no new request can fire. The 8 retries in 2.4 seconds in the original logs is the bug to kill here.

Look for state bugs first:

- Is `onPressed` firing on rebuild because the Future isn't memoized?
- Is the call button rendered inside a list/StreamBuilder that rebuilds on every WS event?
- Does the button's enabled state actually track "request in flight" vs just "user has tapped"?

Adding a guard fixes the symptom; finding the source matters because the same pattern likely exists on other endpoints (chat send, profile save, etc.).

### 3.3 Retry policy (P1)

Replace any default retry interceptor with explicit policy on `POST /api/calls`:

| Outcome                            | Retry?                                                       |
| ---------------------------------- | ------------------------------------------------------------ |
| Network error / DNS / connect fail | Yes, same key, exp backoff (500ms / 2s / 5s), max 3 attempts |
| 5xx (including 503)                | Yes, same key, exp backoff                                   |
| Timeout (your HTTP client side)    | Yes, same key, exp backoff                                   |
| 4xx (incl 409)                     | **No**                                                       |
| 201                                | Done                                                         |

**HTTP client timeout:** Set to **20 seconds** for this endpoint. The server should respond well under 1s now, but give headroom for cold starts and slow networks.

### 3.4 409 handling (P0)

```dart
on 409:
  final body = error.response.data['message']; // structured payload here
  final code = body['code'];
  final existing = body['existing'];

  if (code == 'caller_busy') {
    if (existing != null
        && existing['status'] == 'ringing'
        && existing['ageSeconds'] < 5) {
      // Backend may still be racing the auto-cancel. One retry with the SAME key after 1s.
      delayed(1.sec).then((_) => retrySameKey());
    } else {
      // Genuine: user is on a real call already
      navigateToActiveCall(existing['callId']);  // or show "Rejoin?" prompt
    }
  } else if (code == 'callee_busy') {
    toast("${existing?['peerName'] ?? 'User'} is busy");
  }
```

### 3.5 Server replay flag

When the response includes `"idempotentReplay": true`, your handler should:

- **NOT** start a new ringing sound / UI (it's already running on the original attempt's listener).
- Treat the `callId`/`callerToken` as canonical (no different from a fresh 201 in their validity).
- If the local state was reset (e.g. you killed and reopened the app mid-attempt), use the response to restore the ringing/active call UI.

---

## 4. Backend-side behavior the client can rely on

These are implementation details — useful for debugging but don't hard-code assumptions beyond the API contract.

### 4.1 Idempotency cache

- Redis-backed, scoped by `(userId, idempotencyKey)`.
- TTL: **90 seconds** from the moment the original request completes.
- Concurrent requests with the same key are serialized — second one waits up to 10s for the first to finish, then either replays the cached response or returns 503 `idempotent_request_pending`.
- Failed requests (5xx, exceptions) **do not** populate the cache — the lock is released so a retry can re-attempt the work fresh.

### 4.2 FCM is now non-blocking + bounded

- `POST /api/calls` no longer awaits FCM before responding. The HTTP response returns as soon as the DB row is committed and the LiveKit token is minted.
- FCM is **always** fired (regardless of WS connection state) because WS-connected doesn't guarantee delivery (zombie sockets, iOS App Nap). Your existing dedupe by `callId` in `active_call_controller.dart` is what makes this safe.
- Each token send has a **3-second timeout** at the backend. Slow/dead tokens no longer poison the request.
- Invalid tokens are still auto-pruned from `device_tokens`.

### 4.3 Stale-ring auto-cancel

- When a new `POST /api/calls` would violate the caller-busy unique index, the server checks if the existing `ringing` row from the same caller is older than 5 seconds.
- If yes: it auto-cancels that old call (fires `call.cancelled` events as if the caller had cancelled normally), then retries the insert **once**.
- If no (existing call is younger or status='active'): returns 409 with `existing` info.
- Net effect: if your client crashed mid-call and reopens, the user can place a new call after 5s without any manual cleanup. The cancelled-by-stale-recovery call still produces a `call.cancelled` system message in the chat.

> Note: this only auto-recovers `ringing` rows. An **`active`** call from the same caller is NOT auto-cancelled — that's what `call.snapshot` (§2) is for. The client gets a snapshot on connect and decides whether to resume or end the call.

### 4.4 WS dispatch on replay

When a request is replayed via Idempotency-Key, the server re-emits the original `call.incoming` WS event to the callee and re-fires FCM. This is a best-effort retry for delivery — the client must still dedupe by `callId`.

### 4.5 `call.snapshot` emission rules

- Fires from `RealtimeGateway.handleConnection` after JWT auth + user-room join.
- Fetches `ringing` + `active` calls for the user, mints a **fresh LiveKit token per call** (TTL = `MAX_CALL_DURATION_S` = 4h), and emits as a single payload.
- Best-effort: emission failures are logged but don't block the connection.
- Token freshness means you can use it directly — don't fall back to whatever token you cached locally before the kill.

---

## 5. Backend changes (for your awareness, not action)

Files touched:

| File                                                      | Change                                                                                                                                   |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `src/core/redis/redis.module.ts`                          | NEW — global ioredis client provider                                                                                                     |
| `src/core/redis/redis.service.ts`                         | NEW — shared Redis singleton                                                                                                             |
| `src/core/notifications/fcm.service.ts`                   | Per-token 3s timeout via `Promise.race`                                                                                                  |
| `src/features/calls/services/call-idempotency.service.ts` | NEW — Idempotency-Key cache + lock                                                                                                       |
| `src/features/calls/services/calls.service.ts`            | Async FCM, stale-ring recovery, 409 enrichment, idempotency wiring, replay refanout, single-query user fetch, `getActiveCallsSnapshot()` |
| `src/features/calls/controllers/calls.controller.ts`      | Reads `Idempotency-Key` header, validates format                                                                                         |
| `src/features/calls/dto/initiate-call-result.dto.ts`      | Added `ExistingCallDTO`, `CallBusyConflictDTO`, `idempotentReplay` field                                                                 |
| `src/features/calls/dto/call-snapshot.dto.ts`             | NEW — `CallSnapshot` / `CallSnapshotEvent` types                                                                                         |
| `src/features/calls/calls.module.ts`                      | Registered `CallIdempotencyService`; ChatModule import now via `forwardRef`                                                              |
| `src/features/chat/chat.module.ts`                        | Imports `CallsModule` via `forwardRef` (so gateway can resolve `CallsService`)                                                           |
| `src/features/chat/gateways/realtime.gateway.ts`          | Emits `call.snapshot` on connect (always, including empty)                                                                               |
| `src/app.module.ts`                                       | Registered `RedisModule`                                                                                                                 |

No DB migration required — only behavior changed, schema is untouched.

No new environment variables required — Redis was already configured for BullMQ.

---

## 6. Test checklist

When you have the client changes ready, here's what we should verify end-to-end:

- [ ] **Happy path** — Caller taps Call once, gets ring within 1s. (Baseline.)
- [ ] **Slow network simulator** — kill the HTTP response packet, let the client time out → it retries with the same key → second attempt either gets the cached 201 or sees `idempotentReplay: true`. Only **one** ringing UI appears on the callee. Caller does **not** see a 409.
- [ ] **Stale ring recovery** — Force-kill the app while a call is ringing. Reopen, wait 6 seconds, place a new call. It should succeed (the stale call gets auto-cancelled). The previous chat shows a "📞 Voice call · 0:00" system message with `endReason: cancelled`.
- [ ] **Genuine callee_busy** — User A calls User B, User B picks up. From a second device or session as User C (matched with B), try to call B → 409 with `code: 'callee_busy'`, `existing.peerName = 'User B'`, `status: 'active'`. UI shows "B is busy".
- [ ] **In-flight guard** — Spam-tap the Call button 10x rapidly. The backend should see exactly **one** `POST /api/calls`. If you see >1 in the server logs, the client guard isn't working.
- [ ] **No idempotency key (degraded)** — Old clients without `Idempotency-Key` still work, just without retry safety. Backend treats this as a normal request.
- [ ] **Replay dedupe in active_call_controller** — When `idempotentReplay: true` arrives and a ringing UI is already up for that `callId`, no second ring/sound triggers.
- [ ] **Cold-boot mid-active-call recovery (the main snapshot test)** — A calls B, B accepts, both are in an active call. Force-kill A's app. Reopen A. Within ~1s of WS connect, A should receive `call.snapshot` with the active call and **resume the in-call UI**, rejoined to the LiveKit room with the fresh token. B's call stays continuous throughout. A should be able to end the call from the resumed UI.
- [ ] **Cold-boot mid-ringing recovery (caller side)** — A places a call, force-kill A's app before B picks up (within 45s). Reopen A. `call.snapshot` should deliver the still-ringing call with `role: 'caller'` and `status: 'ringing'`. UI should show the outgoing-ring screen with the remaining time derived from `expiresAt`.
- [ ] **Cold-boot mid-ringing recovery (callee side)** — A places a call, B's app is killed before pickup. B opens app; `call.snapshot` includes the ring with `role: 'callee'`. Show the incoming-call UI.
- [ ] **Empty snapshot clears stale state** — Manually corrupt the local controller state to point at a `callId` that no longer exists server-side. Reconnect WS. The empty `calls: []` snapshot should clear that stale state without flicker.
- [ ] **Snapshot + call.incoming race** — Place a call to B at the exact moment B's WS reconnects. B should receive both `call.snapshot` (with the new ring) and `call.incoming` (separate event). The controller's existing `callId` dedupe should ensure only one ringing UI shows.

---

## 7. The original bugs, for the record

### Bug #1: 18s response + 409 storm (2026-05-15 16:08–16:09)

- `POST /api/calls` request #47 took **17,919 ms** to respond with 201. FCM was awaited inline and one of the callee's tokens was slow/dead, blocking the response.
- During those 18 seconds, the client timed out and retried. Each retry hit the unique partial index `idx_calls_one_per_caller_active` → **409 `caller_busy`**.
- After the caller's WS reconnected (~16:09:09), the client fired **8 `POST /api/calls` in 2.4 seconds**, all 409 — locked out because the slow-but-eventually-successful call from #47 was still in `ringing` state.

Fix: §1 (async FCM), §3.1 (idempotency), §4.3 (stale recovery).

### Bug #2: cold-boot stuck after force-kill mid-call (2026-05-15 17:35)

- A called B, B accepted (`callId = 3924d84f-…`). Both in active call.
- 17:35:43 — A's WS disconnects (app force-killed).
- 17:35:47 — A reopens cold. Hits `/users/me`, WS reconnects. **No call state**.
- A's `ActiveCallController._session` was in-memory only → gone.
- Server's `calls` row still `status='active'`. LiveKit hasn't fired `participant_disconnected` yet (default ~20s timeout).
- A's unique partial index `idx_calls_one_per_caller_active` now blocks any new `POST /api/calls` with **409 `caller_busy`**. A has no UI for the call and no way to recover.

Fix: §2 (`call.snapshot` on every WS connect — server proactively tells A "here's your active call and a fresh token to rejoin"). The Flutter side just needs to consume the event and rebuild controller state from it.

The architectural fix (this PR) eliminates both the cause (sync FCM in request path) and the lockout (idempotency replay + stale-ring recovery + structured 409). The Flutter retry-storm is the **client-side root cause** that we should still investigate and kill — it's likely lurking elsewhere too.
