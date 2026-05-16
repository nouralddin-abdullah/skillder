# Calls — Real Backend Contract (post-audit)

This file captures the **actual wire format** the backend ships, not the planned format. It supersedes `CALLS_PLAN.md` v2 §3 wherever they conflict. Flutter is built against this document.

Audit source: `c:/Users/sadap/Documents/skillder-backend/src/` as of 2026-05-12.

---

## 1. Response envelope (applies to EVERY endpoint)

Every JSON response — success or error — is wrapped:

```json
{
  "success": true,
  "message": "...",
  "data": { /* the documented payload, or null */ }
}
```

Flutter HTTP client must:
- Read `body['data']` to get the documented payload.
- Branch on `body['success']` for soft failures (e.g. `GET /calls/:id` for non-participant returns 200 with `success: false`).

---

## 2. Socket.IO event envelope (applies to EVERY call.* event)

Events are wrapped in `RealtimeEvent`. The fields documented in CALLS_PLAN.md §3.3 live inside `data`, not at the top level.

**Wire shape**:
```json
{
  "type": "call.incoming",
  "seq": 1234,
  "chatId": "<uuid>",
  "data": { /* event-specific payload below */ },
  "createdAt": "<ISO>"
}
```

Flutter must parse `payload['data']['callId']` etc., NOT `payload['callId']`.

---

## 3. REST endpoints — actual shapes

### `POST /api/calls` — initiate

**Request**
```json
{ "chatId": "<uuid>", "kind": "voice" | "video" }
```

**Response 201 → `data`**
```json
{
  "callId": "<uuid>",
  "roomName": "call-<callId>",
  "livekitUrl": "wss://...",
  "callerToken": "<jwt>"
}
```

**Errors**
- 403 `chat_removed` (typed code in `body.message.code`)
- 409 `callee_busy` / `caller_busy` / `busy`
- 503 `livekit_unavailable`
- 403 / 404 plain string for not-a-participant (no typed code)

Flutter rule: pattern-match on HTTP status first; use `body.message.code` only when the status is 409 (busy variants) or 403/503 with `chat_removed` / `livekit_unavailable`.

### `POST /api/calls/:id/accept`
- **Response 200 → `data`**: `{ callId, roomName, livekitUrl, calleeToken }`
- Idempotent if already `active`.
- Errors: plain-string messages, no typed codes.

### `POST /api/calls/:id/reject`
- **Response 200**: `{ "success": true, "message": "Call rejected" }` — **no `data` body, no `ok` flag.**
- Silent no-op if call is no longer ringing.

### `POST /api/calls/:id/cancel`
- Same response shape as reject.
- Silent no-op if not ringing.

### `POST /api/calls/:id/end`
- **Request**: `{ "reason": "normal" | "network" | "cellular_interrupt" }` (default `"normal"`).
- **Response 200 → `data`**: `{ ok: boolean, durationSeconds: number | null }`
- Idempotent if already ended.

### `GET /api/calls/:id`
- **Response 200 → `data`**: `CallDTO` = `{ id, chatId, callerId, calleeId, kind, status, startedAt, answeredAt, endedAt, durationSeconds, endReason }`
- Non-participant → 200 with `success: false`, `data: null`. **NOT 403.**
- `livekitRoom` is intentionally NOT exposed.

### `GET /api/chats/:chatId/calls` — **NOT IMPLEMENTED**
Service exists but no controller route. Flutter derives call history from chat system messages where `systemPayload.kind === 'call'` (see §6).

### `POST /api/devices`
- **Request**: `{ "token": "<fcm_token>", "platform": "android" | "ios" }`
- **Response 200**: `{ "success": true, "message": "Device registered" }`
- Upserts on `token`; reassigns `userId` on conflict.

### `DELETE /api/devices/:token`
- Removes only rows where token AND current userId match.
- **Response 200**: `{ "success": true, "message": "Device unregistered" }`

### `POST /api/webhooks/livekit`
- Backend-only. Flutter does not call this.

---

## 4. Socket.IO events — actual `data` payloads

All events arrive as `{ type, seq, chatId, data, createdAt }`. Below is the `data` shape per type.

### `call.incoming`
```json
{
  "callId": "<uuid>",
  "chatId": "<uuid>",
  "callerId": "<uuid>",
  "kind": "voice" | "video",
  "startedAt": "<ISO>",
  "expiresAt": "<ISO>"
}
```
**No `caller.name` / `caller.photoUrl`.** Flutter looks them up from the chat (we already have `chat.otherUser.name/photoUrl`) for in-app rings. The FCM payload (§5) carries name/photo for cold-start cases.

Recipients: callee only.

