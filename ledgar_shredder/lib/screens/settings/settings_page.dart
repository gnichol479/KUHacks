import 'package:flutter/material.dart';
import '../auth/auth_entry_screen.dart';
import 'settings_detail_page.dart';

// 🔑 Keys (prevents "Coming soon" bugs)
class SettingsKeys {
  static const bank = 'bank';
  static const security = 'security';
  static const appearance = 'appearance';
  static const privacy = 'privacy';
  static const support = 'support';
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool notificationsOn = true;
  bool darkMode = true;

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _openPage(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsDetailPage(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white54),
                )
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 ACCOUNT
            _section("ACCOUNT"),

            _tile(
              Icons.account_balance,
              "Bank & Wallet",
              "Connect payment methods",
              () => _openPage(SettingsKeys.bank),
            ),

            _tile(
              Icons.lock,
              "Security",
              "Password, biometrics",
              () => _openPage(SettingsKeys.security),
            ),

            const SizedBox(height: 20),

            // 🔹 PREFERENCES
            _section("PREFERENCES"),

            _tile(
              Icons.dark_mode,
              "Appearance",
              "Light / Dark mode",
              () => _openPage(SettingsKeys.appearance),
            ),

            _toggleTile(
              Icons.notifications,
              "Notifications",
              notificationsOn,
              (val) => setState(() => notificationsOn = val),
            ),

            _tile(
              Icons.visibility,
              "Privacy",
              "Control who sees your activity",
              () => _openPage(SettingsKeys.privacy),
            ),

            const SizedBox(height: 20),

            // 🔹 SUPPORT
            _section("SUPPORT"),

            _tile(
              Icons.help_outline,
              "Help & Support",
              "FAQ, contact us",
              () => _openPage(SettingsKeys.support),
            ),

            const SizedBox(height: 30),

            // 🔥 LOGOUT
            GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Log Out",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // 🔹 SECTION LABEL
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // 🔹 NORMAL TILE
  Widget _tile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle:
          Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
    );
  }

  // 🔹 TOGGLE TILE
  Widget _toggleTile(
      IconData icon, String title, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
      title:
          Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF7F8CFF),
      ),
    );
  }
}