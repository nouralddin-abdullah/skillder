import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'auth_storage.dart';

class UserService {
  static Future<Map<String, String>> _authHeaders({
    bool json = true,
  }) async {
    final token = await AuthStorage.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /users/me — full profile object. Throws [ApiException] on auth /
  /// network failures so the caller can react (e.g. clear the saved token).
  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: await _authHeaders(json: false),
    );

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: body?['message']?.toString() ?? 'Failed to load profile',
      );
    }
    return body!['data'] as Map<String, dynamic>;
  }

  /// PATCH /users/me — partial update with any subset of profile fields.
  static Future<Map<String, dynamic>> patchMe(
    Map<String, dynamic> fields,
  ) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: await _authHeaders(),
      body: jsonEncode(fields),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: body['message']?.toString() ?? 'Update failed',
      );
    }
    return body;
  }

  /// POST /users/me/photos (multipart). Pass either a file path (native) or
  /// raw bytes (web). Returns the new photo `{ id, url, position }`.
  static Future<Map<String, dynamic>> uploadPhoto({
    String? filePath,
    Uint8List? bytes,
    String filename = 'photo.jpg',
  }) async {
    assert(filePath != null || bytes != null);

    final uri = Uri.parse('${ApiConfig.baseUrl}/users/me/photos');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _authHeaders(json: false));

    final effectiveFilename = (filePath != null && filename == 'photo.jpg')
        ? File(filePath).uri.pathSegments.last
        : filename;
    final contentType = _mimeFromFilename(effectiveFilename);

    if (kIsWeb || filePath == null) {
      req.files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes!,
        filename: effectiveFilename,
        contentType: contentType,
      ));
    } else {
      req.files.add(await http.MultipartFile.fromPath(
        'photo',
        filePath,
        filename: effectiveFilename,
        contentType: contentType,
      ));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: body['message']?.toString() ?? 'Photo upload failed',
      );
    }
    return body['data'] as Map<String, dynamic>;
  }

  /// PATCH /users/me/photos/order — reorder photos by passing their IDs in
  /// the desired order. Returns the updated photos list.
  static Future<List<dynamic>> reorderPhotos(List<String> orderedIds) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/me/photos/order'),
      headers: await _authHeaders(),
      body: jsonEncode({'order': orderedIds}),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: body['message']?.toString() ?? 'Reorder failed',
      );
    }
    return body['data'] as List<dynamic>;
  }

  /// DELETE /users/me/photos/:id — assumes standard REST. Adjust if needed.
  static Future<void> deletePhoto(String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/users/me/photos/$id'),
      headers: await _authHeaders(json: false),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
      throw ApiException(
        statusCode: res.statusCode,
        message: body?['message']?.toString() ?? 'Delete failed',
      );
    }
  }

  static MediaType _mimeFromFilename(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
