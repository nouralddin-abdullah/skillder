# Skillder — Chat Architecture

Reference document for how chat will be implemented in the Skillder Flutter app. Aims for top-tier quality on par with Telegram, WhatsApp, and Tinder.

> **Status:** design only. No code yet. Backend endpoints listed at the bottom must exist before client work starts.
>
> **Aligned with backend** (as of 2026-05-10): single `likes` table with `kind: 'like' | 'pass'`, separate `matches` table with canonical user ordering, `chats` FK to match (`chatId ≠ matchId`), message `kind` discriminator (`text | image | system`), no edit/unsend time window, two-step image upload (`POST /chats/:id/media` then `POST /chats/:id/messages` with `mediaUrl`), `chat_reads` table for last-read pointers, ISO timestamp sync cursors, JWT in WebSocket query string.

---

## 1. Core philosophy: local-first

The single biggest difference between mobile chat and web chat:

| | Web chat (typical) | Mobile chat (production-grade) |
|---|---|---|
| Data location | Server is source of read | Local DB is source of read |
| Open page/app | Fetch from server, show spinner | Read local DB, show instantly |
| State persistence | Lost on refresh / tab close | Survives app kill, OS restart |
| Network failure | App breaks | App still works (read + queued sends) |
| Real-time | WebSocket = primary | WebSocket = nice-to-have, sync API = source of truth |

WhatsApp opens in <50 ms even on a dead connection because it never asks the server for chat history at boot — it reads the on-device SQLite. The server is treated as a **sync target**, not a database.

**Every architectural decision in this doc flows from this principle.**

---

## 2. The state machine: 6 things every message has

Every message lives in local DB with these fields (minimum):

| Field | Purpose |
|---|---|
| `id` | Server-assigned ID (UUID). Null until server confirms. |
| `clientId` | Client-generated UUID assigned at send time. Used for dedupe and to swap in the real `id` later. |
| `chatId` | Foreign key to chat |
| `senderId` | Who sent it |
| `body` | The text (or media reference) |
| `createdAt` | Server timestamp once confirmed; client timestamp until then |
| `status` | `sending` / `sent` / `delivered` / `read` / `failed` / `deleted` |
| `editedAt` | Null until edited |

`clientId` is the most important field most people forget. It lets the same message survive being sent, retried after a network drop, and confirmed by the server — without ever showing a duplicate.

---

## 3. Data flow — the four critical paths

### 3.1 App open (cold start)

```
1. Read all chats + last N messages from local DB
2. Render UI immediately — no spinner
3. In background: GET /chats/sync?since=<lastCursor>
   - Server returns events: new messages, edits, deletes, read receipts, new matches
4. Apply events to local DB in order
5. Save the new cursor
6. UI updates reactively (streams from local DB)
7. Open WebSocket for live events from this point forward
```

### 3.2 Sending a text message (the optimistic path)

```
1. User types + hits send
2. Generate clientId (UUID v4)
3. Insert into local DB:
     {clientId, chatId, kind: "text", body, status: "sending", createdAt: now()}
4. UI shows the message immediately with a clock icon
5. POST /chats/{chatId}/messages  body: {clientId, kind: "text", body, replyToId?}
6. On success:
   - Server returns {id, clientId, createdAt}
   - Update local row: status = "sent", id = serverId, createdAt = serverTime
   - UI swaps clock → single check
7. On failure (timeout, 5xx):
   - Set status = "failed"
   - UI shows red retry icon
   - User taps → re-send the same clientId
8. On 4xx (validation, blocked):
   - Mark failed permanently, no retry
```

The `clientId` makes step 7 idempotent — if the server actually received it but the response was lost, retrying with the same `clientId` returns the existing message.

### 3.2b Sending an image (two-step)

Images are uploaded **before** the message is created so the optimistic UI can show a preview immediately and retries don't re-upload.

