import 'package:flutter/material.dart';
import 'settings_detail_scaffold.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool hideGroupTotals = false;
  bool privateScore = true;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Privacy',
      children: [
        SettingsTile(
          icon: Icons.visibility_off_outlined,
          title: 'Hide Group Totals',
          subtitle: 'Keep the amount you owe in groups less visible.',
          trailing: Switch(
            value: hideGroupTotals,
            onChanged: (value) {
              setState(() {
                hideGroupTotals = value;
              });
            },
          ),
        ),
        const Divider(),
        SettingsTile(
          icon: Icons.shield_outlined,
          title: 'Private Accountability Score',
          subtitle: 'Only you can see your full score details.',
          trailing: Switch(
            value: privateScore,
            onChanged: (value) {
              setState(() {
                privateScore = value;
              });
            },
          ),
        ),
        const Divider(),
        const SettingsTile(
          icon: Icons.person_off_outlined,
          title: 'Blocked Users',
          subtitle: 'Manage the people you have blocked.',
          trailing: Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}