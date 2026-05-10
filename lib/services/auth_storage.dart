import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'access_token';
  static const _userIdKey = 'user_id';

  static Future<void> saveSession({
    required String token,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // If the auth response didn't include a userId (e.g. /auth/login only
    // returns the access token), fall back to extracting the `sub` claim
    // from the JWT itself so downstream code always has a valid id.
    final effectiveUserId =
        userId.isNotEmpty ? userId : (extractUserIdFromJwt(token) ?? '');
    await prefs.setString(_userIdKey, effectiveUserId);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Returns the current user's id, deriving it from the saved JWT if the
  /// stored value is missing/empty (self-heals sessions that were created
  /// before the JWT-fallback was wired up).
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_userIdKey);
    if (stored != null && stored.isNotEmpty) return stored;

    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;
    final fromToken = extractUserIdFromJwt(token);
    if (fromToken != null && fromToken.isNotEmpty) {
      await prefs.setString(_userIdKey, fromToken);
      return fromToken;
    }
    return null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }
}

/// Decodes a JWT and returns the `sub` claim (the backend stores the user
/// id there). Returns `null` on any parse failure.
String? extractUserIdFromJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    var payload = parts[1];
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    final decoded = utf8.decode(base64Url.decode(payload));
    final json = jsonDecode(decoded);
    if (json is Map<String, dynamic>) {
      final sub = json['sub'];
      if (sub is String) return sub;
    }
    return null;
  } catch (_) {
    return null;
  }
}
