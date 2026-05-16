import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../services/api_config.dart';
import '../../../services/api_exception.dart';
import '../../../services/auth_storage.dart';
import '../models/call_models.dart';

/// Thin REST wrapper around `/api/calls` and `/api/devices`. Returns typed
/// objects; throws [ApiException] on any non-2xx response.
///
/// Wire shape note: every backend response is wrapped
/// `{success, message, data: {...}}` — this layer unwraps `.data` so callers
/// get clean typed objects.
class CallService {
  /// `POST /api/calls` — initiate a call.
  ///
  /// [idempotencyKey] must be a UUID v4 generated once per user-initiated
  /// attempt. Internal retries inside this method reuse the same key so the
  /// backend can replay the cached response instead of creating a parallel
  /// call. The caller is responsible for regenerating the key for any
  /// fresh attempt (e.g. after a user dismisses an error and taps again).
  ///
  /// Retry policy (this method's responsibility):
  ///   - Network errors / timeouts / 5xx → exponential backoff, max 3 attempts.
  ///   - 503 `idempotent_request_pending` → wait 1s and retry with same key
  ///     (covers the two-parallel-requests case where the second waited for
  ///     the first to finish).
  ///   - 4xx (incl. 409) → no retry, propagate immediately.
  ///
  /// Throws:
  ///   - [CallBusyException] (statusCode 409) — `code` is the typed reason
  ///     and `existing` carries the conflicting call info when the server
  ///     supplied it.
  ///   - [IdempotencyPendingException] — only after we've exhausted retries
  ///     and the cache still wasn't ready. Treat as a transient failure.
  ///   - [ApiException] — other 4xx / 503 livekit_unavailable / network
  ///     exhaustion.
  static Future<CallConnection> initiate({
    required String chatId,
    required CallKind kind,
    required String idempotencyKey,
  }) async {
    const maxAttempts = 3;
    // 500ms → 2s → 5s between attempts. Total worst-case time before final
    // failure is ~7.5s plus per-attempt timeout. The server should answer
    // well under 1s now that FCM is non-blocking; the headroom is for slow
    // networks and the 503 idempotent_request_pending case where we have
    // to wait for a sibling request to complete.
    const backoff = [
      Duration(milliseconds: 500),
      Duration(seconds: 2),
      Duration(seconds: 5),
    ];

    Object? lastTransient;
    StackTrace? lastTransientStack;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final headers = await _authHeaders();
        headers['Idempotency-Key'] = idempotencyKey;

        // 20s per-attempt timeout, per contract §2.3. The server responds in
        // <1s on the happy path; this is headroom for cold starts and slow
        // networks, not for the awaiting-FCM bug class (which is gone).
        final res = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/calls'),
              headers: headers,
              body: jsonEncode({
                'chatId': chatId,
                'kind': callKindToWire(kind),
              }),
            )
            .timeout(const Duration(seconds: 20));

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final body = _safeDecodeBody(res);
          final data = body['data'];
          if (data is! Map<String, dynamic>) {
            throw ApiException(
              statusCode: res.statusCode,
              message: 'Malformed call response from server',
            );
          }
          return CallConnection.fromJson(data);
        }

        // 503 idempotent_request_pending: server is serializing two parallel
        // requests with the same key — wait briefly and retry with the same
        // key so we hit the now-populated cache. Distinct from livekit_
        // unavailable, which is fatal for this attempt window.
        if (res.statusCode == 503) {
          final body = _safeDecodeBody(res);
          final code = _extractErrorCode(body);
          if (code == 'idempotent_request_pending') {
            if (attempt + 1 < maxAttempts) {
              // Fixed 1s wait — short enough to feel responsive, long enough
              // for the sibling request to finish in the common case. The
              // exponential backoff schedule is for fresh attempts, not for
              // polling the cache.
              await Future<void>.delayed(const Duration(seconds: 1));
              continue;
            }
            throw IdempotencyPendingException(
              message: _extractErrorMessage(body) ??
                  'Server is processing a concurrent request',
            );
          }
          // Other 503 (e.g. livekit_unavailable) — surface, do not retry.
          _throwForResponse(res, body);
        }

        // Other 5xx → retry on the schedule. Don't loop forever even for
        // 500/502/504; after maxAttempts we surface the error.
        if (res.statusCode >= 500 && attempt + 1 < maxAttempts) {
          lastTransient = ApiException(
            statusCode: res.statusCode,
            message: 'Server error ${res.statusCode}',
          );
          lastTransientStack = StackTrace.current;
          await Future<void>.delayed(backoff[attempt]);
          continue;
        }

        // 4xx or terminal 5xx — propagate.
        _throwForResponse(res, _safeDecodeBody(res));
      } on TimeoutException catch (e, st) {
        if (attempt + 1 >= maxAttempts) {
          throw ApiException(
            statusCode: 0,
            message: 'Call request timed out',
          );
        }
        lastTransient = e;
        lastTransientStack = st;
        await Future<void>.delayed(backoff[attempt]);
      } on SocketException catch (e, st) {
        if (attempt + 1 >= maxAttempts) {
          throw ApiException(
            statusCode: 0,
            message: 'Network error: ${e.message}',
          );
        }
        lastTransient = e;
        lastTransientStack = st;
        await Future<void>.delayed(backoff[attempt]);
      } on http.ClientException catch (e, st) {
        if (attempt + 1 >= maxAttempts) {
          throw ApiException(
            statusCode: 0,
            message: 'Network error: ${e.message}',
          );
        }
        lastTransient = e;
        lastTransientStack = st;
        await Future<void>.delayed(backoff[attempt]);
      }
    }

    // Defensive: the loop above always either returns or throws. This is
    // a fallback to surface a transient if control somehow falls through.
    if (lastTransient != null) {
      Error.throwWithStackTrace(
        ApiException(statusCode: 0, message: 'Could not start call'),
        lastTransientStack ?? StackTrace.current,
      );
    }
    throw ApiException(statusCode: 0, message: 'Could not start call');
  }

  /// `POST /api/calls/:id/accept` — callee accepts.
  static Future<CallConnection> accept(String callId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/calls/$callId/accept'),
      headers: await _authHeaders(json: false),
    );
    final body = _decodeOrThrow(res, 'Failed to accept call');
    return CallConnection.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// `POST /api/calls/:id/reject` — callee declines while ringing.
  /// Server is silently idempotent if the call is no longer ringing.
  static Future<void> reject(String callId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/calls/$callId/reject'),
      headers: await _authHeaders(json: false),
    );
    _decodeOrThrow(res, 'Failed to reject call');
  }

  /// `POST /api/calls/:id/cancel` — caller hangs up before answer.
  /// Server is silently idempotent if the call is no longer ringing.
  static Future<void> cancel(String callId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/calls/$callId/cancel'),
      headers: await _authHeaders(json: false),
    );
    _decodeOrThrow(res, 'Failed to cancel call');
  }

  /// `POST /api/calls/:id/end` — either party hangs up an active call.
  /// Idempotent server-side if already ended.
  ///
  /// Returns the duration the server computed (null if it was already ended
  /// without a duration).
  static Future<int?> end({
    required String callId,
    CallEndReason reason = CallEndReason.normal,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/calls/$callId/end'),
      headers: await _authHeaders(),
      body: jsonEncode({'reason': callEndReasonToWire(reason)}),
    );
    final body = _decodeOrThrow(res, 'Failed to end call');
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return (data['durationSeconds'] as num?)?.toInt();
    }
    return null;
  }

  /// `GET /api/calls/:id` — fetch current state. Used for reconciliation
  /// after a missed socket event.
  ///
  /// Returns null when the user is no longer a participant (server returns
  /// HTTP 200 with `success: false` for that case — see contract §3).
  static Future<CallRecord?> get(String callId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/calls/$callId'),
      headers: await _authHeaders(json: false),
    );
    final body = _decodeOrThrow(res, 'Failed to load call');
    final data = body['data'];
    if (body['success'] != true || data is! Map<String, dynamic>) {
      return null;
    }
    return CallRecord.fromJson(data);
  }

  /// `POST /api/devices` — upsert this device's FCM token. Safe to call
  /// repeatedly; server reassigns userId if the token belonged to another
  /// user.
  static Future<void> registerDevice({
    required String token,
    String platform = 'android',
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/devices'),
      headers: await _authHeaders(),
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    _decodeOrThrow(res, 'Failed to register device');
  }

  /// `DELETE /api/devices/:token` — call on logout. Removes only rows where
  /// token AND current user match.
  static Future<void> unregisterDevice(String token) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/devices/$token'),
      headers: await _authHeaders(json: false),
    );
    _decodeOrThrow(res, 'Failed to unregister device');
  }

  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await AuthStorage.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

