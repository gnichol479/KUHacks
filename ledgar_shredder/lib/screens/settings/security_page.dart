import 'package:flutter/material.dart';
import 'settings_detail_scaffold.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool biometric = true;
  bool twoFactor = false;

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
            onChanged: (value) {
              setState(() {
                biometric = value;
              });
            },
          ),
        ),
        const Divider(),
        SettingsTile(
          icon: Icons.verified_user_outlined,
          title: 'Two-Factor Authentication',
          subtitle: 'Add another layer of security to your account.',
          trailing: Switch(
            value: twoFactor,
            onChanged: (value) {
              setState(() {
                twoFactor = value;
              });
            },
          ),
        ),
        const Divider(),
        const SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Update your account password.',
          trailing: Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}