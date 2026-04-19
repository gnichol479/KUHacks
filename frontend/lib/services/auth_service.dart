import 'dart:convert';
import 'dart:typed_data';

import 'api_client.dart';

class AuthService {
  Future<void> register(String email, String password) async {
    await ApiClient.postJson('/register', {
      'email': email,
      'password': password,
    });
  }

  Future<String> login(String email, String password) async {
    final data = await ApiClient.postJson('/login', {
      'email': email,
      'password': password,
    });
    final token = data['token'];
    if (token is! String || token.isEmpty) {
      throw ApiException('Login response missing token', 500);
    }
    await ApiClient.setToken(token);
    return token;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    return ApiClient.getJson('/profile', auth: true);
  }

  /// Partial update for the user's profile. Pass `clearAvatar: true` (or
  /// leave `avatarBase64` null while setting `clearAvatar`) to remove the
  /// existing photo. Otherwise pass non-null `avatarBase64` to upload a new
  /// one.
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? avatarBase64,
    String? avatarMime,
    bool clearAvatar = false,
  }) {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (clearAvatar) {
      body['avatar_base64'] = null;
    } else if (avatarBase64 != null) {
      body['avatar_base64'] = avatarBase64;
      body['avatar_mime'] = avatarMime ?? 'image/jpeg';
    }
    return ApiClient.patchJson('/profile', body, auth: true);
  }

  Future<Map<String, dynamic>> completeOnboarding({
    required String fullName,
    required String username,
    required String phone,
  }) {
    return ApiClient.postJson(
      '/onboarding',
      {
        'full_name': fullName,
        'username': username,
        'phone': phone,
      },
      auth: true,
    );
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final result = await ApiClient.getDecoded(
      '/users/search',
      auth: true,
      query: {'q': query},
    );
    return result is List ? result : const [];
  }

  Future<Map<String, dynamic>> addContact(String userId) {
    return ApiClient.postJson(
      '/contacts/add',
      {'user_id': userId},
      auth: true,
    );
  }

  Future<List<dynamic>> fetchLedgers() async {
    final result = await ApiClient.getDecoded('/ledgers', auth: true);
    return result is List ? result : const [];
  }

  Future<Map<String, dynamic>> fetchLedger(String ledgerId) {
    return ApiClient.getJson('/ledgers/$ledgerId', auth: true);
  }

  Future<Map<String, dynamic>> addLedgerEntry({
    required String ledgerId,
    required String description,
    required double amount,
    required bool theyOweMe,
    int? dueInDays,
  }) {
    return ApiClient.postJson(
      '/ledgers/$ledgerId/entries',
      {
        'description': description,
        'amount': amount,
        'direction': theyOweMe ? 'they_owe_me' : 'i_owe_them',
        if (dueInDays != null) 'due_in_days': dueInDays,
      },
      auth: true,
    );
  }

  Future<Map<String, dynamic>> settleUp({
    required String ledgerId,
    required double amount,
    required String method,
  }) {
    return ApiClient.postJson(
      '/ledgers/$ledgerId/settle',
      {
        'amount': amount,
        'method': method,
      },
      auth: true,
    );
  }

  /// Settle 1-8 ledger debts atomically inside a single XRPL Batch
  /// transaction. With `mode: "ALLORNOTHING"` (default), either every
  /// payment goes through and every ledger gets its settlement entry, or
  /// none of them do. Used by the home-tab "Auto-Settle" card and any
  /// multi-recipient picker.
  Future<Map<String, dynamic>> settleBatch({
    required List<Map<String, dynamic>> items,
    String mode = 'ALLORNOTHING',
  }) {
    return ApiClient.postJson(
      '/ledgers/settle-batch',
      {
        'items': items,
        'mode': mode,
      },
      auth: true,
    );
  }

  Future<Map<String, dynamic>> forgiveDebt({
    required String ledgerId,
    required double amount,
    bool mintMemory = false,
    String? memoryMessage,
  }) {
    return ApiClient.postJson(
      '/ledgers/$ledgerId/forgive',
      {
        'amount': amount,
        if (mintMemory) 'mint_memory': true,
        if (mintMemory) 'memory_message': (memoryMessage ?? '').trim(),
      },
      auth: true,
    );
  }

  /// Memories are XRPL NFTs minted as a keepsake when a user forgives a
  /// debt. The endpoint returns every memory the caller has issued or
  /// received, newest first.
  Future<List<dynamic>> fetchMemories() async {
    final result = await ApiClient.getDecoded('/memories', auth: true);
    return result is List ? result : const [];
  }

  Future<List<dynamic>> fetchRequests() async {
    final result = await ApiClient.getDecoded(
      '/contacts/requests',
      auth: true,
    );
    return result is List ? result : const [];
  }

  Future<List<dynamic>> fetchSentRequests() async {
    final result = await ApiClient.getDecoded(
      '/contacts/sent',
      auth: true,
    );
    return result is List ? result : const [];
  }

  Future<void> acceptRequest(String ledgerId) async {
    await ApiClient.postJson(
      '/contacts/accept',
      {'ledger_id': ledgerId},
      auth: true,
    );
  }

  Future<void> rejectRequest(String ledgerId) async {
    await ApiClient.postJson(
      '/contacts/reject',
      {'ledger_id': ledgerId},
      auth: true,
    );
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    required List<String> memberIds,
  }) {
    return ApiClient.postJson(
      '/groups',
      {'name': name, 'member_user_ids': memberIds},
      auth: true,
    );
  }

  Future<List<dynamic>> fetchGroups() async {
    final result = await ApiClient.getDecoded('/groups', auth: true);
    return result is List ? result : const [];
  }

  Future<Map<String, dynamic>> fetchGroup(String groupId) {
    return ApiClient.getJson('/groups/$groupId', auth: true);
  }

  Future<Map<String, dynamic>> addGroupEntry({
    required String groupId,
    required String toUserId,
    required double amount,
    required String description,
    bool theyOweMe = false,
    int? dueInDays,
  }) {
    return ApiClient.postJson(
      '/groups/$groupId/entries',
      {
        'to_user_id': toUserId,
        'amount': amount,
        'description': description,
        'direction': theyOweMe ? 'they_owe_me' : 'i_owe_them',
        if (dueInDays != null) 'due_in_days': dueInDays,
      },
      auth: true,
    );
  }

  Future<Map<String, dynamic>> settleGroup({
    required String groupId,
    required String toUserId,
    required double amount,
  }) {
    return ApiClient.postJson(
      '/groups/$groupId/settle',
      {
        'to_user_id': toUserId,
        'amount': amount,
        'method': 'xrp',
      },
      auth: true,
    );
  }

  /// Create a pending IOU request on a 1:1 ledger. The other user must
  /// accept via [acceptEntryRequest] before the entry actually mutates the
  /// ledger balance.
  Future<Map<String, dynamic>> createLedgerEntryRequest({
    required String ledgerId,
    required String description,
    required double amount,
    required bool theyOweMe,
    int? dueInDays,
  }) {
    return ApiClient.postJson(
      '/ledgers/$ledgerId/entry-requests',
      {
        'description': description,
        'amount': amount,
        'direction': theyOweMe ? 'they_owe_me' : 'i_owe_them',
        if (dueInDays != null) 'due_in_days': dueInDays,
      },
      auth: true,
    );
  }

  /// Create a pending IOU request inside a group between the caller and
  /// [toUserId]. The recipient must accept before the entry is applied.
  Future<Map<String, dynamic>> createGroupEntryRequest({
    required String groupId,
    required String toUserId,
    required double amount,
    required String description,
    bool theyOweMe = false,
    int? dueInDays,
  }) {
    return ApiClient.postJson(
      '/groups/$groupId/entry-requests',
      {
        'to_user_id': toUserId,
        'amount': amount,
        'description': description,
        'direction': theyOweMe ? 'they_owe_me' : 'i_owe_them',
        if (dueInDays != null) 'due_in_days': dueInDays,
      },
      auth: true,
    );
  }

  /// Pending IOU requests where the caller is the recipient and must
  /// accept or reject before the entry hits the ledger/group.
  Future<List<dynamic>> fetchEntryRequestsIncoming() async {
    final result = await ApiClient.getDecoded(
      '/entry-requests/incoming',
      auth: true,
    );
    return result is List ? result : const [];
  }

  /// Pending IOU requests the caller has sent and is waiting on.
  Future<List<dynamic>> fetchEntryRequestsSent() async {
    final result = await ApiClient.getDecoded(
      '/entry-requests/sent',
      auth: true,
    );
    return result is List ? result : const [];
  }

  Future<Map<String, dynamic>> acceptEntryRequest(String requestId) {
    return ApiClient.postJson(
      '/entry-requests/$requestId/accept',
      const <String, dynamic>{},
      auth: true,
    );
  }

  Future<Map<String, dynamic>> rejectEntryRequest(String requestId) {
    return ApiClient.postJson(
      '/entry-requests/$requestId/reject',
      const <String, dynamic>{},
      auth: true,
    );
  }

  /// Send a receipt photo to the backend, which forwards it to Gemini and
  /// returns `{store: String, total: num}` — used by the New IOU sheet to
  /// auto-fill the description and amount fields.
  Future<Map<String, dynamic>> scanReceipt({
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) {
    return ApiClient.postJson(
      '/scan-receipt',
      {
        'image_base64': base64Encode(bytes),
        'mime_type': mimeType,
      },
      auth: true,
    );
  }
}
