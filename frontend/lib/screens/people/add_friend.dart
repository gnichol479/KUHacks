import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_with_score.dart';

/// Translates a `/contacts/add` 200 response into the snackbar text the user
/// should see. The backend returns the same shape whether the row was newly
/// inserted or already existed; only `message`/`status` distinguish the cases.
String addContactSnackText(Map<String, dynamic> result) {
  final status = (result['status'] as String?) ?? '';
  final message = (result['message'] as String?) ?? '';
  if (status == 'accepted') return 'Already a contact';
  if (status == 'pending' && message == 'Request already exists') {
    return 'Already requested';
  }
  return 'Request sent';
}

/// True only when the call actually created a new pending request (vs.
/// returning an existing accepted/pending row).
bool isNewPendingAddResult(Map<String, dynamic> result) {
  return result['status'] == 'pending' && result['message'] == 'Request sent';
}

class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({super.key});

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _auth = AuthService();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _searching = false;
  String? _pendingId;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    try {
      final data = await _auth.searchUsers(q);
      if (!mounted) return;
      setState(() {
        _results = data;
        _searching = false;
      });
    } catch (e) {
      debugPrint('SEARCH error: $e');
      if (!mounted) return;
      setState(() {
        _results = [];
        _searching = false;
      });
    }
  }

  Future<void> _send(Map<String, dynamic> user) async {
    final id = user['id'] as String;
    setState(() => _pendingId = id);
    try {
      final result = await _auth.addContact(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(addContactSnackText(result))),
      );
      // Hand the raw API response and the target user back to the caller so
      // it can optimistically insert into the Sent list and decide whether to
      // bump cross-screen reload listeners.
      Navigator.pop(context, {'result': result, 'user': user});
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _pendingId = null);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Try again.')),
      );
      setState(() => _pendingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                "Add Friend",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Search for a user by their name or @username.",
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _onChanged,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white70,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Name or @username',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _resultsBlock(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultsBlock() {
    if (_searchController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No matches',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _results.length; i++) ...[
            _resultTile(_results[i] as Map<String, dynamic>),
            if (i != _results.length - 1)
              const Divider(color: Colors.white10, height: 1),
          ],
        ],
      ),
    );
  }

  Widget _resultTile(Map<String, dynamic> user) {
    final id = user['id'] as String;
    final isPending = _pendingId == id;
    final fullName = (user['full_name'] as String?) ?? '';
    final username = (user['username'] as String?) ?? '';
    final initialSrc = fullName.isNotEmpty
        ? fullName
        : (username.isNotEmpty ? username : '?');
    return ListTile(
      leading: AvatarWithScore(
        radius: 20,
        score: (user['accountability_score'] as num?)?.toInt(),
        avatarBase64: user['avatar_base64'] as String?,
        child: Text(
          initialSrc[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        fullName,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        '@$username',
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: isPending
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.person_add, color: Colors.lightBlueAccent),
      onTap: isPending ? null : () => _send(user),
    );
  }
}
