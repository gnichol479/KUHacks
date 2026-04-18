import 'package:flutter/material.dart';
import 'auto_pay.dart';
import 'add_funds.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isAutoPayEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 10),

            // 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "A",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Alex Morgan",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "@alexmorgan",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.settings, color: Colors.white70),
                )
              ],
            ),

            const SizedBox(height: 30),

            // 🔹 AUTO SETTLE
            const Text(
              "AUTO-SETTLE BALANCE",
              style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "\$40.00",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "We'll automatically pay your debts when possible.",
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),

                  // 🔥 FIXED SWITCH
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Auto-Settle Enabled",
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: isAutoPayEnabled,
                        onChanged: (value) {
                          setState(() {
                            isAutoPayEnabled = value;
                          });

                          if (value) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) =>
                                    const AutoPayOverlay(),
                              ),
                            );

                            Future.delayed(
                                const Duration(seconds: 2), () {
                              if (mounted) Navigator.pop(context);
                            });
                          }
                        },
                        activeColor: const Color(0xFF7F8CFF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.flash_on,
                            color: Colors.lightBlueAccent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Will auto-pay Marcus Rivera \$40.00",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
  onTap: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFundsSheet(),
    );
  },
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
    child: const Text(
      "+ Add Funds",
      style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold),
    ),
  ),
),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 ACCOUNTABILITY SCORE
            const Text(
              "ACCOUNTABILITY SCORE",
              style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        "87",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text("+5 this month",
                          style: TextStyle(
                              color: Colors.lightBlueAccent)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: index == 5
                                  ? const Color(0xFF7F8CFF)
                                  : const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ["Nov", "Dec", "Jan", "Feb", "Mar", "Apr"][index],
                            style:
                                const TextStyle(color: Colors.white54),
                          )
                        ],
                      );
                    }),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 TOKENS
            const Text(
              "TOKENS",
              style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _token("💰", "Balance", "120"),
                  _token("⚡", "Spent", "45"),
                  _token("🎁", "Earned", "75"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 BADGES
            const Text(
              "BADGES",
              style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _badge(Icons.verified, "Reliable")),
                const SizedBox(width: 12),
                Expanded(child: _badge(Icons.favorite, "Generous")),
                const SizedBox(width: 12),
                Expanded(child: _badge(Icons.flash_on, "Active")),
              ],
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // 🔹 TOKEN
  Widget _token(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  // 🔹 BADGE
  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.lightBlueAccent),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}