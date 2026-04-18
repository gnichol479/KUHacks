import 'package:flutter/material.dart';

class AutoPayOverlay extends StatelessWidget {
  const AutoPayOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⚡ ICON CIRCLE
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                  ),
                ),
                child: const Icon(Icons.flash_on,
                    color: Colors.white, size: 40),
              ),

              const SizedBox(height: 20),

              const Text(
                "Auto-Paying",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Marcus Rivera",
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "\$0.00",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Payment processing...",
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}