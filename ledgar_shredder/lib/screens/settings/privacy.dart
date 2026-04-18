import 'package:flutter/material.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool publicProfile = true;
  bool activityStatus = false;
  bool allowIOURequests = true;

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
                    "Privacy",
                    style: TextStyle(
                      color: Color(0xFFEDEFF3),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ===== VISIBILITY =====
              const Text(
                "VISIBILITY",
                style: TextStyle(
                  color: Color(0xFF9AA0A6),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              _toggleTile(
                title: "Public Profile",
                subtitle: "Let others find you",
                value: publicProfile,
                onChanged: (v) => setState(() => publicProfile = v),
              ),

              _toggleTile(
                title: "Activity Status",
                subtitle: "Show when you're active",
                value: activityStatus,
                onChanged: (v) => setState(() => activityStatus = v),
              ),

              const SizedBox(height: 24),

              // ===== PERMISSIONS =====
              const Text(
                "PERMISSIONS",
                style: TextStyle(
                  color: Color(0xFF9AA0A6),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              _toggleTile(
                title: "Allow IOU Requests",
                subtitle: "From friends and groups",
                value: allowIOURequests,
                onChanged: (v) => setState(() => allowIOURequests = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== REUSABLE TILE =====
  Widget _toggleTile({
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2F3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock, size: 16, color: Colors.white),
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

          Switch(
            value: value,
            activeColor: const Color(0xFF4F6EF7),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}