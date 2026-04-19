import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AutoPayProgress {
  final String friendName;
  final double amount;
  final String status;

  const AutoPayProgress({
    required this.friendName,
    required this.amount,
    required this.status,
  });
}

class AutoPayOverlay extends StatelessWidget {
  final ValueListenable<AutoPayProgress>? progress;
  final String? staticFriendName;
  final double? staticAmount;
  final String? staticStatus;

  const AutoPayOverlay({
    super.key,
    this.progress,
    this.staticFriendName,
    this.staticAmount,
    this.staticStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6),
      body: Center(
        child: progress == null
            ? _card(
                friendName: staticFriendName ?? '',
                amount: staticAmount ?? 0,
                status: staticStatus ?? 'Payment processing...',
              )
            : ValueListenableBuilder<AutoPayProgress>(
                valueListenable: progress!,
                builder: (_, p, __) => _card(
                  friendName: p.friendName,
                  amount: p.amount,
                  status: p.status,
                ),
              ),
      ),
    );
  }

  Widget _card({
    required String friendName,
    required double amount,
    required String status,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            'Auto-Paying',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            friendName.isEmpty ? '—' : friendName,
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            status,
            style: const TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
