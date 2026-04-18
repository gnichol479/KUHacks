import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thin HTTP wrapper around the Flask backend.
///
/// Centralises the base URL, JSON encoding/decoding, and JWT injection so
/// individual services (auth, ledgers, etc.) don't have to duplicate the
/// boilerplate.
class ApiClient {
  ApiClient._();

  /// Base URL of the Flask backend. The iPhone uses this LAN address to reach
  /// the laptop running `python app.py` on `0.0.0.0:5001`.
  static const String baseUrl = 'http://10.108.93.11:5001';

  /// SharedPreferences key for the persisted JWT.
  static const String tokenKey = 'auth_token';

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<http.Response> postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    return http.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(String path, {bool auth = false}) async {
    return http.get(_uri(path), headers: await _headers(auth: auth));
  }
}

/// Exception thrown when the API returns a non-2xx response. The message is
/// pulled from the JSON `error` field when possible so screens can surface it
/// directly in a SnackBar.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  static ApiException fromResponse(http.Response response) {
    String message = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        message = decoded['error'] as String;
      }
    } catch (_) {
      // Body wasn't JSON; keep the default message.
    }
    return ApiException(message, statusCode: response.statusCode);
  }
}
