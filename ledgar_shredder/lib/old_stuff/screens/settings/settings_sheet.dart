import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';

import 'appearance_page.dart';
import 'bank_wallet_page.dart';
import 'help_support_page.dart';
import 'notifications_page.dart';
import 'privacy_page.dart';
import 'security_page.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary;
    final borderColor = AppColors.border;
    final primaryBlue = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _SettingsSheetItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Bank and Wallet',
                onTap: () => _openPage(context, const BankWalletPage()),
              ),
              _SettingsSheetItem(
                icon: Icons.lock_outline_rounded,
                title: 'Security',
                onTap: () => _openPage(context, const SecurityPage()),
              ),
              _SettingsSheetItem(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                onTap: () => _openPage(context, const AppearancePage()),
              ),
              _SettingsSheetItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () => _openPage(context, const NotificationsPage()),
              ),
              _SettingsSheetItem(
                icon: Icons.shield_outlined,
                title: 'Privacy',
                onTap: () => _openPage(context, const PrivacyPage()),
              ),
              _SettingsSheetItem(
                icon: Icons.help_outline_rounded,
                title: 'Help and Support',
                onTap: () => _openPage(context, const HelpSupportPage()),
              ),

              const SizedBox(height: 6),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  static void _openPage(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

class _SettingsSheetItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsSheetItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryBlue = AppColors.primary;
    final textPrimary = AppColors.textPrimary;
    final borderColor = AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: primaryBlue, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}