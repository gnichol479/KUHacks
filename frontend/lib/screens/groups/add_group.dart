import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_with_score.dart';

/// Bottom sheet for creating a new group. Lets the user pick a name and
/// multi-select members from their accepted contacts list.
class AddGroupSheet extends StatefulWidget {
  const AddGroupSheet({super.key});

  @override
  State<AddGroupSheet> createState() => _AddGroupSheetState();
}

class _AddGroupSheetState extends State<AddGroupSheet> {
  final TextEditingController _nameController = TextEditingController();
  final AuthService _auth = AuthService();
  final Set<String> _selected = <String>{};

  bool _loadingContacts = true;
  bool _loadFailed = false;
  bool _submitting = false;
  String? _error;
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final raw = await _auth.fetchLedgers();
      if (!mounted) return;
      final mapped = <Map<String, dynamic>>[];
      for (final l in raw.cast<Map<String, dynamic>>()) {
        final other = (l['other_user'] as Map?) ?? {};
        final id = other['id'] as String?;
        if (id == null) continue;
        mapped.add({
          'id': id,
          'full_name': other['full_name'] as String?,
          'username': other['username'] as String?,
          'accountability_score':
              (other['accountability_score'] as num?)?.toInt(),
          'avatar_base64': other['avatar_base64'] as String?,
        });
      }
      setState(() {
        _contacts = mapped;
        _loadingContacts = false;
        _loadFailed = false;
      });
    } catch (e) {
      debugPrint('ADD_GROUP fetchLedgers error: $e');
      if (!mounted) return;
      setState(() {
        _contacts = [];
        _loadingContacts = false;
        _loadFailed = true;
      });
    }
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _selected.isNotEmpty &&
      !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _auth.createGroup(
        name: _nameController.text.trim(),
        memberIds: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (e) {
      debugPrint('CREATE_GROUP error: $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Network error. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'New Group',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white70,
                maxLength: 80,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Group name (e.g. Roommates)',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MEMBERS',
                  style: TextStyle(
                    color: Colors.white54,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _selected.isEmpty
                      ? 'Pick at least one'
                      : '${_selected.length} selected',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(child: _contactsBlock()),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _canSubmit ? _submit : null,
              child: Opacity(
                opacity: _canSubmit ? 1 : 0.5,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Group',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactsBlock() {
    if (_loadingContacts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "Couldn't load contacts.",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: _loadContacts,
              child: const Text(
                'Retry',
                style: TextStyle(color: Color(0xFF7F8CFF)),
              ),
            ),
          ],
        ),
      );
    }
    if (_contacts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No contacts yet. Add friends first to build a group.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _contacts.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Colors.white10, height: 1),
        itemBuilder: (_, i) => _contactTile(_contacts[i]),
      ),
    );
  }

  Widget _contactTile(Map<String, dynamic> contact) {
    final id = contact['id'] as String;
    final selected = _selected.contains(id);
    final fullName = (contact['full_name'] as String?) ?? '';
    final username = contact['username'] as String?;
    final initialSrc = fullName.isNotEmpty
        ? fullName
        : (username != null && username.isNotEmpty ? username : '?');
    return ListTile(
      leading: AvatarWithScore(
        radius: 20,
        score: (contact['accountability_score'] as num?)?.toInt(),
        avatarBase64: contact['avatar_base64'] as String?,
        child: Text(
          initialSrc[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        fullName.isNotEmpty ? fullName : '@${username ?? ''}',
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: username != null
          ? Text('@$username', style: const TextStyle(color: Colors.white54))
          : null,
      trailing: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected ? const Color(0xFF7F8CFF) : Colors.white38,
      ),
      onTap: () {
        setState(() {
          if (selected) {
            _selected.remove(id);
          } else {
            _selected.add(id);
          }
        });
      },
    );
  }
}