/// Thrown by [CallService.initiate] when the backend returns 409. The
/// `code` field carries the typed reason (`'callee_busy'`, `'caller_busy'`,
/// `'busy'`); [existing] is the conflicting call's snapshot, if the server
/// included one (which the post-fix backend always does for callee_busy and
/// caller_busy).
class CallBusyException extends ApiException {
  final String code;
  final ExistingCallInfo? existing;
  CallBusyException({
    required this.code,
    required super.message,
    this.existing,
  }) : super(statusCode: 409);
}

/// Thrown when the server is still computing a response for a sibling
/// request that holds the same `Idempotency-Key`. Transient — the caller
/// can dismiss it and let the user try again, or surface as a regular error.
class IdempotencyPendingException extends ApiException {
  IdempotencyPendingException({required super.message}) : super(statusCode: 503);
}

/// Decode the response body as a JSON map, or an empty map if parsing fails.
/// Errors are never thrown — callers branch on `res.statusCode` first.
Map<String, dynamic> _safeDecodeBody(http.Response res) {
  if (res.body.isEmpty) return const {};
  try {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}
  return const {};
}

/// Pull the typed error code out of a Nest exception payload. Nest places
/// the structured error under `body.message` for HttpException-derived
/// throws; older endpoints sometimes set `message` to a plain string.
String? _extractErrorCode(Map<String, dynamic> body) {
  final messageField = body['message'];
  if (messageField is Map<String, dynamic>) {
    return messageField['code']?.toString();
  }
  return null;
}

