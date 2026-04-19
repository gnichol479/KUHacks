import 'dart:math' as math;

import 'package:flutter/material.dart';

// 🔽 IMPORT YOUR SCREENS
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bobAnimation;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(
      begin: -6,
      end: 6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  // ✅ FIXED NAVIGATION
  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = MediaQuery.of(context).size;
    // Aim the ripple origin where the raven sits in the centered column —
    // ~32% from the top reads close to the badge on most phones without
    // needing a layout pass to measure it exactly.
    final rippleCenter = Offset(screen.width / 2, screen.height * 0.32);
    // Diagonal so the rings always escape the screen before recycling.
    final rippleMaxRadius = math.sqrt(
      screen.width * screen.width + screen.height * screen.height,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F1A), Color(0xFF05070D)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _rippleController,
                  builder: (_, __) => CustomPaint(
                    painter: _RipplePainter(
                      progress: _rippleController.value,
                      rings: 6,
                      minRadius: 72,
                      maxRadius: rippleMaxRadius,
                      strokeWidth: 2.0,
                      center: rippleCenter,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _bobAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bobAnimation.value),
                          child: child,
                        );
                      },
                      child: const _RavenBadge(),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "Ledger Shredder",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Track and manage shared expenses\nwithout the awkwardness.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    PrimaryButton(
                      text: "Create Account",
                      onPressed: _goToSignup,
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(text: "Log In", onPressed: _goToLogin),
                    const SizedBox(height: 40),
                    const Text(
                      "LEDGER SHREDDER",
                      style: TextStyle(
                        color: Colors.white24,
                        letterSpacing: 3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RavenBadge extends StatelessWidget {
  const _RavenBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Muted off-white tinted toward the navy backdrop so the disc reads
        // as a soft halo instead of a hard white spotlight.
        color: const Color(0xFF2A2F3D),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Image.asset('assets/raven.webp', fit: BoxFit.contain),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Sonar-style concentric rings rendered behind the raven badge. Each ring
/// is phase-offset by `i / rings` so that as one stroke fades out near
/// `maxRadius`, the next is just being born at `minRadius`. This produces
/// the alternating "white ring -> dark gap -> white ring" pulse the auth
/// entry screen wants without needing per-ring controllers.
class _RipplePainter extends CustomPainter {
  final double progress;
  final int rings;
  final double minRadius;
  final double maxRadius;
  final double strokeWidth;
  final Offset? center;

  _RipplePainter({
    required this.progress,
    required this.rings,
    required this.minRadius,
    required this.maxRadius,
    required this.strokeWidth,
    this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = center ?? Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < rings; i++) {
      final t = (progress + i / rings) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * t;
      // Quick fade-in at birth, fade-out toward the outer edge so the
      // recycling boundary never pops. Capped well below pure white so the
      // rings melt into the gradient instead of blowing out.
      final fade = (t < 0.1) ? t / 0.1 : (1 - t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withOpacity(0.18 * fade.clamp(0.0, 1.0));
      canvas.drawCircle(origin, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) =>
      old.progress != progress ||
      old.center != center ||
      old.maxRadius != maxRadius;
}