```
1. User picks image (and optional caption)
2. Generate clientId
3. Insert into local DB:
     {clientId, chatId, kind: "image", body: caption, status: "sending",
      mediaUploadId: <local outbox id>, mediaUrl: null, createdAt: now()}
4. UI renders the local file/bytes immediately with an upload progress overlay
5. POST /chats/{chatId}/media  (multipart, photo field)
   → returns {mediaUrl}
6. Update local row: mediaUrl = <returned>, mediaUploadId = null
7. POST /chats/{chatId}/messages  body: {clientId, kind: "image", mediaUrl, body: caption, replyToId?}
8. On success: same as step 6 in 3.2 — status = "sent"
9. On retry after the message POST fails: re-call step 7 with the same clientId AND the same mediaUrl. No re-upload needed.
10. On retry after the upload fails: re-run step 5; mediaUrl gets a new value. The message hasn't been POSTed yet so there's no idempotency concern.
```

Two-step makes large uploads feel snappy (UI is responsive instantly) and keeps the system message-create call fast and cheap.

### 3.3 Receiving a message (app foregrounded)

```
1. WebSocket pushes event:
     {type: "message.created", chatId, message: {...}}
2. Insert into local DB (dedupe by id)
3. UI updates reactively (it's listening to the chat's message stream)
4. If the chat is open:
   - Send POST /chats/{id}/read
   - Update local row: status = "read"
5. If the chat is NOT open:
   - Increment unread count on chat list
```

### 3.4 Receiving a message (app closed)

```
1. Server sends FCM/APNs push notification
2. OS shows notification on lock screen
3. User taps → app opens → cold start path runs
4. Delta sync catches all missed messages
5. UI shows them
```

**You don't keep the WebSocket alive when backgrounded.** The OS will kill it (battery, doze mode, App Nap). Push notifications are how the OS lets you wake.

---

## 4. The two pipelines: WebSocket + Delta Sync

The system has **two ways** to get updates from the server. Both exist for a reason.

### 4.1 WebSocket (live, low-latency)
- Active only while app is foregrounded and connected
- Pushes individual events with sub-second latency
- Used for: typing indicators, presence, instant messages, read receipts
- Fragile: drops on network changes, tunnels, suspended tabs
- **Cannot be trusted as the only source of updates**

### 4.2 Delta sync (correct, eventually consistent)
- HTTP polling triggered by:
  - Cold start
  - WebSocket reconnect (after disconnect)
  - App resume from background
  - Push notification received (optional — let user open the app)
- Returns ALL events since `cursor`, in order
- Server response includes new cursor
- This is the **source of truth** for "what did I miss?"

### Mental model

> **WebSocket = the fast path. Delta sync = the safety net.**

If WebSocket disappears for 30 seconds and 10 messages arrive in that window, the user shouldn't notice anything when the connection comes back — delta sync replays the missed events instantly.

---

## 5. Local database schema (minimum)

Using **Drift** (formerly Moor) — type-safe SQLite for Flutter. Alternatives: Hive (NoSQL, faster writes), ObjectBox (fastest, less Flutter-native).

### Tables

```
chats
  id                  TEXT PK
  matchId             TEXT  (FK to backend's matches.id)
  otherUserId         TEXT
  otherUserName       TEXT  (denormalized, updated via events)
  otherUserPhotoUrl   TEXT  (denormalized)
  lastMessagePreview  TEXT
  lastMessageAt       INTEGER (epoch ms)
  unreadCount         INTEGER

messages
  id              TEXT PK NULL       (null until server confirms)
  clientId        TEXT UNIQUE NOT NULL
  chatId          TEXT NOT NULL      → chats.id
  senderId        TEXT NULL          (null for system messages)
  kind            TEXT NOT NULL      ('text' | 'image' | 'system')
  body            TEXT NULL          (text content, or image caption — also nullable for image-only)
  mediaUrl        TEXT NULL          (set when kind='image')
  mediaUploadId   TEXT NULL          (local-only; the outbox row id while upload is in flight)
  createdAt       INTEGER NOT NULL
  status          TEXT NOT NULL
  editedAt        INTEGER NULL
  deletedAt       INTEGER NULL
  replyToId       TEXT NULL          (for reply threads)

sync_state
  key             TEXT PK
  cursor          TEXT  (last delta sync cursor)
  lastSyncAt      INTEGER

outbox
  clientId        TEXT PK
  chatId          TEXT
  body            TEXT
  createdAt       INTEGER
  attempts        INTEGER
  nextAttemptAt   INTEGER
  lastError       TEXT
```

