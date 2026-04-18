import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';
import '../../../screens/theme/app_text_styles.dart';
import '../../../screens/theme/app_spacing.dart';

import 'login_screen.dart';
import '../home/home_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔙 Back
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    label: const Text(
                      'Back',
                      style: AppTextStyles.body,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 🧠 Title
                  const Text(
                    'Create your account',
                    style: AppTextStyles.titleLarge,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  const Text(
                    'Start tracking shared expenses with friends and family.',
                    style: AppTextStyles.bodySecondary,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 🧾 Form Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 📧 Email
                        const Text(
                          'Email',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        TextField(
                          decoration: InputDecoration(
                            hintText: 'my@emailaddress.com',
                            hintStyle: const TextStyle(
                              color: Color(0xFFB0B4BD),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFDFDFE),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // 🔒 Password
                        const Text(
                          'Password',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Create a password...',
                            hintStyle: const TextStyle(
                              color: Color(0xFFB0B4BD),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFDFDFE),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // 🟦 Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
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
                              'Continue',
                              style: AppTextStyles.button,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 🔗 Footer
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: AppTextStyles.bodySecondary,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}