### `call.accepted`
```json
{ "callId": "<uuid>", "answeredAt": "<ISO>" }
```
Recipients: caller + callee (both, so callee's other devices dismiss).

### `call.rejected`
```json
{
  "callId": "<uuid>",
  "endedAt": "<ISO>",
  "reason": "rejected",
  "durationSeconds": 0
}
```
Recipients: caller + callee.

### `call.cancelled`
```json
{
  "callId": "<uuid>",
  "endedAt": "<ISO>",
  "reason": "cancelled",
  "durationSeconds": 0
}
```
Recipients: callee only (caller already knows — they cancelled).

### `call.ended` — **also fires for ring-timeout (missed)**
```json
{
  "callId": "<uuid>",
  "endedAt": "<ISO>",
  "durationSeconds": <int>,
  "reason": "normal" | "network" | "cellular_interrupt" | "missed"
         | "participant_disconnected" | "room_finished_inactive" | "rejected" | "cancelled"
}
```
Recipients: caller + callee.

**Important**: there is NO separate `call.missed` event. Ring-timeout transitions the call to status `missed` and fires `call.ended` with `reason: 'missed'`. Flutter treats this branch as "missed call".

### Caller-side note
The caller does NOT receive a socket echo when they initiate a call. The "outgoing call" UI is driven entirely off the `POST /api/calls` 201 response. The first socket event the caller sees is `call.accepted` (peer picked up) or `call.rejected`/`call.ended` (peer declined / timed out).

---

## 5. FCM payload (data-only, high priority, TTL 60s)

```json
{
  "data": {
    "type": "call.incoming",
    "callId": "<uuid>",
    "chatId": "<uuid>",
    "callerId": "<uuid>",
    "callerName": "<string>",
    "callerPhotoUrl": "<url>" | "",
    "kind": "voice" | "video",
    "startedAt": "<ISO>",
    "expiresAtMs": "<int as string>"
  }
}
```

All values are strings (FCM `data` requirement). `callerPhotoUrl` is `""` (empty string) not `null` when caller has no photos. Flutter: treat empty string as absent.

---

## 6. System message format for call records

`messages.systemPayload` (jsonb) is set when the message represents a call event. Schema:

```json
{
  "kind": "call",
  "callId": "<uuid>",
  "callKind": "voice" | "video",
  "durationSeconds": <int> | null,
  "endReason": "normal" | "rejected" | "missed" | "cancelled" | "network"
             | "cellular_interrupt" | "participant_disconnected" | "room_finished_inactive",
  "callerId": "<uuid>",
  "calleeId": "<uuid>"
}
```

`durationSeconds` is `null` for ring-timeout/reject/cancel (no actual duration), an integer for `endActive`.

`messages.body` carries a human-readable fallback (`"📞 Voice call · 2:35"`, `"Call declined"`, `"Missed call"`) for clients that don't read `systemPayload`. New Flutter renders from `systemPayload`.

---

## 7. Misc behavior to mirror

- **Ring timeout**: 45s server-side. Caller's app should cancel its outgoing UI on `call.ended`/`reason='missed'`.
- **Connect timeout**: 20s after `accept` server-side. If callee never connects to LiveKit, server ends with `reason='network'`.
- **`durationSeconds` may be `null`** in `POST /end` response — Flutter must handle.
- **`call.cancelled` is NOT a separate UI state from `call.ended`** for the caller — they already knew they cancelled. For the callee, `call.cancelled` arrives instead of `call.ended`, and dismisses ringing.
- **No GET /chats/:chatId/calls** — for in-chat call history, Flutter renders from system messages with `systemPayload.kind === 'call'`.

---

## 8. Required env on the backend (informational)

These have to be set on the backend for the feature to function. Flutter doesn't read them but should know what's expected to work:

- `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`
- `FCM_ENABLED=true` + `FIREBASE_SERVICE_ACCOUNT_JSON` (base64)
- `REDIS_*` for BullMQ ring/connect timeouts

If `FCM_ENABLED=false` the calls feature still works for users who happen to be online (Socket.IO event delivers); cold-start ringing is simply disabled.

---

## 9. Open clarifications (won't block initial implementation, would polish later)

These are paraphrased from the audit's "Open questions for backend":
1. The wrapped Socket.IO envelope was almost certainly intentional (matches existing chat events). Treating as ground truth.
2. `GET /chats/:chatId/calls` — defer until backend ships, render from system messages in the meantime.
3. Adding `caller: { name, photoUrl }` to `call.incoming` socket payload would be nicer; for now we lookup from chat.
4. Typed error codes on accept/reject/cancel/end — using HTTP status for now.
5. Real DB migrations (A3) — backend's track, no Flutter blocker.
6. Per-route rate limit overrides — backend's track.
7. Exposing `livekitRoom` on `CallDTO` — not needed for normal flow (room name is in the initiate/accept response).
