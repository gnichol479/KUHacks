import 'package:flutter/material.dart';
import 'settings_detail_scaffold.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(
      title: 'Help and Support',
      children: [
        SettingsTile(
          icon: Icons.help_outline_rounded,
          title: 'FAQ',
          subtitle: 'Find quick answers to common questions.',
          trailing: Icon(Icons.chevron_right_rounded),
        ),
        Divider(),
        SettingsTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Contact Support',
          subtitle: 'Reach out if something is not working right.',
          trailing: Icon(Icons.chevron_right_rounded),
        ),
        Divider(),
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'App Version',
          subtitle: 'Ledgar Shredder v0.1 MVP',
        ),
      ],
    );
  }
}