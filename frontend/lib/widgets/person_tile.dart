import 'package:flutter/material.dart';

import 'avatar_with_score.dart';

class PersonTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String amount;
  final bool positive;
  final VoidCallback? onTap;
  final int? accountabilityScore;
  final String? avatarBase64;

  const PersonTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.positive,
    this.onTap,
    this.accountabilityScore,
    this.avatarBase64,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (name.trim().isNotEmpty ? name.trim()[0] : '?').toUpperCase();
    return ListTile(
      onTap: onTap,
      leading: AvatarWithScore(
        radius: 22,
        score: accountabilityScore,
        avatarBase64: avatarBase64,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          color: positive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
