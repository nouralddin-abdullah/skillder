import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/chat_models.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_storage.dart';

/// Top-tier upload pipeline for chat media.
///
/// On native, uses `dart:io HttpClient` to PUT a file straight from disk
/// — bytes are read in chunks, never held entirely in memory. That's how
/// you upload a 100MB video on a phone with 1GB free RAM without OOM.
///
/// On web, falls back to in-memory bytes (the only option without
/// `dart:io`). The chat outbox keeps file paths for native, bytes for web.
class MediaUploader {
  /// Streams from a local file straight into the presigned PUT request.
  /// Returns when R2 confirms 2xx. Throws [ApiException] otherwise.
  static Future<void> uploadFile({
    required String uploadUrl,
    required File file,
    required String contentType,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final length = await file.length();
    final client = HttpClient();
    try {
      final request = await client.putUrl(Uri.parse(uploadUrl));
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      request.headers.contentLength = length;

      var sent = 0;
      // Pipe the file chunks straight into the request — never buffers the
      // whole video in RAM.
      await for (final chunk in file.openRead()) {
        request.add(chunk);
        sent += chunk.length;
        onProgress?.call(sent, length);
      }
      final response = await request.close();
      // Drain the body so the connection can be reused / closed cleanly.
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Direct upload failed (${response.statusCode})',
        );
      }
    } finally {
      client.close();
    }
  }

  /// In-memory fallback for web (and small images on native if the caller
  /// already has bytes loaded).
  static Future<void> uploadBytes({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
        'Content-Length': bytes.length.toString(),
      },
      body: bytes,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Direct upload failed (${res.statusCode})',
      );
    }
  }

  /// Sign + PUT in one call. Picks the streaming path on native when a
  /// file path is provided; falls back to bytes everywhere else.
  static Future<String> uploadAndSign({
    required String chatId,
    required String contentType,
    String? filePath,
    Uint8List? bytes,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    assert(filePath != null || bytes != null);

    // Compute size without slurping the whole file into memory.
    final size = filePath != null && !kIsWeb
        ? await File(filePath).length()
        : bytes!.length;

    // 1. POST /media/sign
    final token = await AuthStorage.getToken();
    final signRes = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/media/sign'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'contentType': contentType, 'size': size}),
    );
    if (signRes.statusCode < 200 || signRes.statusCode >= 300) {
      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(signRes.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {}
      throw ApiException(
        statusCode: signRes.statusCode,
        message: body?['message']?.toString() ?? 'Failed to sign upload',
      );
    }
    final signed = MediaUploadResult.fromJson(
      (jsonDecode(signRes.body) as Map<String, dynamic>)['data']
          as Map<String, dynamic>,
    );

    // 2. PUT — streamed from file on native, in-memory on web.
    if (!kIsWeb && filePath != null) {
      await uploadFile(
        uploadUrl: signed.uploadUrl,
        file: File(filePath),
        contentType: contentType,
        onProgress: onProgress,
      );
    } else {
      await uploadBytes(
        uploadUrl: signed.uploadUrl,
        bytes: bytes!,
        contentType: contentType,
      );
    }

    return signed.mediaUrl;
  }
}
