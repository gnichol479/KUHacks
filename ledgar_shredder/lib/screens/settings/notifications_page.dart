import 'package:flutter/material.dart';
import 'settings_detail_scaffold.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool reminders = true;
  bool payments = true;
  bool groups = false;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Notifications',
      children: [
        SettingsTile(
          icon: Icons.notifications_active_outlined,
          title: 'Payment Reminders',
          subtitle: 'Get reminded when balances are still open.',
          trailing: Switch(
            value: reminders,
            onChanged: (value) {
              setState(() {
                reminders = value;
              });
            },
          ),
        ),
        const Divider(),
        SettingsTile(
          icon: Icons.payments_outlined,
          title: 'Payment Activity',
          subtitle: 'Be notified when someone pays or requests payment.',
          trailing: Switch(
            value: payments,
            onChanged: (value) {
              setState(() {
                payments = value;
              });
            },
          ),
        ),
        const Divider(),
        SettingsTile(
          icon: Icons.groups_outlined,
          title: 'Group Updates',
          subtitle: 'Receive alerts for changes in group balances.',
          trailing: Switch(
            value: groups,
            onChanged: (value) {
              setState(() {
                groups = value;
              });
            },
          ),
        ),
      ],
    );
  }
}