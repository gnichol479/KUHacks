import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';
import 'settings_detail_scaffold.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool hideGroupTotals = false;
  bool privateScore = true;

  void _openDetail(String title, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrivacyDetailSheet(
        title: title,
        description: description,
      ),
    );
  }

  void _openBlockedUsers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BlockedUsersSheet(),
    );
  }

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
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                hideGroupTotals = value;
              });
            },
          ),
          onTap: () => _openDetail(
            'Hide Group Totals',
            'This hides detailed balances inside groups for added privacy.',
          ),
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.shield_outlined,
          title: 'Private Accountability Score',
          subtitle: 'Only you can see your full score details.',
          trailing: Switch(
            value: privateScore,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                privateScore = value;
              });
            },
          ),
          onTap: () => _openDetail(
            'Private Score',
            'Your accountability score will only be visible to you.',
          ),
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.person_off_outlined,
          title: 'Blocked Users',
          subtitle: 'Manage the people you have blocked.',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _openBlockedUsers,
        ),
      ],
    );
  }
}

class _PrivacyDetailSheet extends StatelessWidget {
  final String title;
  final String description;

  const _PrivacyDetailSheet({
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

class _BlockedUsersSheet extends StatelessWidget {
  const _BlockedUsersSheet();

  @override
  Widget build(BuildContext context) {
    final blocked = ['Marcus Rivera', 'Erik Zhang'];

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

            const Text(
              'Blocked Users',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            ...blocked.map((user) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(user)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Unblock'),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}