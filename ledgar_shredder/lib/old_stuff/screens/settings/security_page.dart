import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';
import 'settings_detail_scaffold.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool biometric = true;
  bool twoFactor = false;

  void _openDetail(String title, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SecurityDetailSheet(
        title: title,
        description: description,
      ),
    );
  }

  void _openChangePassword() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Security',
      children: [
        SettingsTile(
          icon: Icons.fingerprint,
          title: 'Biometric Unlock',
          subtitle: 'Use Face ID / fingerprint when opening the app.',
          trailing: Switch(
            value: biometric,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                biometric = value;
              });
            },
          ),
          onTap: () => _openDetail(
            'Biometric Unlock',
            'Secure your app using Face ID or fingerprint authentication.',
          ),
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.verified_user_outlined,
          title: 'Two-Factor Authentication',
          subtitle: 'Add another layer of security to your account.',
          trailing: Switch(
            value: twoFactor,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                twoFactor = value;
              });
            },
          ),
          onTap: () => _openDetail(
            'Two-Factor Authentication',
            'Enable a secondary verification step when logging in.',
          ),
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Update your account password.',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _openChangePassword,
        ),
      ],
    );
  }
}

class _SecurityDetailSheet extends StatelessWidget {
  final String title;
  final String description;

  const _SecurityDetailSheet({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              description,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatelessWidget {
  const _ChangePasswordSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 16),

              const _PasswordField(label: 'Current Password'),
              const SizedBox(height: 12),
              const _PasswordField(label: 'New Password'),
              const SizedBox(height: 12),
              const _PasswordField(label: 'Confirm Password'),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;

  const _PasswordField({required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}