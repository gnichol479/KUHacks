import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const String baseUrl = 'https://hackku-backend.fly.dev';
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static void _logResponse(String method, String path, http.Response response) {
    if (!kDebugMode) return;
    final status = response.statusCode;
    final bytes = response.bodyBytes.length;
    debugPrint('API $method $path -> $status (${bytes}b)');
    if (status < 200 || status >= 300) {
      final body = response.body;
      final preview = body.length > 400 ? '${body.substring(0, 400)}…' : body;
      debugPrint('API $method $path error body: $preview');
    }
  }

  static Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(
      uri,
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    _logResponse('POST', path, response);
    return _handle(response);
  }

  static Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.patch(
      uri,
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    _logResponse('PATCH', path, response);
    return _handle(response);
  }

  static Future<Map<String, dynamic>> getJson(
    String path, {
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(
      uri,
      headers: await _headers(auth: auth),
    );
    _logResponse('GET', path, response);
    return _handle(response);
  }

  /// GET that returns the raw decoded JSON value (List, Map, or null).
  /// Use this when an endpoint may return a bare JSON array.
  static Future<dynamic> getDecoded(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await http.get(
      uri,
      headers: await _headers(auth: auth),
    );
    _logResponse('GET', path, response);
    return _handleDecoded(response);
  }

  static dynamic _handleDecoded(http.Response response) {
    final status = response.statusCode;
    final raw = response.body;

    dynamic decoded;
    if (raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        // Non-JSON body; treat as null for parsing purposes.
      }
    }

    if (status >= 200 && status < 300) {
      return decoded;
    }

    final errorMessage = (decoded is Map && decoded['error'] is String)
        ? decoded['error'] as String
        : 'Request failed (HTTP $status)';
    throw ApiException(errorMessage, status);
  }

  static Map<String, dynamic> _handle(http.Response response) {
    final status = response.statusCode;
    final raw = response.body;

    Map<String, dynamic> decoded = const {};
    if (raw.isNotEmpty) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } catch (_) {
        // Non-JSON body; treat as empty for parsing purposes.
      }
    }

    if (status >= 200 && status < 300) {
      return decoded;
    }

    final errorMessage = (decoded['error'] is String)
        ? decoded['error'] as String
        : 'Request failed (HTTP $status)';
    throw ApiException(errorMessage, status);
  }
}
