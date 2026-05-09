import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'auth_storage.dart';

class AuthService {
  /// Creates a new account, persists the returned token + userId, and returns
  /// the userId for the caller.
  static Future<String> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 201 && res.statusCode != 200) {
      final errors = body['errors'];
      throw ApiException(
        statusCode: res.statusCode,
        message: body['message']?.toString() ?? 'Signup failed',
        fieldErrors: errors is List
            ? errors.map((e) {
                final m = e as Map<String, dynamic>;
                final path = m['path'];
                return FieldError(
                  field: path is List && path.isNotEmpty
                      ? path.first.toString()
                      : '',
                  message: m['message']?.toString() ?? '',
                );
              }).toList()
            : null,
      );
    }

    final data = body['data'] as Map<String, dynamic>;
    final token = data['accessToken'] as String;
    final userId = data['userId'] as String;

    await AuthStorage.saveSession(token: token, userId: userId);
    return userId;
  }

  /// Logs the user in. The login response only carries the token, so we just
  /// persist that — `userId` is filled later from `GET /users/me`.
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode != 200 && res.statusCode != 201) {
      final errors = body['errors'];
      throw ApiException(
        statusCode: res.statusCode,
        message: body['message']?.toString() ?? 'Login failed',
        fieldErrors: errors is List
            ? errors.map((e) {
                final m = e as Map<String, dynamic>;
                final path = m['path'];
                return FieldError(
                  field: path is List && path.isNotEmpty
                      ? path.first.toString()
                      : '',
                  message: m['message']?.toString() ?? '',
                );
              }).toList()
            : null,
      );
    }

    final data = body['data'] as Map<String, dynamic>;
    final token = data['accessToken'] as String;
    await AuthStorage.saveSession(token: token, userId: '');
  }
}
