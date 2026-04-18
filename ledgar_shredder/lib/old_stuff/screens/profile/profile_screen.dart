import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';

import '../home/home_screen.dart';
import '../balances/balances_screen.dart';
import '../scanner/scan_screen.dart';
import '../settings/settings_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool autoSettleEnabled = true;

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.card;
    final primaryBlue = AppColors.primary;
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;
    final borderColor = AppColors.border;
    final owedGreen = AppColors.positive;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // HEADER
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(36),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'A',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alex Morgan',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@alexmorgan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const SettingsSheet(),
                            );
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: borderColor),
                            ),
                            child: Icon(
                              Icons.settings_outlined,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // AUTO SETTLE
                    Text(
                      'AUTO-SETTLE BALANCE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$40.00',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "We'll automatically pay your debts when possible.",
                            style: TextStyle(color: textSecondary),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: borderColor),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Auto-Settle Enabled',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Switch(
                                value: autoSettleEnabled,
                                activeTrackColor: primaryBlue,
                                onChanged: (value) {
                                  setState(() {
                                    autoSettleEnabled = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SCORE
                    Text(
                      'ACCOUNTABILITY SCORE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '87',
                            style: TextStyle(
                              fontSize: 58,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '+5 this month',
                            style: TextStyle(
                              color: owedGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // BADGES
                    Text(
                      'BADGES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _BadgeCard(icon: Icons.verified, label: 'Reliable'),
                        const SizedBox(width: 12),
                        _BadgeCard(icon: Icons.favorite, label: 'Generous'),
                        const SizedBox(width: 12),
                        _BadgeCard(icon: Icons.flash_on, label: 'Active'),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // TOKENS
                    Text(
                      'TOKENS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: const [
                          _TokenRow(
                            title: 'Forgiveness Token',
                            subtitle: 'Given to Marcus Rivera',
                            count: '2',
                          ),
                          Divider(),
                          _TokenRow(
                            title: 'Trust Token',
                            subtitle: 'Earned from on-time payments',
                            count: '5',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // NAV
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Icons.home_rounded, label: 'Home', selected: false, onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                  }),
                  _NavItem(icon: Icons.people_alt_outlined, label: 'People', selected: false, onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BalancesScreen()));
                  }),
                  _NavItem(icon: Icons.receipt_long_outlined, label: 'Scan', selected: false, onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                  }),
                  _NavItem(icon: Icons.person_outline_rounded, label: 'Profile', selected: true, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BadgeCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String count;

  const _TokenRow({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle),
            ],
          ),
        ),
        Text(count, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
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
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w500,
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