### Indexes
- `messages(chatId, createdAt DESC)` — for chat detail queries
- `messages(clientId)` UNIQUE — for dedupe
- `chats(lastMessageAt DESC)` — for chat list ordering

### The outbox pattern
Every send goes through the `outbox` table. A background worker drains it. If the network is down, messages stack up there and ship on reconnect. This is what makes airplane-mode-then-send-then-airplane-off "just work."

---

## 6. The reactive UI layer

The UI never calls REST or WebSocket directly. It listens to **streams from the local DB**.

```
┌────────────────────────────┐
│       ChatScreen UI        │
│   StreamBuilder<List<Msg>> │
└────────────┬───────────────┘
             │ stream
             ▼
┌────────────────────────────┐
│      ChatRepository        │
│   .messageStream(chatId)   │ ──► Drift query stream
└────────────────────────────┘
             ▲
             │ writes
             │
┌────────────────────────────┐    ┌──────────────────────────┐
│      ChatRepository        │ ◄─ │  WebSocketService        │
│   .applyEvent(event)       │    │  (parses + dispatches)   │
└────────────┬───────────────┘    └──────────────────────────┘
             │ writes                       ▲
             ▼                              │
        ┌─────────┐                ┌────────┴─────────┐
        │ Drift   │                │  REST API client │
        │ (SQLite)│ ◄─────────────►│  - POST message  │
        └─────────┘   sync/upload  │  - GET sync      │
                                   │  - GET history   │
                                   └──────────────────┘
```

UI rebuilds happen automatically when the DB changes — it doesn't matter whether the change came from a WebSocket event, a delta sync, or the user's own send. This is the beauty of local-first: one source of truth for the UI.

---

## 7. Edge cases and how we handle them

### 7.1 Message arrives twice (WebSocket replays after delta sync)
Dedupe by `id` (or `clientId` for own messages). DB unique constraint enforces.

### 7.2 User sends, server gets it, response is lost
On retry the client uses the same `clientId`. Server responds with the existing message. No duplicate.

### 7.3 Message sent → edited → deleted, all while user offline
Delta sync returns events in order. Apply them sequentially:
1. `message.created` → insert
2. `message.edited` → update body, set editedAt
3. `message.deleted` → set deletedAt, body becomes "this message was deleted"

### 7.4 User on bad network, message stuck in `sending` for 30 seconds
Show a clock for the first 5s, then "sending..." subtitle, then "tap to retry" if it fails. Outbox retries with exponential backoff (1s, 2s, 4s, 8s, 16s, 32s, max).

### 7.5 User opens chat while message is unsent
The unsent message appears in the chat (it's already in local DB). Status icon shows the state. New messages from the other user can arrive on top of it.

### 7.6 User logs out
Wipe the local DB. Don't leak chats to the next user on the same device.

### 7.7 Multi-device (same account on phone + tablet)
Each device tracks its own sync cursor. Same events get delivered to both. Read receipts fire on whichever device opens the chat first.

### 7.8 Storage limits
Cap local message count per chat (e.g., 500 most recent). When user scrolls up past that, fetch older from `GET /chats/{id}/messages?before=<msgId>`. Insert into local DB as cache. Optional: TTL eviction for very old messages.

### 7.9 Conversation deletion / unmatch
`match.removed` event arrives. Cascade delete the chat + its messages from local DB.

**Re-match policy:** allowed. If A unmatches B and they later both like each other again, a new match (and new chat) is created. The hard stop is the separate **block** action — a blocked user can never re-appear. Backend's `matches` table soft-deletes (`status = 'unmatched'`), and the next mutual like flips it back to `matched` (or creates a new row with the previous one archived — backend's call).

