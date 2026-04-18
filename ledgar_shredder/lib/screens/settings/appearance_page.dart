import 'package:flutter/material.dart';
import 'settings_detail_scaffold.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  bool compactMode = false;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Appearance',
      children: [
        const SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Theme',
          subtitle: 'Light mode currently active.',
          trailing: Icon(Icons.chevron_right_rounded),
        ),
        const Divider(),
        SettingsTile(
          icon: Icons.view_agenda_outlined,
          title: 'Compact Mode',
          subtitle: 'Reduce spacing and fit more balances on screen.',
          trailing: Switch(
            value: compactMode,
            onChanged: (value) {
              setState(() {
                compactMode = value;
              });
            },
          ),
        ),
        const Divider(),
        const SettingsTile(
          icon: Icons.text_fields_rounded,
          title: 'Text Size',
          subtitle: 'Standard',
          trailing: Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}