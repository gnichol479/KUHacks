import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // TOGGLE STATES
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool paymentReminders = true;
  bool newIOUs = true;
  bool groupActivity = false;

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
                    "Notifications",
                    style: TextStyle(
                      color: Color(0xFFEDEFF3),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ===== GENERAL =====
              const Text(
                "GENERAL",
                style: TextStyle(
                  color: Color(0xFF9AA0A6),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              _toggleTile(
                title: "Push Notifications",
                subtitle: "Receive alerts on your device",
                value: pushNotifications,
                onChanged: (v) => setState(() => pushNotifications = v),
              ),

              _toggleTile(
                title: "Email Notifications",
                subtitle: "Receive updates via email",
                value: emailNotifications,
                onChanged: (v) => setState(() => emailNotifications = v),
              ),

              const SizedBox(height: 24),

              // ===== ACTIVITY TYPES =====
              const Text(
                "ACTIVITY TYPES",
                style: TextStyle(
                  color: Color(0xFF9AA0A6),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              _toggleTile(
                title: "Payment Reminders",
                subtitle: "When payments are due",
                value: paymentReminders,
                onChanged: (v) => setState(() => paymentReminders = v),
              ),

              _toggleTile(
                title: "New IOUs",
                subtitle: "When someone adds an IOU",
                value: newIOUs,
                onChanged: (v) => setState(() => newIOUs = v),
              ),

              _toggleTile(
                title: "Group Activity",
                subtitle: "Updates from your groups",
                value: groupActivity,
                onChanged: (v) => setState(() => groupActivity = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TILE =================
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
            child: const Icon(Icons.notifications, size: 16, color: Colors.white),
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