import 'package:flutter/material.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {

  bool biometricLogin = true;
  bool twoFactor = false;
  bool autoLock = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 16),

              // HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Security",
                    style: TextStyle(
                      color: Color(0xFFEDEFF3),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ===== AUTH =====
              const Text(
                "AUTHENTICATION",
                style: TextStyle(
                  color: Color(0xFF9AA0A6),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              _actionTile(
                icon: Icons.lock_outline,
                title: "Change Password",
                subtitle: "Update your password",
                onTap: () {
                  _showChangePassword(context);
                },
              ),

              _toggleTile(
                icon: Icons.fingerprint,
                title: "Biometric Login",
                subtitle: "Face ID / Touch ID",
                value: biometricLogin,
                onChanged: (v) => setState(() => biometricLogin = v),
              ),

              _toggleTile(
                icon: Icons.verified_user_outlined,
                title: "Two-Factor Authentication",
                subtitle: "Extra security layer",
                value: twoFactor,
                onChanged: (v) => setState(() => twoFactor = v),
              ),

              const SizedBox(height: 24),

              // ===== APP SECURITY =====
              const Text(
                "APP SECURITY",
                style: TextStyle(
                  color: Color(0xFF9AA0A6),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              _toggleTile(
                icon: Icons.lock_clock_outlined,
                title: "Auto-Lock",
                subtitle: "Lock after 5 minutes",
                value: autoLock,
                onChanged: (v) => setState(() => autoLock = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ACTION TILE =================
  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2F3A)),
        ),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 16),
            Expanded(child: _textBlock(title, subtitle)),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ================= TOGGLE TILE =================
  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3A)),
      ),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 16),
          Expanded(child: _textBlock(title, subtitle)),
          Switch(
            value: value,
            activeColor: const Color(0xFF4F6EF7),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================
  Widget _iconBox(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F3A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }

  Widget _textBlock(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFEDEFF3),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF9AA0A6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ================= CHANGE PASSWORD MODAL =================
  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D24),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Change Password",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _input("Current Password"),
              const SizedBox(height: 12),
              _input("New Password"),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F6EF7),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Update Password"),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _input(String hint) {
    return TextField(
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
        filled: true,
        fillColor: const Color(0xFF12141A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}