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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 10),

              // 🔙 Back
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

              // 👤 Profile Header
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Net: $net",
                        style: TextStyle(
                          color: isNegative
                              ? Colors.purpleAccent
                              : Colors.lightBlueAccent,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 💰 Balance Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    const Text(
                      "BALANCE BETWEEN YOU",
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "\$45.00",
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _primaryButton("Settle Up"),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _secondaryButton("Forgive"),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "HISTORY",
                style: TextStyle(
                  color: Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              _historyItem(
                title: "Dinner at Nobu",
                date: "Apr 12, 2026",
                amount: "-\$45",
                status: "Pending",
                negative: true,
              ),

              _historyItem(
                title: "Birthday gift",
                date: "Mar 15, 2026",
                amount: "+\$30",
                status: "Forgiven",
                negative: false,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 BUTTONS

  Widget _primaryButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _secondaryButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const Text(
        "Forgive",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  // 🔹 HISTORY ITEM

  Widget _historyItem({
    required String title,
    required String date,
    required String amount,
    required String status,
    required bool negative,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(date,
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: negative
                      ? Colors.purpleAccent
                      : Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          )
        ],
      ),
    );
  }
}