### 7.10 Server pushes an event for an unknown chat (race condition)
Receive `message.created` for `chatId` we don't have. Either:
- Trigger a `GET /chats/{chatId}` to hydrate
- Or include the chat object inline in the event (preferred — cheaper, no race)

---

## 8. Real-time channel — WebSocket protocol

Suggested message envelope from server to client:

```json
{
  "type": "message.created",
  "chatId": "...",
  "data": { /* full message object */ },
  "cursor": "2026-05-10T14:23:00.123Z"
}
```

Event types we'll need:
- `message.created`
- `message.edited`
- `message.deleted`
- `message.read` (read receipts)
- `chat.typing` (typing indicators — ephemeral, not persisted)
- `match.created` (new chat appears in list)
- `match.removed` (unmatch — chat disappears)
- `presence.updated` (online/last-seen — optional)

Client → server messages (rare — most actions go through REST):
- `ping` / `pong` for keepalive (or rely on protocol-level)
- `chat.typing.start` / `chat.typing.stop`

### Connection management
- Connect on app foreground
- Disconnect on app background after 30s grace period
- Reconnect with exponential backoff on drop
- After every reconnect: trigger a delta sync immediately

---

## 9. Push notifications

**FCM (Firebase Cloud Messaging)** for both Android and iOS. Native APNs is fine but FCM unifies the codebase.

### Flow
1. Client gets FCM token on app start (or on login)
2. Client uploads token: `POST /devices/fcm` with `{ token, platform }`
3. Server stores token per user (one user can have many devices)
4. When user A sends to user B and B is offline → server pushes to all of B's tokens
5. B's phone shows notification
6. B taps → app cold-starts → delta sync catches up

### Notification payload
Keep it minimal — just enough to render the OS notification. Don't put the full message body if it's sensitive (lock-screen visibility). Best to send:

```json
{
  "notification": {
    "title": "Sarah",
    "body": "New message"
  },
  "data": {
    "chatId": "...",
    "type": "message"
  }
}
```

The actual message comes from delta sync when the app opens. This avoids push payload size limits and keeps content out of OS logs.

---

## 10. Performance targets

For top-tier feel, aim for:

| Metric | Target |
|---|---|
| Cold start to chat list visible | < 200 ms |
| Tap chat → messages visible | < 50 ms (already in DB) |
| Send tap → message appears in UI | < 16 ms (one frame) |
| Send → server confirm | < 500 ms on good network |
| WebSocket message → UI update | < 100 ms |
| Delta sync after reconnect | < 1 s for typical day's events |

Hit these and the app feels native. Miss them and it feels like a wrapper around a website.

---

## 11. Implementation order (recommended)

Build in slices, each one shippable:

### Phase 1 — local mock (no backend needed)
1. Set up Drift + schema
2. ChatRepository with stream-based queries
3. UI: chat list + chat detail, reading from streams
4. Seed local DB with fake data
5. Implement send → write to local DB only (status stays `sending` forever)

You now have a working chat UI that runs offline. **Ship-able as a demo.**

### Phase 2 — REST integration
6. Implement send → outbox → POST → confirm
7. Implement `GET /chats` to hydrate initial chat list
8. Implement `GET /chats/{id}/messages` for paginated history
9. Pull-to-refresh on chat list

Now messages actually go to the server. **No real-time yet — feels like SMS.**

### Phase 3 — delta sync
10. Implement `GET /chats/sync?since=...`
11. Sync on app foreground, after every send confirmation
12. Background sync every 30s while app is open

Now messages from others appear within 30s. **Feels like email.**

### Phase 4 — WebSocket
13. Add WebSocketService
14. Connect on foreground, disconnect on background
15. Apply incoming events to local DB
16. Trigger delta sync on every reconnect

Now messages appear instantly. **Feels like WhatsApp.**

### Phase 5 — push notifications
17. FCM setup + token upload
18. Server-side push triggers on offline recipients
19. Tap notification → deep-link to chat