String? _extractErrorMessage(Map<String, dynamic> body) {
  final messageField = body['message'];
  if (messageField is Map<String, dynamic>) {
    return messageField['message']?.toString() ??
        messageField['error']?.toString();
  }
  if (messageField is String) return messageField;
  return null;
}

/// Throws the appropriate typed exception for a non-2xx response. Centralizes
/// the "where does the structured error live" logic so the retry loop above
/// stays readable.
Never _throwForResponse(http.Response res, Map<String, dynamic> body) {
  final code = _extractErrorCode(body);
  final message = _extractErrorMessage(body) ?? 'Failed to start call';

  if (res.statusCode == 409) {
    ExistingCallInfo? existing;
    final messageField = body['message'];
    if (messageField is Map<String, dynamic>) {
      final raw = messageField['existing'];
      if (raw is Map<String, dynamic>) {
        try {
          existing = ExistingCallInfo.fromJson(raw);
        } catch (_) {
          // Backward-compat: pre-fix backend didn't include `existing`. The
          // 409 still carries a valid `code` — caller surfaces a generic
          // busy error without the existing-call context.
          existing = null;
        }
      }
    }
    throw CallBusyException(
      code: code ?? 'busy',
      message: message,
      existing: existing,
    );
  }

  throw ApiException(
    statusCode: res.statusCode,
    message: code != null ? '$code: $message' : message,
  );
}

/// Decode JSON, raise [ApiException] on non-2xx. Used by the non-initiate
/// endpoints (accept/reject/cancel/end/get/device-register) which don't need
/// idempotency keys or retry policies.
Map<String, dynamic> _decodeOrThrow(http.Response res, String fallback) {
  Map<String, dynamic>? body;
  try {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) body = decoded;
  } catch (_) {}
  if (res.statusCode < 200 || res.statusCode >= 300) {
    final messageField = body?['message'];
    String message = fallback;
    String? code;
    if (messageField is Map<String, dynamic>) {
      code = messageField['code']?.toString();
      message = messageField['error']?.toString() ?? fallback;
    } else if (messageField is String) {
      message = messageField;
    }
    if (res.statusCode == 409 && code != null) {
      throw CallBusyException(code: code, message: message);
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: code != null ? '$code: $message' : message,
    );
  }
  return body ?? const {};
}
