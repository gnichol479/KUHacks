import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

import 'signup_screen.dart';
import 'login_screen.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  const Spacer(),

                  // 🔵 Logo / Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.currency_exchange_rounded,
                      size: 30,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 🧠 Title
                  const Text(
                    'Settle up, simply.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ✍️ Subtitle
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      'Track and manage shared expenses\nwithout the awkwardness.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 🟦 Primary Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.cardRadius,
                        ),
                      ),
                      child: const Text(
                        'Create Account',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ⚪ Secondary Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: AppColors.card,
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.cardRadius,
                        ),
                      ),
                      child: const Text(
                        'Log In',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}