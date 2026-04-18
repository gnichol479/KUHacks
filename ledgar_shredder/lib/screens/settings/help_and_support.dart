import 'package:flutter/material.dart';

class HelpAndSupportPage extends StatelessWidget {
  const HelpAndSupportPage({super.key});

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
                    "Help & Support",
                    style: TextStyle(
                      color: Color(0xFFEDEFF3),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // OPTIONS
              _tile(
                icon: Icons.help_outline,
                title: "FAQ",
                subtitle: "Common questions",
                onTap: () {
                  _showFAQ(context);
                },
              ),

              _tile(
                icon: Icons.chat_bubble_outline,
                title: "Live Chat",
                subtitle: "Talk to support",
                onTap: () {
                  _showChat(context);
                },
              ),

              _tile(
                icon: Icons.email_outlined,
                title: "Email Support",
                subtitle: "support@ledgar.app",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Email app coming soon")),
                  );
                },
              ),

              _tile(
                icon: Icons.description_outlined,
                title: "Terms of Service",
                subtitle: "Legal information",
                onTap: () {
                  _showSimplePage(context, "Terms of Service");
                },
              ),

              _tile(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy Policy",
                subtitle: "How we handle data",
                onTap: () {
                  _showSimplePage(context, "Privacy Policy");
                },
              ),

              const Spacer(),

              // VERSION
              const Center(
                child: Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    color: Color(0xFF9AA0A6),
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TILE =================
  Widget _tile({
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F3A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
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
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ================= FAQ =================
  void _showFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "FAQ",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 12),
              Text(
                "• How does auto pay work?\n• How do I add funds?\n• How do groups work?",
                style: TextStyle(color: Color(0xFF9AA0A6)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= CHAT =================
  void _showChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Live Chat",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  hintStyle: TextStyle(color: Color(0xFF9AA0A6)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Send"),
              )
            ],
          ),
        );
      },
    );
  }

  // ================= SIMPLE PAGE =================
  void _showSimplePage(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "$title content coming soon...",
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}