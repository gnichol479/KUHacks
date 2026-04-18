import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../main/main_screen.dart'; // adjust if needed

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _onContinue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // BACK
              GestureDetector(
                onTap: _goBack,
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                    SizedBox(width: 6),
                    Text("Back",
                        style:
                            TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // TITLE
              Text(
                "Create your account",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Start tracking shared expenses with friends and family.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 30),

              // CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    // EMAIL
                    _inputField(
                      label: "Email",
                      hint: "you@example.com",
                      controller: emailController,
                    ),

                    const SizedBox(height: 20),

                    // PASSWORD
                    _inputField(
                      label: "Password",
                      hint: "Choose a password",
                      controller: passwordController,
                      isPassword: true,
                    ),

                    const SizedBox(height: 30),

                    // BUTTON
                    GestureDetector(
                      onTap: _onContinue,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF5B6CFF),
                              Color(0xFF7F8CFF)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // LOGIN LINK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white60),
                  ),
                  GestureDetector(
                    onTap: _goToLogin,
                    child: const Text(
                      "Log in",
                      style: TextStyle(
                        color: Color(0xFF7F8CFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 INLINE INPUT FIELD
  Widget _inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1F2937),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}