Now you don't need the app open to know about messages. **Production-grade.**

### Phase 6 — polish
- Typing indicators
- Read receipts (UI for the existing data)
- Reply / quote
- Image / file sharing
- Voice messages
- Reactions

---

## 12. Backend endpoints required

Minimum viable:

```
POST   /chats/{chatId}/messages
       body (text):  {clientId, kind: "text", body, replyToId?}
       body (image): {clientId, kind: "image", mediaUrl, body?, replyToId?}
       returns: full message object

POST   /chats/{chatId}/media     (multipart, field name "photo")
       returns: {mediaUrl}

GET    /chats
       returns: list of chats (with last message preview)

GET    /chats/{chatId}/messages?before=<msgId>&limit=50
       returns: paginated history (descending by createdAt)

GET    /chats/sync?since=<cursor>
       returns: {events: [...], newCursor: "..."}

POST   /chats/{chatId}/read
       body: {upToMessageId}
       returns: ok

DELETE /chats/{chatId}/messages/{messageId}
       returns: ok

PATCH  /chats/{chatId}/messages/{messageId}
       body: {body}
       returns: updated message
```

### Match-related endpoints (handled by backend's matching subsystem)

```
POST   /likes
       body: {targetUserId, kind: "like" | "pass"}
       returns: {kind: "pending" | "matched", matchId?, chatId?}

GET    /matches
       returns: current user's active matches

DELETE /matches/{matchId}
       body: {reason?: "unmatch" | "block"}
       returns: ok
       (block also adds to a separate /blocks list and prevents future re-matching)
```

The chat list (`GET /chats`) is the user-facing view of matches that have an open conversation.

WebSocket:
```
wss://api.skillder.com/realtime?token=<jwt>
```

Push notifications:
```
POST /devices/fcm
     body: {token, platform: "android"|"ios"}
DELETE /devices/fcm/{token}
```

---

## 13. Flutter package picks

| Concern | Package | Why |
|---|---|---|
| Local DB | `drift` | Type-safe SQLite, generates code, has stream queries built-in. Best in class. |
| WebSocket | `web_socket_channel` | Official, minimal, works on web + mobile + desktop |
| HTTP | `http` (already used) | Keep consistent with existing services |
| Push notifications | `firebase_messaging` | Standard, works on Android + iOS |
| State management | streams from Drift directly | Don't add Riverpod/Bloc just for chat — Drift's reactive queries are enough |
| Background work | `workmanager` (Android) / `BGTaskScheduler` (iOS) | Periodic sync — only needed if we want delta sync without push |
| UUIDs | `uuid` | Generate `clientId`s |

Avoid:
- Hive — fast but loose typing, hard to migrate schemas
- Floor — slower than Drift, less active
- A "chat library" like Stream Chat or Sendbird — only if you want a hosted backend, otherwise overkill

---

## 14. Things deliberately deferred (until later)

- **End-to-end encryption.** WhatsApp does it. Tinder doesn't. Skip for v1.
- **Voice/video calls.** Use a service like Twilio when needed.
- **Group chats.** Same architecture, just `chat.participants` is a set.
- **Message search.** Full-text search on local DB via SQLite FTS5 — easy to add later.
- **Sticker / GIF picker.** UI only, no architectural change.
- **Translation.** Just a UI overlay on `message.body`.
- **Disappearing messages.** Add a `expiresAt` column.

---

## TL;DR

> **Treat the local SQLite DB as the source of truth. The server is just a sync target. WebSocket is a nice-to-have for low-latency live updates. Delta sync is the safety net that makes correctness guaranteed. Push notifications wake the app when it's closed. The outbox pattern makes sends survive network drops. UI listens to the local DB via streams and rebuilds reactively. Every message has a `clientId` for idempotent retries.**

This is the same architecture WhatsApp, Telegram, and Tinder use. Built right, the app feels instant on every interaction — even on bad networks, even after going through a tunnel, even if the user hasn't opened the app in a week.
