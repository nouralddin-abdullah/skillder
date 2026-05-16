# Skillder Voice & Video Calls — Implementation Plan (Android, MVP)

**Status:** Draft **v2** — incorporates backend review of v1.
Three-way sign-off required before implementation begins.

---

## Changelog: v1 → v2

All changes from backend's review (C1–C5, I1–I5, N2, A1–A5, answers to open questions). Each is annotated **[v2]** in the body so it's easy to find on re-review.

| ID | Change | Source |
|---|---|---|
| **C1** | Busy-check via Postgres `UNIQUE` partial indexes (race-free), service catches `23505` → 409 | Backend |
| **C2** | Ring-timeout + connect-timeout via BullMQ delayed jobs (survives process restarts) | Backend |
| **C3** | `call.accepted` and `call.rejected` now go to **both** parties so callee's other devices dismiss the ringing UI | Backend |
| **C4** | Explicit `forUserIds[]` per event type, persisted to `chat_events` (table added) | Backend |
| **C5** | LiveKit webhooks (`participant_disconnected`, `room_finished`) promoted to V1 — defends the new unique index from "both clients die mid-call" | Backend |
| **I1** | System call records use a structured `system_payload jsonb` column on `messages`, with `body` kept as human-readable fallback | Backend |
| **I2** | Token TTL = `MAX_CALL_DURATION_S` (single constant, both move together) | Backend |
| **I3** | `device_tokens` table schema finalized (with `last_seen_at` + indexes); endpoints `POST /devices`, `DELETE /devices/:token` | Backend |
| **I4** | LiveKit room name simplified to `call-{callId}` (drop redundant `chatId`) | Backend |
| **I5** | `POST /calls` response drops `calleeId` (Flutter has it via the chat object) | Backend |
| **N2** | `end_reason` enum extended with `participant_disconnected`, `room_finished_inactive` | Backend |
| **A3** | Real migration file required for prod (synchronize:true is dev-only) | Backend |
| **A4** | Structured pino audit log on every call state transition (no new table) | Backend |
| **A5** | `FCM_ENABLED` env flag for dev-without-Firebase | Backend |
| **F1** | Flutter handles multi-device dismissal: when our own user accepts/rejects on another device, dismiss the local ringing UI | Frontend follow-on to C3 |
| **F2** | Flutter renders system call messages from `systemPayload` (with localization), falls back to `body` for old clients | Frontend follow-on to I1 |

---

## 1. Goals & Scope

### In scope (V1)

- 1:1 **voice** calls
- 1:1 **video** calls (with front/back camera flip)
- **Screen sharing** (replaces or augments outgoing video)
- **WhatsApp-parity UI**:
  - Full-screen ringing screen on lock screen for incoming calls
  - In-call screen with the 2×3 control grid (Speaker / Video / Mute / More / Share / End)
  - Persistent minimized "ongoing call" bar at top when navigating other screens
