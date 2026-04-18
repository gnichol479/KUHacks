import 'dart:convert';

import 'api_client.dart';

/// Lightweight DTO for the authenticated user returned by `/profile`.
class UserProfile {
  UserProfile({required this.id, required this.email, this.createdAt});

  final String id;
  final String email;
  final DateTime? createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}

/// High-level wrapper around the auth-related backend endpoints.
class AuthService {
  AuthService._();

  /// POST /register — creates the account but does NOT auto-login. The UI
  /// then calls [login] to obtain a token.
  static Future<void> register(String email, String password) async {
    final response = await ApiClient.postJson('/register', {
      'email': email.trim(),
      'password': password,
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response);
    }
  }

  /// POST /login — on success, persists the JWT in SharedPreferences and
  /// returns it.
  static Future<String> login(String email, String password) async {
    final response = await ApiClient.postJson('/login', {
      'email': email.trim(),
      'password': password,
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response);
    }

    final body = jsonDecode(response.body);
    final token = body is Map ? body['token'] as String? : null;
    if (token == null || token.isEmpty) {
      throw ApiException('Login response missing token');
    }
    await ApiClient.setToken(token);
    return token;
  }

  /// GET /profile — fetches the currently authenticated user. Throws an
  /// [ApiException] with status 401 if the stored token is invalid or expired.
  static Future<UserProfile> fetchProfile() async {
    final response = await ApiClient.get('/profile', auth: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserProfile.fromJson(body);
  }

  static Future<bool> hasToken() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    await ApiClient.clearToken();
  }
}
