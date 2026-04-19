import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';

// 🔑 SAME KEYS (must match settings_sheet.dart)
class SettingsKeys {
  static const profile = 'profile';
  static const bank = 'bank';
  static const security = 'security';
  static const appearance = 'appearance';
  static const privacy = 'privacy';
  static const support = 'support';
}

class SettingsDetailPage extends StatefulWidget {
  final String type;

  const SettingsDetailPage({super.key, required this.type});

  @override
  State<SettingsDetailPage> createState() => _SettingsDetailPageState();
}

class _SettingsDetailPageState extends State<SettingsDetailPage> {
  final TextEditingController cardController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController _displayNameCtrl = TextEditingController();

  final AuthService _auth = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  bool darkMode = true;
  bool allowVisibility = true;

  // Profile-tab state
  bool _profileLoading = false;
  bool _profileSaving = false;
  String? _profileError;
  Uint8List? _avatarBytes;
  String _avatarMime = 'image/jpeg';
  // Tracks whether the user explicitly removed the existing photo so Save
  // can issue a clearing PATCH instead of a no-op.
  bool _avatarRemoved = false;
  // Initial values pulled from /profile so we only send changed fields.
  String _initialName = '';
  String? _initialAvatarB64;

  @override
  void initState() {
    super.initState();
    if (widget.type == SettingsKeys.profile) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    cardController.dispose();
    passwordController.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      final data = await _auth.fetchProfile();
      if (!mounted) return;
      final profile = (data['profile'] as Map?) ?? const {};
      final name = (profile['full_name'] as String?) ?? '';
      final b64 = profile['avatar_base64'] as String?;
      final mime = (profile['avatar_mime'] as String?) ?? 'image/jpeg';
      setState(() {
        _initialName = name;
        _displayNameCtrl.text = name;
        _initialAvatarB64 = b64;
        _avatarMime = mime;
        _avatarBytes = (b64 != null && b64.isNotEmpty)
            ? _safeDecode(b64)
            : null;
        _profileLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.message;
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Could not load your profile.';
        _profileLoading = false;
      });
    }
  }

  Uint8List? _safeDecode(String b64) {
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showPhotoSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white70),
              title: const Text(
                'Take photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white70),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (_avatarBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Color(0xFFFFB4B4)),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: Color(0xFFFFB4B4)),
                ),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'remove') {
      setState(() {
        _avatarBytes = null;
        _avatarRemoved = true;
      });
      return;
    }

    final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _profileError = 'Could not open the photo picker.');
      return;
    }
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final mime = picked.mimeType ?? _guessMime(picked.path);
    if (!mounted) return;
    setState(() {
      _avatarBytes = bytes;
      _avatarMime = mime;
      _avatarRemoved = false;
      _profileError = null;
    });
  }

  String _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _saveProfile() async {
    if (_profileSaving) return;
    final name = _displayNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _profileError = 'Display name cannot be empty.');
      return;
    }

    final nameChanged = name != _initialName;
    final hasNewAvatar = _avatarBytes != null &&
        (_initialAvatarB64 == null || _avatarRemoved == false &&
            base64Encode(_avatarBytes!) != _initialAvatarB64);
    final clearingAvatar =
        _avatarRemoved && (_initialAvatarB64 != null && _initialAvatarB64!.isNotEmpty);

    if (!nameChanged && !hasNewAvatar && !clearingAvatar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save.')),
      );
      return;
    }

    setState(() {
      _profileSaving = true;
      _profileError = null;
    });

    try {
      String? avatarB64;
      if (hasNewAvatar && _avatarBytes != null) {
        avatarB64 = base64Encode(_avatarBytes!);
      }
      final result = await _auth.updateProfile(
        fullName: nameChanged ? name : null,
        avatarBase64: avatarB64,
        avatarMime: hasNewAvatar ? _avatarMime : null,
        clearAvatar: clearingAvatar,
      );
      if (!mounted) return;

      final profile = (result['profile'] as Map?) ?? const {};
      setState(() {
        _initialName = (profile['full_name'] as String?) ?? name;
        _initialAvatarB64 = profile['avatar_base64'] as String?;
        _avatarRemoved = false;
        _profileSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.message;
        _profileSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Network error while saving.';
        _profileSaving = false;
      });
    }
  }

  String _appBarTitle() {
    switch (widget.type) {
      case SettingsKeys.profile:
        return 'Profile';
      case SettingsKeys.bank:
        return 'Bank & Wallet';
      case SettingsKeys.security:
        return 'Security';
      case SettingsKeys.appearance:
        return 'Appearance';
      case SettingsKeys.privacy:
        return 'Privacy';
      case SettingsKeys.support:
        return 'Help & Support';
      default:
        return widget.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F1A),
        title: Text(_appBarTitle()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.type) {
      case SettingsKeys.profile:
        return _profileUI();

      case SettingsKeys.bank:
        return _bankUI();

      case SettingsKeys.security:
        return _securityUI();

      case SettingsKeys.appearance:
        return _appearanceUI();

      case SettingsKeys.privacy:
        return _privacyUI();

      case SettingsKeys.support:
        return _supportUI();

      default:
        return const Text(
          "ERROR: TYPE NOT MATCHING",
          style: TextStyle(color: Colors.red),
        );
    }
  }

  // 👤 PROFILE
  Widget _profileUI() {
    if (_profileLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7F8CFF)),
      );
    }

    final initial = (_displayNameCtrl.text.isNotEmpty
            ? _displayNameCtrl.text.trim()[0]
            : (_initialName.isNotEmpty ? _initialName[0] : 'A'))
        .toUpperCase();

    return ListView(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                  ),
                  image: _avatarBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_avatarBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: _avatarBytes == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Material(
                  color: const Color(0xFF1F2937),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _profileSaving ? null : _showPhotoSheet,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: _profileSaving ? null : _showPhotoSheet,
            icon: const Icon(Icons.photo_library, color: Color(0xFF7F8CFF)),
            label: const Text(
              'Change Photo',
              style: TextStyle(color: Color(0xFF7F8CFF)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'DISPLAY NAME',
          style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _displayNameCtrl,
          style: const TextStyle(color: Colors.white),
          enabled: !_profileSaving,
          onChanged: (_) => setState(() {}),
          decoration: _input('Your name as it appears to others'),
        ),
        if (_profileError != null) ...[
          const SizedBox(height: 12),
          Text(
            _profileError!,
            style: const TextStyle(color: Color(0xFFFFB4B4)),
          ),
        ],
        const SizedBox(height: 28),
        GestureDetector(
          onTap: _profileSaving ? null : _saveProfile,
          child: Opacity(
            opacity: _profileSaving ? 0.6 : 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: _profileSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // 💳 BANK
  Widget _bankUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Add Card", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 10),
        TextField(
          controller: cardController,
          style: const TextStyle(color: Colors.white),
          decoration: _input("Card Number"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Card Added")),
            );
          },
          child: const Text("Save"),
        )
      ],
    );
  }

  // 🔐 SECURITY
  Widget _securityUI() {
    return Column(
      children: [
        TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: _input("New Password"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Password Updated")),
            );
          },
          child: const Text("Update Password"),
        )
      ],
    );
  }

  // 🎨 APPEARANCE
  Widget _appearanceUI() {
    return Column(
      children: [
        const Text("Dark Mode", style: TextStyle(color: Colors.white)),
        Slider(
          value: darkMode ? 1 : 0,
          onChanged: (val) {
            setState(() {
              darkMode = val > 0.5;
            });
          },
        ),
      ],
    );
  }

  // 🔒 PRIVACY
  Widget _privacyUI() {
    return Column(
      children: [
        SwitchListTile(
          value: allowVisibility,
          onChanged: (val) {
            setState(() => allowVisibility = val);
          },
          title: const Text(
            "Allow others to see debts",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ❓ SUPPORT
  Widget _supportUI() {
    return const Column(
      children: [
        ExpansionTile(
          title: Text(
            "How does auto-settle work?",
            style: TextStyle(color: Colors.white),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "We minimize transactions automatically.",
                style: TextStyle(color: Colors.white60),
              ),
            )
          ],
        ),
        ExpansionTile(
          title: Text(
            "Is my data secure?",
            style: TextStyle(color: Colors.white),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Yes, your data is protected.",
                style: TextStyle(color: Colors.white60),
              ),
            )
          ],
        ),
      ],
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1F2937),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
