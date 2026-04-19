import 'package:flutter/material.dart';

// 🔑 SAME KEYS (must match settings_sheet.dart)
class SettingsKeys {
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

  bool darkMode = true;
  bool allowVisibility = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F1A),
        title: Text(widget.type),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.type) {
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