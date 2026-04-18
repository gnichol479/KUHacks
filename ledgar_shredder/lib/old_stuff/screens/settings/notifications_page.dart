import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';
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

  void _openDetail(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationDetailSheet(title: title),
    );
  }

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
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                reminders = value;
              });
            },
          ),
          onTap: () => _openDetail('Payment Reminders'),
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.payments_outlined,
          title: 'Payment Activity',
          subtitle: 'Be notified when someone pays or requests payment.',
          trailing: Switch(
            value: payments,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                payments = value;
              });
            },
          ),
          onTap: () => _openDetail('Payment Activity'),
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.groups_outlined,
          title: 'Group Updates',
          subtitle: 'Receive alerts for changes in group balances.',
          trailing: Switch(
            value: groups,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                groups = value;
              });
            },
          ),
          onTap: () => _openDetail('Group Updates'),
        ),
      ],
    );
  }
}

class _NotificationDetailSheet extends StatefulWidget {
  final String title;

  const _NotificationDetailSheet({required this.title});

  @override
  State<_NotificationDetailSheet> createState() =>
      _NotificationDetailSheetState();
}

class _NotificationDetailSheetState
    extends State<_NotificationDetailSheet> {
  bool push = true;
  bool email = false;
  String frequency = 'Instant';

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
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            _ToggleRow(
              label: 'Push Notifications',
              value: push,
              onChanged: (v) => setState(() => push = v),
            ),

            const SizedBox(height: 12),

            _ToggleRow(
              label: 'Email Notifications',
              value: email,
              onChanged: (v) => setState(() => email = v),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Text('Frequency'),
                  const Spacer(),
                  Text(frequency),
                ],
              ),
            ),

            const SizedBox(height: 16),

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
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Switch(
          value: value,
          activeTrackColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}