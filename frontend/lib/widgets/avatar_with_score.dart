import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Best-effort base64 decode for user avatars served by the backend.
/// Returns `null` for malformed strings so callers can transparently fall
/// back to initials without crashing the entire list row.
Uint8List? decodeAvatarBase64(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.trim();
  if (cleaned.isEmpty) return null;
  try {
    return base64Decode(cleaned);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('decodeAvatarBase64 failed: $e');
    }
    return null;
  }
}

/// User avatar plus a tilted accountability-score ribbon pinned to the
/// top-right. The ribbon hides itself when [score] is null so legacy call
/// sites that don't have a score yet keep rendering a plain CircleAvatar.
///
/// The ribbon color tiers (`>=80` green, `>=60` amber, otherwise red) match
/// the plan and read as "trust" / "caution" / "watch out" at a glance.
class AvatarWithScore extends StatelessWidget {
  final double radius;
  final int? score;
  final Widget? child;
  final ImageProvider? backgroundImage;
  final Color? backgroundColor;

  /// Convenience: decode a backend-supplied base64 avatar into a
  /// `MemoryImage`. Wins over [backgroundImage] when both are non-null so
  /// list-row callers can just pass the API field through unchanged.
  final String? avatarBase64;

  const AvatarWithScore({
    super.key,
    this.radius = 18,
    required this.score,
    this.child,
    this.backgroundImage,
    this.backgroundColor,
    this.avatarBase64,
  });

  Color _ribbonColor(int s) {
    if (s >= 80) return const Color(0xFF22C55E);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final decoded = decodeAvatarBase64(avatarBase64);
    final ImageProvider? bgImage =
        decoded != null ? MemoryImage(decoded) : backgroundImage;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF1F2937),
      backgroundImage: bgImage,
      child: bgImage == null ? child : null,
    );
    final s = score;
    if (s == null) {
      return avatar;
    }

    // Scale the ribbon a touch with the avatar so it stays legible on
    // bigger profile headers (FriendScreen) without dominating the small
    // list rows.
    final ribbonHeight = math.max(13.0, radius * 0.45);
    final ribbonWidth = math.max(34.0, radius * 1.7);
    final fontSize = math.max(8.5, radius * 0.36);
    final color = _ribbonColor(s);

    // Box wraps the avatar with a small overflow allowance so the rotated
    // ribbon doesn't get clipped by parent ListTile padding.
    return SizedBox(
      width: radius * 2 + 8,
      height: radius * 2 + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: avatar,
          ),
          Positioned(
            top: -2,
            right: -4,
            child: Transform.rotate(
              angle: math.pi / 4,
              alignment: Alignment.center,
              child: Container(
                width: ribbonWidth,
                height: ribbonHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(ribbonHeight / 2),
                  border: Border.all(
                    color: const Color(0xFF111827),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '$s',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
