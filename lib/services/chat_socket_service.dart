import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../features/calls/models/call_session.dart';
import 'api_config.dart';
import 'auth_storage.dart';
import 'chat_sync_service.dart';

/// Live updates over Socket.IO.
///
/// Connects to the backend's `/realtime` namespace and routes incoming
/// chat events into [ChatSyncService.applyRealtimeEvent] so the local DB
/// (and therefore every UI stream) updates the moment something happens
/// on the server — no need to wait for the next sync.
///
/// On every (re)connect we trigger a sync delta so any events that were
/// missed during the disconnect window are caught up.
class ChatSocketService {
  final ChatSyncService syncService;

  io.Socket? _socket;
  bool _intentionallyDisconnected = false;

  /// Broadcast stream of typing notifications. The chat detail screen
  /// subscribes to this and filters by chatId.
  final StreamController<TypingNotification> _typingCtl =
      StreamController<TypingNotification>.broadcast();

  Stream<TypingNotification> get typingStream => _typingCtl.stream;

  /// Broadcast stream of call lifecycle events. The active-call controller
  /// subscribes to this for incoming calls + state transitions on calls
  /// we're already in. Events are typed (see [CallEvent] subtypes) and
  /// already unwrap the `{type, seq, chatId, data, createdAt}` envelope
  /// per CALLS_CONTRACT_ACTUAL.md §2.
  final StreamController<CallEvent> _callCtl =
      StreamController<CallEvent>.broadcast();

  Stream<CallEvent> get callEventStream => _callCtl.stream;

  /// Broadcast stream of `call.snapshot` events. Fires once per WS connect —
  /// the server's authoritative view of the user's currently-ringing /
  /// currently-active calls. The active-call controller subscribes so it
  /// can rebuild local state after a cold boot or force-kill (the case
  /// where the controller's in-memory `_session` was lost but the server
  /// still has the call alive). See CALLS_FRONTEND_CONTRACT.md §2.
  ///
  /// Kept on its own stream rather than folded into `callEventStream`
  /// because the snapshot envelope is `{type, calls[]}` — a different
  /// shape from the per-call `{type, seq, chatId, data}` envelope — and
  /// because the controller treats the snapshot as a *state reconcile*
  /// rather than an event to process.
  final StreamController<CallSnapshotEvent> _callSnapshotCtl =
      StreamController<CallSnapshotEvent>.broadcast();

  Stream<CallSnapshotEvent> get callSnapshotStream => _callSnapshotCtl.stream;

  ChatSocketService(this.syncService);

  bool get isConnected => _socket?.connected ?? false;

  /// Idempotent — safe to call multiple times. Establishes the connection
  /// if one isn't already in flight.
  Future<void> connect() async {
    _intentionallyDisconnected = false;
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) return;

    final socket = io.io(
      '${ApiConfig.socketUrl}/realtime',
      io.OptionBuilder()
          .setTransports(const ['websocket'])
          // Auth-via-query — matches the backend gateway's `?token=` reader.
          // We also send it via auth so behind any future proxy that strips
          // query strings the handshake still works.
          .setQuery({'token': token})
          .setAuth({'token': token})
          // Native socket.io reconnection — the app stays online through
          // network blips without our intervention.
          .enableReconnection()
          .setReconnectionAttempts(double.maxFinite.toInt())
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(15000)
          .build(),
    );

    socket
      ..onConnect(_onConnect)
      ..onDisconnect(_onDisconnect)
      ..onConnectError(_onError)
      ..onError(_onError)
      ..on('message.created', _routeChatEvent)
      ..on('message.edited', _routeChatEvent)
      ..on('message.deleted', _routeChatEvent)
      ..on('message.read', _routeChatEvent)
      ..on('match.created', _routeChatEvent)
      ..on('match.removed', _routeChatEvent)
      ..on('chat.typing', _routeTyping)
      ..on('call.incoming', _routeCallEvent)
      ..on('call.accepted', _routeCallEvent)
      ..on('call.rejected', _routeCallEvent)
      ..on('call.cancelled', _routeCallEvent)
      ..on('call.ended', _routeCallEvent)
      ..on('call.snapshot', _routeCallSnapshot);

    _socket = socket;
    socket.connect();
  }

  Future<void> disconnect() async {
    _intentionallyDisconnected = true;
    final socket = _socket;
    if (socket == null) return;
    if (socket.connected) socket.disconnect();
  }

  Future<void> dispose() async {
    await disconnect();
    _socket?.dispose();
    _socket = null;
    await _typingCtl.close();
    await _callCtl.close();
    await _callSnapshotCtl.close();
  }

  /// Send a typing.start / typing.stop notification to the other party.
  /// Caller is responsible for debouncing — server gateway just forwards
  /// whatever it receives.
  void emitTyping({required String chatId, required bool isTyping}) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit(
      isTyping ? 'chat.typing.start' : 'chat.typing.stop',
      {'chatId': chatId},
    );
  }

  // ─────────────────────────── Routing ─────────────────────────────────

  void _routeChatEvent(dynamic raw) {
    if (raw is! Map) return;
    final map = Map<String, dynamic>.from(raw);
    // Fire-and-forget — the apply function handles its own errors.
    unawaited(syncService.applyRealtimeEvent(map));
  }

  void _routeCallEvent(dynamic raw) {
    if (raw is! Map) return;
    final envelope = Map<String, dynamic>.from(raw);
    final event = parseCallEvent(envelope);
    if (event != null) _callCtl.add(event);
  }

  void _routeCallSnapshot(dynamic raw) {
    if (raw is! Map) return;
    final event = CallSnapshotEvent.fromJson(Map<String, dynamic>.from(raw));
    _callSnapshotCtl.add(event);
  }

  void _routeTyping(dynamic raw) {
    if (raw is! Map) return;
    final chatId = raw['chatId']?.toString();
    final userId = raw['userId']?.toString();
    final isTyping = raw['isTyping'] == true;
    if (chatId == null || userId == null) return;
    _typingCtl.add(TypingNotification(
      chatId: chatId,
      userId: userId,
      isTyping: isTyping,
    ));
  }

  // ─────────────────────────── Lifecycle ───────────────────────────────

  void _onConnect(_) {
    // Catch up on any events we missed while offline.
    unawaited(syncService.syncDelta());
  }

  void _onDisconnect(_) {
    // Socket.io's reconnection logic kicks in unless we asked for this.
    if (_intentionallyDisconnected) return;
  }

  void _onError(_) {
    // Errors are non-fatal here — socket.io will retry. We rely on the
    // periodic sync delta as the safety net.
  }
}

/// One typing notification from the server. ChatDetailScreen filters by
/// [chatId] and shows/hides the indicator accordingly.
class TypingNotification {
  final String chatId;
  final String userId;
  final bool isTyping;
  const TypingNotification({
    required this.chatId,
    required this.userId,
    required this.isTyping,
  });
}

class ChatSocketServiceHolder {
  static ChatSocketService? _instance;

  static Future<ChatSocketService> instance() async {
    final existing = _instance;
    if (existing != null) return existing;
    final sync = await ChatSyncServiceHolder.instance();
    final created = ChatSocketService(sync);
    _instance = created;
    return created;
  }

  static Future<void> reset() async {
    final existing = _instance;
    if (existing != null) {
      await existing.dispose();
    }
    _instance = null;
  }
}
