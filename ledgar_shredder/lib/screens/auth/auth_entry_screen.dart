import 'package:flutter/material.dart';
import 'dart:async';

// 🔽 IMPORT YOUR SCREENS
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bobAnimation;

  bool _isWinking = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startWinkLoop();
  }

  void _startWinkLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      setState(() => _isWinking = true);
      await Future.delayed(const Duration(milliseconds: 250));
      setState(() => _isWinking = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
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
                child: _RavenIcon(isWinking: _isWinking),
              ),

              const SizedBox(height: 40),

              Text(
                "Settle up, simply.",
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

              SecondaryButton(
                text: "Log In",
                onPressed: _goToLogin,
              ),

              const SizedBox(height: 40),

              const Text(
                "LEDGAR SHREDDER",
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
    );
  }
}

class _RavenIcon extends StatelessWidget {
  final bool isWinking;

  const _RavenIcon({required this.isWinking});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: RavenPainter(isWinking: isWinking),
      ),
    );
  }
}

class RavenPainter extends CustomPainter {
  final bool isWinking;

  RavenPainter({required this.isWinking});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white70;
    final center = Offset(size.width / 2, size.height / 2);

    final body = Path()
      ..moveTo(center.dx, center.dy - 20)
      ..lineTo(center.dx - 20, center.dy + 10)
      ..lineTo(center.dx + 20, center.dy + 10)
      ..close();

    canvas.drawPath(body, paint);

    canvas.drawCircle(center.translate(0, -30), 10, paint);

    final eyePaint = Paint()..color = Colors.black;
    if (!isWinking) {
      canvas.drawCircle(center.translate(2, -32), 2, eyePaint);
    } else {
      canvas.drawLine(
        center.translate(-1, -32),
        center.translate(5, -32),
        eyePaint..strokeWidth = 2,
      );
    }

    final beak = Path()
      ..moveTo(center.dx + 8, center.dy - 30)
      ..lineTo(center.dx + 18, center.dy - 27)
      ..lineTo(center.dx + 8, center.dy - 24)
      ..close();

    canvas.drawPath(beak, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
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