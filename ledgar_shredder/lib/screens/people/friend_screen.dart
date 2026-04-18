import 'package:flutter/material.dart';

class FriendScreen extends StatelessWidget {
  final String name;
  final String net;
  final bool isNegative;

  const FriendScreen({
    super.key,
    required this.name,
    required this.net,
    required this.isNegative,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 10),

            // 🔙 BACK
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                  SizedBox(width: 6),
                  Text("Back",
                      style:
                          TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 👤 HEADER
            Row(
              children: [
                const CircleAvatar(radius: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Net: $net",
                      style: TextStyle(
                        color: isNegative
                            ? Colors.purpleAccent
                            : Colors.lightBlueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 🔥 GRAPH CARD (OCTAGON STYLE)
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white10,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          net,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isNegative
                                ? Colors.purpleAccent
                                : Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // fake radial spokes (gives octagon feel)
                  ...List.generate(8, (i) {
                    return Transform.rotate(
                      angle: i * 0.785, // 360/8
                      child: Center(
                        child: Container(
                          width: 2,
                          height: 100,
                          color: Colors.white10,
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 ACTION BUTTONS
            Row(
              children: [
                Expanded(child: _primary("Settle Up")),
                const SizedBox(width: 12),
                Expanded(child: _secondary("Remind")),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "ANALYTICS",
              style:
                  TextStyle(color: Colors.white54, letterSpacing: 1.5),
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
  _stat("Total Paid", "\$320"),
  _stat("You Paid", "\$150"),
  _stat("They Paid", "\$170"),
],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "HISTORY",
              style:
                  TextStyle(color: Colors.white54, letterSpacing: 1.5),
            ),

            const SizedBox(height: 12),

            _history("Dinner at Nobu", "-\$45", true),
            _history("Movie Night", "+\$20", false),
            _history("Uber Split", "-\$15", true),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // 🔹 BUTTONS
  Widget _primary(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _secondary(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child:
          Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  // 🔹 STATS
  static Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54)),
      ],
    );
  }

  // 🔹 HISTORY
  Widget _history(String title, String amount, bool negative) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          Text(
            amount,
            style: TextStyle(
              color: negative
                  ? Colors.purpleAccent
                  : Colors.lightBlueAccent,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}