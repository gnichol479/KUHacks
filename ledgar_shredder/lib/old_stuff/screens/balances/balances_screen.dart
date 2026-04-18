// balances_screen.dart (UPDATED)

import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';
import '../../../screens/theme/app_text_styles.dart';
import '../../../screens/theme/app_spacing.dart';

import '../home/home_screen.dart';
import '../scanner/scan_screen.dart';
import '../profile/profile_screen.dart';
import '../ledger/ledger_detail_screen.dart';

class BalancesScreen extends StatefulWidget {
  const BalancesScreen({super.key});

  @override
  State<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends State<BalancesScreen> {
  bool showPeople = true;

  final people = const [
    {
      'name': 'Sarah Chen',
      'subtitle': 'You owe \$45',
      'amount': '-\$45',
      'positive': false,
    },
    {
      'name': 'Marcus Rivera',
      'subtitle': 'They owe you \$120',
      'amount': '+\$120',
      'positive': true,
    },
    {
      'name': 'Erik Zhang',
      'subtitle': 'You owe \$22',
      'amount': '-\$22',
      'positive': false,
    },
  ];

  final groups = const [
    {
      'name': 'Lake Trip',
      'subtitle': '4 members • You are owed \$58',
      'amount': '+\$58',
      'positive': true,
    },
    {
      'name': 'Roommates',
      'subtitle': '3 members • You owe \$37',
      'amount': '-\$37',
      'positive': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeList = showPeople ? people : groups;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔝 Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            showPeople ? 'People' : 'Groups',
                            style: AppTextStyles.titleLarge,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.cardRadius,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 🔄 Tabs
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TopTab(
                              label: 'People',
                              selected: showPeople,
                              onTap: () => setState(() => showPeople = true),
                            ),
                          ),
                          Expanded(
                            child: _TopTab(
                              label: 'Groups',
                              selected: !showPeople,
                              onTap: () => setState(() => showPeople = false),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // 🔍 Search
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppSpacing.cardRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppColors.textSecondary),
                          SizedBox(width: 10),
                          Text(
                            'Search...',
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 📋 List
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppSpacing.cardRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < activeList.length; i++) ...[
                            _BalanceListRow(
                              name: activeList[i]['name'] as String,
                              subtitle: activeList[i]['subtitle'] as String,
                              amount: activeList[i]['amount'] as String,
                              positive: activeList[i]['positive'] as bool,
                              isGroup: !showPeople,
                            ),
                            if (i != activeList.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔻 Bottom Nav
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home,
                    label: 'Home',
                    selected: false,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomeScreen()),
                    ),
                  ),
                  _NavItem(
                    icon: Icons.people,
                    label: 'Ledgars',
                    selected: true,
                    onTap: () {},
                  ),
                  _NavItem(
                    icon: Icons.receipt,
                    label: 'Scan',
                    selected: false,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScanScreen()),
                    ),
                  ),
                  _NavItem(
                    icon: Icons.person,
                    label: 'Profile',
                    selected: false,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BalanceListRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String amount;
  final bool positive;
  final bool isGroup;

  const _BalanceListRow({
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.positive,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LedgerDetailScreen(
              name: name,
              subtitle: subtitle,
              amount: amount,
              positive: positive,
              isGroup: isGroup,
            ),
          ),
        );
      },
      leading: CircleAvatar(
        backgroundColor: isGroup
            ? AppColors.primary.withOpacity(0.1)
            : const Color(0xFFF1F2F6),
        child: Icon(
          isGroup ? Icons.groups : Icons.person,
          color: isGroup
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
      title: Text(name, style: AppTextStyles.titleMedium),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: positive
              ? AppColors.positive
              : AppColors.negative,
        ),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: positive
              ? AppColors.positive
              : AppColors.negative,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}