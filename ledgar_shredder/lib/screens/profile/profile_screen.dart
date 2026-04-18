import 'package:flutter/material.dart';
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
    const background = Color(0xFFF7F7F8);
    const cardColor = Colors.white;
    const primaryBlue = Color(0xFF4F6EF7);
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF7A7A7A);
    const borderColor = Color(0xFFE9E9EE);
    const owedGreen = Color(0xFF2E9B6F);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alex Morgan',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.6,
                                    color: textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '@alexmorgan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
                            child: const Icon(
                              Icons.settings_outlined,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'AUTO-SETTLE BALANCE',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '\$40.00',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.0,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "We'll automatically pay your debts when possible.",
                            style: TextStyle(
                              fontSize: 16,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: borderColor, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Auto-Settle Enabled',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Switch(
                                value: autoSettleEnabled,
                                activeColor: Colors.white,
                                activeTrackColor: primaryBlue,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: const Color(0xFFD9DCE3),
                                onChanged: (value) {
                                  setState(() {
                                    autoSettleEnabled = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'Add Funds',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'ACCOUNTABILITY SCORE',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                '87',
                                style: TextStyle(
                                  fontSize: 58,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.2,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  '+5 this month',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: owedGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              Expanded(child: _MonthBar(label: 'Nov')),
                              SizedBox(width: 10),
                              Expanded(child: _MonthBar(label: 'Dec')),
                              SizedBox(width: 10),
                              Expanded(child: _MonthBar(label: 'Jan')),
                              SizedBox(width: 10),
                              Expanded(child: _MonthBar(label: 'Feb')),
                              SizedBox(width: 10),
                              Expanded(child: _MonthBar(label: 'Mar')),
                              SizedBox(width: 10),
                              Expanded(
                                child: _MonthBar(
                                  label: 'Apr',
                                  active: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'BADGES',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: _BadgeCard(
                            icon: Icons.verified_user_outlined,
                            label: 'Reliable',
                            active: true,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _BadgeCard(
                            icon: Icons.favorite_border_rounded,
                            label: 'Generous',
                            active: true,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _BadgeCard(
                            icon: Icons.flash_on_outlined,
                            label: 'Active',
                            active: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: _BadgeCard(
                            icon: Icons.schedule_outlined,
                            label: 'On Time',
                            active: false,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _BadgeCard(
                            icon: Icons.balance_outlined,
                            label: 'Fair Split',
                            active: false,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'TOKENS',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: const Column(
                        children: [
                          _TokenRow(
                            title: 'Forgiveness Token',
                            subtitle: 'Given to Marcus Rivera',
                            count: '2',
                          ),
                          Divider(height: 24, color: borderColor),
                          _TokenRow(
                            title: 'Trust Token',
                            subtitle: 'Earned from on-time payments',
                            count: '5',
                          ),
                          Divider(height: 24, color: borderColor),
                          _TokenRow(
                            title: 'Split Token',
                            subtitle: 'Used in group settlements',
                            count: '3',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: background,
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: false,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                  ),
                  _NavItem(
                    icon: Icons.people_alt_outlined,
                    label: 'People',
                    selected: false,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const BalancesScreen()),
                      );
                    },
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Scan',
                    selected: false,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                    },
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    selected: true,
                    onTap: () {},
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

class _MonthBar extends StatelessWidget {
  final String label;
  final bool active;

  const _MonthBar({
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4F6EF7);
    const textSecondary = Color(0xFF7A7A7A);

    return Column(
      children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: active ? primaryBlue : const Color(0xFFE8EBEF),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BadgeCard({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const borderColor = Color(0xFFE9E9EE);
    const textSecondary = Color(0xFF7A7A7A);
    const primaryBlue = Color(0xFF4F6EF7);

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: active ? primaryBlue : const Color(0xFFC7CCD5),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: active ? textSecondary : const Color(0xFFC7CCD5),
            ),
          ),
        ],
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
    const primaryBlue = Color(0xFF4F6EF7);
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF7A7A7A);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.stars_rounded,
            color: primaryBlue,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryBlue,
          ),
        ),
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
    const primaryBlue = Color(0xFF4F6EF7);
    const textSecondary = Color(0xFF9A9AA0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: selected ? primaryBlue : textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? primaryBlue : textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}