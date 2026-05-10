import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_models.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_storage.dart';

/// REST wrapper for likes + matches. Mirrors `MatchingController` on the
/// backend.
class MatchingService {
  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await AuthStorage.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// `POST /likes` — express interest (or pass) on another user.
  ///
  /// If the other user has already liked you and you also `'like'`, the
  /// response contains `matched: true` with a fresh `matchId` and `chatId`.
  /// Backend handles soft-removed match resurrection transparently.
  static Future<LikeResult> createLike({
    required String toUserId,
    required String kind, // 'like' | 'pass'
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/likes'),
      headers: await _authHeaders(),
      body: jsonEncode({'toUserId': toUserId, 'kind': kind}),
    );
    final body = _decodeOrThrow(res, 'Failed to record like');
    return LikeResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// `GET /matches` — current user's matches, including soft-removed ones
  /// (those carry `removedByMe: true`).
  static Future<List<MatchSummary>> listMatches() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/matches'),
      headers: await _authHeaders(json: false),
    );
    final body = _decodeOrThrow(res, 'Failed to load matches');
    final data = body['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MatchSummary.fromJson)
        .toList();
  }

  /// `DELETE /matches/:matchId` — silent unmatch.
  ///
  /// On success the backend soft-removes the match for the current user
  /// only. The other party sees no change. Re-liking via [createLike] will
  /// resurrect the same match.
  static Future<void> unmatch(String matchId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/matches/$matchId'),
      headers: await _authHeaders(json: false),
    );
    _decodeOrThrow(res, 'Failed to unmatch');
  }
}

Map<String, dynamic> _decodeOrThrow(http.Response res, String fallback) {
  Map<String, dynamic>? body;
  try {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) body = decoded;
  } catch (_) {}
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(
      statusCode: res.statusCode,
      message: body?['message']?.toString() ?? fallback,
    );
  }
  return body ?? const {};
}