- Native call lifecycle on Android: ringing on locked phone, accept/reject from lock screen, audio survives screen lock and screen-off
- Call history rendered as system messages in chat: `📞 Voice call · 2:35` / `🎥 Video call · 2:35` / `Missed call` (rendered from structured payload, see [I1])
- End-to-end encryption (built-in via LiveKit's E2EE)
- **[v2-C5]** LiveKit webhooks for `participant_disconnected` + `room_finished` so dead calls clean themselves up
- **[v2-A4]** Structured pino audit logs on every call state transition

### Explicitly OUT of scope (V1)

- **iOS** — separate effort, requires paid Apple Developer Program ($99/yr) for VoIP push + CallKit. Architecture is shared; iOS-specific glue deferred.
- **Group calls** (3+ participants in one room)
- **ConnectionService integration** — using custom Activity approach instead, matches WhatsApp/Telegram/Signal. Decision rationale: OEM fragmentation, no system Phone Recents pollution, full UI control.
- **Call recording** (separate LiveKit Egress workflow, easy to add later)
- **Krisp noise suppression** (paid LiveKit add-on, optional later)
- **Background blur** for video
- **Android PiP (Picture-in-Picture mode)** — minibar covers our use case
- **SIP / phone number bridging**
- **AI transcription**

---

## 2. Architecture Overview

Two cleanly-separated layers:

```
┌────────────────────┐                          ┌────────────────────┐
│  Caller (Flutter)  │                          │  Callee (Flutter)  │
└──────────┬─────────┘                          └─────────▲──────────┘
           │ POST /calls                                  │
           │ ─────────────────────►                       │
           │                       ┌────────────────┐    │
           │                       │ Skillder       │    │ Socket.IO event
           │                       │ Backend        │ ───┘ + FCM data push
           │                       │ (NestJS)       │
           │                       │ - signaling    │ ◄─── webhooks ───┐
           │                       │ - LiveKit      │                  │
           │                       │   token mint   │                  │
           │                       │ - BullMQ jobs  │                  │
           │                       └────────┬───────┘                  │
           │                                │ admin REST               │
           │                                ▼                          │
           │                       ┌────────────────┐                  │
           └───────── WebRTC ──────► LiveKit Cloud ◄────── WebRTC ─────┘
                                   └────────────────┘
                                   (media never touches our backend)
```

### Media layer — LiveKit Cloud
- All audio/video bytes flow through LiveKit
- Backend mints access tokens with `livekit-server-sdk`; never sees media
- Each call = its own LiveKit room (**[v2-I4]** `call-{callId}`)
- LiveKit Cloud handles TURN, edge servers, encryption — no infra to operate
- **[v2-C5]** LiveKit Cloud webhooks back to our backend for room/participant lifecycle events

### Signaling layer — Skillder backend
- "Who calls who, was it accepted, when did it end"
- Slots into existing `RealtimeGateway` (Socket.IO) and `chat_events` table
- New REST endpoints + new event types — no architectural rewrite
- **[v2-C2]** BullMQ for ring-timeout / connect-timeout watchdogs (survives restarts)

---

## 3. Backend Contract

> **The most important section for backend review.** v2 changes inline.

### 3.1 New entity: `calls`

```sql
CREATE TABLE calls (
  id                uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id           uuid NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  caller_id         uuid NOT NULL REFERENCES users(id),
  callee_id         uuid NOT NULL REFERENCES users(id),
  kind              varchar(8) NOT NULL CHECK (kind IN ('voice', 'video')),
  status            varchar(16) NOT NULL CHECK (status IN
                      ('ringing', 'active', 'ended', 'missed', 'rejected', 'cancelled')),
  -- [v2-N1] denormalized for admin queries; derivable from id
  livekit_room      text NOT NULL,
  started_at        timestamptz NOT NULL DEFAULT now(),
  answered_at       timestamptz,
  ended_at          timestamptz,
  duration_seconds  integer,
  -- [v2-N2] enum extended for LiveKit-detected disconnects
  end_reason        varchar(32) CHECK (end_reason IN
                      ('normal', 'rejected', 'missed', 'cancelled',
                       'network', 'cellular_interrupt', 'busy',
                       'participant_disconnected', 'room_finished_inactive')),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_calls_chat_started ON calls(chat_id, started_at DESC);

-- [v2-C1] Race-free busy enforcement at DB level. Two simultaneous POST /calls
-- to the same callee both pass app-level prechecks; only one passes this index.
-- Service code catches Postgres unique_violation (23505) → returns 409.
CREATE UNIQUE INDEX idx_calls_one_per_callee_active ON calls(callee_id)
  WHERE status IN ('ringing', 'active');

CREATE UNIQUE INDEX idx_calls_one_per_caller_active ON calls(caller_id)
  WHERE status IN ('ringing', 'active');
```

### 3.1a New entity: `device_tokens` **[v2-I3]**

```sql
CREATE TABLE device_tokens (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token         text NOT NULL UNIQUE,
  platform      varchar(16) NOT NULL CHECK (platform IN ('android', 'ios')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  last_seen_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_last_seen ON device_tokens(last_seen_at);
```

`UNIQUE` on `token` handles the "user logs into a phone that previously belonged to someone else" case — re-binds correctly.

### 3.1b Touch on `messages` table **[v2-I1]**

```sql
ALTER TABLE messages ADD COLUMN system_payload jsonb;
```

Used only for `kind='system'` rows. Schema for call records:

```json
{
  "kind": "call",
  "callId": "uuid",
  "callKind": "voice",
  "durationSeconds": 155,
  "endReason": "normal",
  "callerId": "uuid",
  "calleeId": "uuid"
}
```

`body` stays a human-readable fallback (`"📞 Voice call · 2:35"`) for clients that don't yet read `system_payload`. New clients render from the structured payload (localizable, can attach a "call back" tap target, filterable). Additive change, no breaking wire change.

### 3.2 REST endpoints (under `/api/calls`)

#### `POST /calls` — Initiate

**Request**
```json
{ "chatId": "uuid", "kind": "voice" | "video" }
```

**Response 201**
```json
{
  "callId": "uuid",
  "roomName": "call-{callId}",
  "livekitUrl": "wss://...",
  "callerToken": "jwt..."
}
```
**[v2-I5]** `calleeId` removed from response — Flutter already has it via the chat object.

**Server logic**
1. Authorize: caller is in `chat`, neither user has removed it.
2. **[v2-C1]** No app-level busy precheck — rely on the unique partial indexes. INSERT first; on `unique_violation (23505)`, inspect which index conflicted (`idx_calls_one_per_callee_active` → 409 `callee_busy`; `idx_calls_one_per_caller_active` → 409 `caller_busy`).
3. Mint LiveKit token for caller (perms: `roomJoin`, `canPublish`, `canSubscribe`, `canPublishData`).
4. Persist to `chat_events` with `forUserIds=[calleeId]` **[v2-C4]**.
5. Emit `call.incoming` Socket.IO event to `user:{calleeId}` room.
6. Send FCM **data-only, high-priority** push to all of callee's registered device tokens.
7. **[v2-C2]** Schedule BullMQ delayed job `ring-timeout-{callId}` with delay = `RING_TIMEOUT_S * 1000`, jobId = `ring-${callId}`. Processor checks status; if still `ringing`, transitions to `missed`, inserts system message, emits `call.ended`.
8. **[v2-A4]** Pino: `info({event: 'call.initiated', callId, callerId, calleeId, kind})`.
9. Return caller's token + connection info.

**Errors**
| Status | code | Meaning |
|---|---|---|
| 403 | `chat_removed` | Either party has removed the chat |
| 403 | `not_participant` | Caller isn't a member of this chat |
| 409 | `callee_busy` | Callee is already in / receiving a call (caught from unique index) |
| 409 | `caller_busy` | Caller is already in / receiving a call (caught from unique index) |
| 503 | `livekit_unavailable` | LiveKit token mint failed; service rolls back insert |

#### `POST /calls/:id/accept` — Callee accepts

**Response 200**
```json
{
  "callId": "uuid",
  "roomName": "call-{callId}",
  "livekitUrl": "wss://...",
  "calleeToken": "jwt..."
}
```

**Server logic**
1. Authorize: `userId === call.calleeId`, `call.status === 'ringing'`.
2. Update `status='active'`, `answered_at=now()`. **Idempotent** if already `active` from this user — return 200 with current values.
3. Mint LiveKit token for callee.
4. Cancel the BullMQ ring-timeout job (`removeJob('ring-${callId}')`).
5. **[v2-C2]** Schedule new BullMQ delayed job `connect-timeout-${callId}` with delay = `CONNECT_TIMEOUT_S * 1000`. Processor queries LiveKit room participants via admin SDK; if callee absent, ends call with `reason='network'`.
6. Persist to `chat_events` with `forUserIds=[callerId, calleeId]` **[v2-C4]**.
7. **[v2-C3]** Emit `call.accepted` to **both** `user:{callerId}` and `user:{calleeId}` rooms — caller transitions to active call screen, callee's *other* devices dismiss their local ringing UI.
8. **[v2-A4]** Pino: `info({event: 'call.accepted', callId, calleeId})`.

#### `POST /calls/:id/reject` — Callee declines

**Response 200** `{ "ok": true }`

**Server logic**
1. Authorize: `userId === call.calleeId`, `call.status === 'ringing'`.
2. Update `status='rejected'`, `ended_at=now()`, `end_reason='rejected'`.
3. Cancel ring-timeout job.
4. Insert system message on chat with **[v2-I1]** structured payload `{kind:'call', callKind, endReason:'rejected', ...}`, body `"Call declined"`.
5. Persist `chat_events` with `forUserIds=[callerId, calleeId]` **[v2-C4]**.
6. **[v2-C3]** Emit `call.rejected` to **both** rooms — caller sees declined state, callee's other devices dismiss ringing.
7. **[v2-A4]** Pino: `info({event: 'call.rejected', callId, calleeId})`.

#### `POST /calls/:id/cancel` — Caller hangs up before answer

**Response 200** `{ "ok": true }`

**Server logic**
1. Authorize: `userId === call.callerId`, `call.status === 'ringing'`.
2. Update `status='cancelled'`, `ended_at=now()`, `end_reason='cancelled'`.
3. Cancel ring-timeout job.
4. Insert system message: payload `{kind:'call', callKind, endReason:'cancelled', ...}`, body `"Missed call"`.
5. Persist `chat_events` with `forUserIds=[calleeId]` **[v2-C4]** (caller already knows — they cancelled).
6. Emit `call.cancelled` to `user:{calleeId}` only — dismisses ringing UI on all callee devices.
7. **[v2-A4]** Pino: `info({event: 'call.cancelled', callId, callerId})`.

#### `POST /calls/:id/end` — Either party hangs up an active call

**Request**
```json
{ "reason": "normal" | "network" | "cellular_interrupt" }
```

**Response 200** `{ "ok": true, "durationSeconds": 155 }`

**Server logic**
1. Authorize: `userId in (callerId, calleeId)`, `call.status === 'active'`.
2. **Idempotent**: if already `ended`, return 200 with current values.
3. Compute `duration_seconds = ended_at - answered_at`.
4. Update `status='ended'`, `ended_at=now()`, `end_reason=reason`.
5. Cancel any pending connect-timeout job.
6. Insert system message: payload `{kind:'call', callKind, durationSeconds, endReason, ...}`, body `"📞 Voice call · 2:35"` or `"🎥 Video call · 2:35"`.
7. Persist `chat_events` with `forUserIds=[callerId, calleeId]` **[v2-C4]**.
8. Emit `call.ended` to both rooms.
9. **[v2-A4]** Pino: `info({event: 'call.ended', callId, by: userId, reason, durationSeconds})`.

#### `GET /calls/:id` — Recovery / reconciliation

Returns full call row. Used by Flutter when reconnecting after a missed Socket.IO event.

#### `GET /chats/:chatId/calls?limit=50&before=cursor` — History

Paginated call list for a chat.

#### **[v2-I3]** `POST /devices` — Register / refresh device token

**Request** `{ "token": "<fcm_token>", "platform": "android" | "ios" }`

**Response 200** `{ "ok": true }`

Upserts on `token` (unique). On conflict, updates `user_id` (handles re-binding when a token is now owned by a different user) and `last_seen_at`.

#### **[v2-I3]** `DELETE /devices/:token` — Unregister (logout cleanup)

#### **[v2-C5]** `POST /webhooks/livekit` — LiveKit lifecycle webhooks

Public route (LiveKit signs the body with the API secret instead of using JWT auth).

**Request body** (LiveKit-defined):
```json
{
  "event": "participant_disconnected" | "room_finished" | "...",
  "room": { "name": "call-{callId}", ... },
  "participant": { "identity": "<userId>", ... },
  "createdAt": ...
}
```

**Server logic**
1. Verify HMAC signature from `Authorization: <signed_jwt>` header (`livekit-server-sdk` exposes `WebhookReceiver`).
2. Parse `room.name` → extract `callId`.
3. Branch on event type:
   - `participant_disconnected` → if call is still `active` and the *other* participant is also gone (query LiveKit room state), end call with `reason='participant_disconnected'`.
   - `room_finished` → if call is still `active`, end call with `reason='room_finished_inactive'`.
4. **[v2-A4]** Pino: `info({event: 'livekit.webhook', type, callId})`.

This is what makes the unique busy-check from C1 safe — without it, both-clients-die scenarios leave `active` rows that block both users from making any future call until the cron sweeps (up to `MAX_CALL_DURATION_S=4h` later).

### 3.3 Socket.IO events  —  **[v2-C3 + C4 changes inline]**

```ts
type CallIncomingEvent = {
  type: 'call.incoming';
  callId: string;
  chatId: string;
  caller: { id: string; name: string; photoUrl: string | null };  // [A2] photoUrl null if caller has no photos
  kind: 'voice' | 'video';
  startedAt: string;     // ISO
  expiresAt: string;     // ISO, when ringing auto-cancels (startedAt + RING_TIMEOUT_S)
};

type CallAcceptedEvent = {
  type: 'call.accepted';
  callId: string;
  answeredAt: string;
};

type CallRejectedEvent = {
  type: 'call.rejected';
  callId: string;
};

type CallCancelledEvent = {
  type: 'call.cancelled';
  callId: string;
};

type CallEndedEvent = {
  type: 'call.ended';
  callId: string;
  endedAt: string;
  durationSeconds: number;
  reason: 'normal' | 'rejected' | 'missed' | 'cancelled' | 'network'
        | 'cellular_interrupt' | 'participant_disconnected'
        | 'room_finished_inactive';   // [v2-N2] expanded
};
```

**Recipients per event** **[v2-C3]**:

| Event | Recipients | `chat_events.forUserIds` **[v2-C4]** |
|---|---|---|
| `call.incoming` | callee only (all callee devices) | `[calleeId]` |
| `call.accepted` | **both** (caller transitions; callee's other devices dismiss) | `[callerId, calleeId]` |
| `call.rejected` | **both** (caller sees declined; callee's other devices dismiss) | `[callerId, calleeId]` |
| `call.cancelled` | callee only (caller already knows — they cancelled) | `[calleeId]` |
| `call.ended` | both | `[callerId, calleeId]` |

`chatId` is set on every event; existing sync-delta filter works unchanged.

### 3.4 FCM payload (Android wake-from-killed)

Critical — only path to wake a callee whose app is killed. Sent **in addition to** Socket.IO (Socket.IO catches users who happen to be online; FCM catches everyone else).

Must be **data-only** (not `notification`) and **high priority**.

```json
{
  "token": "<callee FCM device token>",
  "android": { "priority": "high", "ttl": "60s" },
  "data": {
    "type": "call.incoming",
    "callId": "<uuid>",
    "chatId": "<uuid>",
    "callerId": "<uuid>",
    "callerName": "Mohammed Ghassan",
    "callerPhotoUrl": "https://...",
    "kind": "voice",
    "startedAt": "2026-05-12T13:30:00Z",
    "expiresAtMs": "1715520600000"
  }
}
```

Flutter has a top-level `@pragma('vm:entry-point')` background handler that fires on receipt → starts the foreground service + posts the full-screen-intent notification within ~2 seconds.

### 3.5 LiveKit token claims **[v2-I2]**

```ts
const MAX_CALL_DURATION_S = 4 * 3600;   // single constant for token TTL + cleanup cron

{
  iss: process.env.LIVEKIT_API_KEY,
  sub: userId,
  name: userDisplayName,
  video: {
    room: `call-${callId}`,             // [v2-I4]
    roomJoin: true,
    canPublish: true,
    canSubscribe: true,
    canPublishData: true,
  },
  iat: nowSec,
  exp: nowSec + MAX_CALL_DURATION_S,    // [v2-I2]
}
```

### 3.6 Backend modules to add / touch

**New**
- `src/features/calls/`
  - `entities/call.entity.ts`
  - `dto/initiate-call.dto.ts`, `end-call.dto.ts`
  - `services/calls.service.ts`
  - `controllers/calls.controller.ts`
  - **[v2-C2]** `tasks/ring-timeout.processor.ts` (BullMQ Worker)
  - **[v2-C2]** `tasks/connect-timeout.processor.ts` (BullMQ Worker)
  - **[v2-C5]** `controllers/livekit-webhook.controller.ts`
- `src/features/devices/` **[v2-I3]**
  - `entities/device-token.entity.ts`
  - `controllers/devices.controller.ts`
- `src/core/livekit/livekit.service.ts` — token mint + webhook verification
- `src/core/notifications/fcm.service.ts` — wraps `firebase-admin` Messaging; **[v2-A5]** respects `FCM_ENABLED` flag
- **[v2-A3]** Migrations: `AddCallsTable...ts`, `AddDeviceTokensTable...ts`, `AddSystemPayloadToMessages...ts` (one PR or three small ones, backend's call)

**Touch**
- `src/features/chat/services/messages.service.ts` — `insertCallSystemMessage(chatId, payload, body)` helper writes both `system_payload` and `body`
- `src/features/chat/gateways/realtime.gateway.ts` — extend `RealtimeEvent` union with the call events; existing `dispatch()` works unchanged
- `src/features/chat/services/chat-events.service.ts` — append-only persistence with explicit `forUserIds` per the table in §3.3

### 3.7 Rate limiting

| Endpoint | Limit |
|---|---|
| `POST /calls` | 5 per minute per user (revisit per-pair limit when block feature lands — backend's note on N3) |
| `POST /calls/:id/accept` | unlimited (idempotent) |
| `POST /calls/:id/reject` | unlimited |
| `POST /calls/:id/cancel` | unlimited |
| `POST /calls/:id/end` | unlimited (idempotent) |
| `POST /devices` | 10 per minute per user |
| `POST /webhooks/livekit` | not user-rated; signature verification gates it |

### 3.8 Edge cases — backend behavior

| Scenario | Handling |
|---|---|
| Two simultaneous `POST /calls` to same callee | Postgres unique index rejects second; service catches `23505` → 409 `callee_busy` **[v2-C1]** |
| Callee already in a call | Same — rejected by unique index → 409 `callee_busy` |
| Callee removed the chat | `POST /calls` → 403 `chat_removed` |
| Callee offline (no socket, no FCM token) | Call still rings for `RING_TIMEOUT_S=45s`, BullMQ job auto-`missed` **[v2-C2]** |
| Process restarts during ring window | BullMQ replays delayed job from Redis on boot — call gets cleaned up **[v2-C2]** |
| Caller cancels mid-ring | `POST /cancel` → callee's `call.cancelled` event dismisses ringing UI on all devices |
| Both sides hang up simultaneously | First `POST /end` writes; second is a 200 idempotent no-op |
| LiveKit unreachable on `POST /calls` | Service rolls back the insert; returns 503 `livekit_unavailable` |
| Callee accepts but never connects to LiveKit | `connect-timeout-{callId}` BullMQ job fires after 20s, ends call with `reason='network'` **[v2-C2]** |
| Both clients die mid-call (force-stop, plane mode, OS kill) | LiveKit emits `participant_disconnected` (or `room_finished` after empty room timeout) → webhook handler ends call **[v2-C5]**. Cron-based 4-hour cleanup remains as backstop. |
| Bob has 2 phones, accepts on phone A | Phone A → `POST /accept`. Backend emits `call.accepted` to `user:{calleeId}` room — phone B receives it and dismisses its ringing UI **[v2-C3]** |

### 3.9 **[v2-A4]** Audit logging

Every state transition writes a structured pino line at `info` level:

```
{event: 'call.initiated', callId, callerId, calleeId, kind}
{event: 'call.accepted',  callId, calleeId}
{event: 'call.rejected',  callId, calleeId, reason}
{event: 'call.cancelled', callId, callerId}
{event: 'call.ended',     callId, by, reason, durationSeconds}
{event: 'call.timeout',   callId, kind: 'ring' | 'connect'}
{event: 'livekit.webhook', type, callId}
```

No new table — existing pino sink covers debugging "Bob says Alice rang him at 3am 47 times".

---

## 4. Flutter Plan

### 4.1 Packages (unchanged from v1)

| Package | Purpose |
|---|---|
| `livekit_client: ^2.x` | Core media SDK |
| `flutter_callkit_incoming: ^2.x` | Foreground service + full-screen activity (custom UI mode, NOT ConnectionService) |
| `firebase_core` + `firebase_messaging` | FCM push receipt + top-level background handler |
| `permission_handler` | Mic + camera + notification permission prompts |
| `wakelock_plus` | Keep screen awake during active call |
| `audioplayers` | Local outgoing-call ringback tone |

### 4.2 File layout (unchanged)

```
lib/
  features/
    calls/
      models/
        call_session.dart
        call_state.dart
      services/
        call_service.dart
        call_fcm_handler.dart
        ringtone_player.dart
        livekit_room_manager.dart
      controllers/
        active_call_controller.dart
      ui/
        incoming_call_screen.dart
        outgoing_call_screen.dart
        active_call_screen.dart
        active_call_minibar.dart
        call_history_message.dart
android/app/src/main/
  AndroidManifest.xml
  res/xml/notification_channels.xml
  kotlin/com/skillder/app/CallNotificationReceiver.kt
```

### 4.3 Screen flow (unchanged)

(See v1 for the full diagrams — caller, callee, mid-call.)

### 4.4 State management (unchanged)

Single `ActiveCallController` scoped at app root; survives screen navigation.

### 4.5 **[v2-F1]** Multi-device dismissal handling

Backend now broadcasts `call.accepted` and `call.rejected` to **both** parties (per [C3]). Flutter side handling:

- When `call.incoming` arrives, the local ringing UI is shown on every signed-in device.
- When `call.accepted` or `call.rejected` arrives **and we are the callee**, the local handler checks: "do I have a ringing UI for this `callId`?"
  - If yes (we're a sibling device that didn't accept): dismiss the ringing notification + foreground service immediately. No further action.
  - If yes and `callId` matches the call we just accepted/rejected: standard transition (already in flight).
- When `call.cancelled` arrives, behavior is unchanged from v1 — dismiss the ringing UI.

Hook point: `call_fcm_handler.dart` and the in-app socket listener share a `CallSessionRegistry` keyed by `callId` to track which calls have local ringing UI showing.

### 4.6 **[v2-F2]** System call message rendering

`call_history_message.dart` reads from the message's `systemPayload` field (added in [I1]):

```dart
if (message.systemPayload != null && message.systemPayload!['kind'] == 'call') {
  final p = message.systemPayload!;
  // Render a localized, tappable widget with icon + duration + (optional) "Call back" button
  return CallHistoryTile(
    callKind: p['callKind'],          // 'voice' | 'video'
    durationSeconds: p['durationSeconds'],
    endReason: p['endReason'],
    onCallBack: () => _initiateCall(chat, p['callKind']),
  );
}
// Fallback to plain body for old clients or non-call system messages
return Text(message.body);
```

This unlocks Arabic localization (the screenshots show Arabic UI), tap-to-call-back, and future call-history filtering.

### 4.7 Audio routing, manifest, channels, screenshare, edge cases

(All unchanged from v1 — see §4.5–4.9 of v1 for full detail.)

---

## 5. Test Plan (unchanged from v1)

12 manual scenarios on 2 real Android devices (one Pixel-class, one OEM-skinned). See v1 §5.

Additional v2 scenarios to add:

| # | Scenario | Pass criteria |
|---|---|---|
| 13 | **[v2-C3]** Callee has 2 devices logged in, accepts on device A | Device B's ringing UI dismisses within ~1s of accept |
| 14 | **[v2-C5]** Active call, both clients force-stopped simultaneously | Backend logs show webhook firing, both users can immediately initiate a new call (busy index released) |
| 15 | **[v2-C2]** Backend restarted during a 45s ring window | Callee's ringing UI auto-dismisses at ~T+45s; "Missed call" appears in chat |

---

## 6. Open questions — resolved in v2

All 8 open questions from v1 answered by backend. Recap:

| # | Question | Answer (incorporated into v2) |
|---|---|---|
| 1 | `device_tokens` table exists? | No, added in v2 §3.1a per [I3] |
| 2 | Existing notifications module? | No, add `src/core/notifications/fcm.service.ts` per [A5] |
| 3 | LiveKit creds | Reuse `maeen` dev creds; fresh project before public beta |
| 4 | Per-call token strategy | Confirmed: mint per request, no caching |
| 5 | Need `call.busy` socket event? | No — HTTP 409 is enough |
| 6 | LiveKit webhooks? | Yes, V1 — promoted via [C5] |
| 7 | System message format | Structured payload per [I1] |
| 8 | `chat_events` retention | Same as message events; GDPR sweep is a separate cross-cutting concern |

---

## 7. Estimated effort (v2 revision)

| Track | Effort |
|---|---|
| Backend (entity, controller, FCM module, LiveKit token + webhook handler, system message integration, BullMQ ring/connect timeouts, unique partial indexes, structured system payload, device tokens) | **2.5–3.5 days** (revised from 2–3) |
| Flutter (FCM background handler, ringing UI, active call screen, minibar, screenshare wiring, audio routing, edge cases, multi-device dismissal, structured system message rendering) | 4–6 days (unchanged) |
| Cross-team integration + manual test pass | 1 day |
| **Total wall time, parallel** | **~1–1.5 weeks** |

---

## 8. Sign-off

| Reviewer | Status | Date | Notes |
|---|---|---|---|
| Frontend (Flutter) | ✅ accepts v2 | 2026-05-12 | All v2 changes reflected in §4.5 (F1) and §4.6 (F2). Will implement against v2. |
| Backend (NestJS) | ⏳ pending v2 review | | v1 → 🟡 agree-with-changes; v2 incorporates all C1–C5, I1–I5, N2, A1–A5. Awaiting re-read. |
| Product / scope | ✅ accepts v2 | 2026-05-12 | Scope and effort match expectations. Cleared to start once backend signs off v2. |

Iterate until all three are ✅ before any code lands.
