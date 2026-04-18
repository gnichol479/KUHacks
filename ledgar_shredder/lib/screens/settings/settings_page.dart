import 'package:flutter/material.dart';
import 'privacy.dart';
import 'security.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 16),

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Settings",
                    style: TextStyle(
                      color: Color(0xFFEDEFF3),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  )
                ],
              ),

              const SizedBox(height: 20),

              // ================= ACCOUNT =================
              _sectionTitle("ACCOUNT"),

              _card([
                _tile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Bank & Wallet",
                  subtitle: "Connect payment methods",
                  onTap: () {
                    // TODO: open bank page
                  },
                ),
                _divider(),
                _tile(
                  icon: Icons.security,
                  title: "Security",
                  subtitle: "Password, biometrics",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecurityPage(),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // ================= PREFERENCES =================
              _sectionTitle("PREFERENCES"),

              _card([
                _tile(
                  icon: Icons.palette_outlined,
                  title: "Appearance",
                  subtitle: "Dark mode",
                  onTap: () {},
                ),
                _divider(),
                _tile(
                  icon: Icons.notifications_none,
                  title: "Notifications",
                  subtitle: "On",
                  onTap: () {},
                ),
                _divider(),
                _tile(
                  icon: Icons.lock_outline,
                  title: "Privacy",
                  subtitle: "Control who sees your activity",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPage(),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // ================= SUPPORT =================
              _sectionTitle("SUPPORT"),

              _card([
                _tile(
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  subtitle: "FAQ, contact us",
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 20),

              // ================= LOG OUT =================
              _card([
                _tile(
                  icon: Icons.logout,
                  title: "Log Out",
                  subtitle: "",
                  isDanger: true,
                  onTap: () {
                    // TODO: logout logic
                  },
                ),
              ]),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9AA0A6),
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2F3A)),
      ),
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger
              ? const Color(0x26D96B6B)
              : const Color(0xFF2A2F3A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDanger ? const Color(0xFFD96B6B) : Colors.white,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? const Color(0xFFD96B6B) : const Color(0xFFEDEFF3),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF9AA0A6)),
            ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      color: Color(0xFF222633),
    );
  }
}