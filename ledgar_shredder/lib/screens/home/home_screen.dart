import 'package:flutter/material.dart';
import '../balances/balances_screen.dart';
import '../scanner/scan_screen.dart';
import '../profile/profile_screen.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showAddIouSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _AddIouSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final balances = [
      {
        'name': 'Sarah Chen',
        'subtitle': 'You owe \$45',
        'amount': '-\$45',
        'positive': false,
        'group': false,
      },
      {
        'name': 'Marcus Rivera',
        'subtitle': 'They owe you \$120',
        'amount': '+\$120',
        'positive': true,
        'group': false,
      },
      {
        'name': 'Lake Trip Group',
        'subtitle': 'Group balance pending',
        'amount': '+\$58',
        'positive': true,
        'group': true,
      },
      {
        'name': 'Roommates',
        'subtitle': 'You owe \$37',
        'amount': '-\$37',
        'positive': false,
        'group': true,
      },
    ];

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: AppTextStyles.bodySecondary,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Your Ledger',
                                style: AppTextStyles.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppSpacing.cardRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NET BALANCE', style: AppTextStyles.label),
                          SizedBox(height: 14),
                          Text(
                            '+\$133.00',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              color: AppColors.positive,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _BalanceMiniStat(
                                  label: 'You Owe',
                                  amount: '\$82.00',
                                  color: AppColors.negative,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _BalanceMiniStat(
                                  label: 'Owed to You',
                                  amount: '\$215.00',
                                  color: AppColors.positive,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    const _InfoPill(
                      icon: Icons.account_balance_wallet_outlined,
                      text: '\$40 available for auto-settle',
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    const _InfoPill(
                      icon: Icons.route_outlined,
                      text: 'Optimized: Pay Sarah instead',
                    ),

                    const SizedBox(height: AppSpacing.md),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddIouSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add IOU',
                            style: AppTextStyles.button),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.cardRadius,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text('ACTIVE BALANCES',
                        style: AppTextStyles.label),

                    const SizedBox(height: AppSpacing.md),

                    ...balances.map(
                      (item) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _BalanceRow(
                          name: item['name'] as String,
                          subtitle: item['subtitle'] as String,
                          amount: item['amount'] as String,
                          positive: item['positive'] as bool,
                          isGroup: item['group'] as bool,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
      icon: Icons.home_rounded,
      label: 'Home',
      selected: true,
      onTap: () {},
    ),
    _NavItem(
      icon: Icons.people_alt_outlined,
      label: 'Balances',
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
      selected: false,
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
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

/* KEEP ALL YOUR ORIGINAL HELPER CLASSES BELOW THIS LINE UNCHANGED */

class _AddIouSheet extends StatefulWidget {
  const _AddIouSheet();

  @override
  State<_AddIouSheet> createState() => _AddIouSheetState();
}

class _AddIouSheetState extends State<_AddIouSheet> {
  final _whoController = TextEditingController(text: 'Sarah Chen');
  final _descriptionController = TextEditingController(text: 'e.g. Dinner, Uber');
  final _amountController = TextEditingController(text: '\$0.00');

  bool theyOweMe = true;

  @override
  void dispose() {
    _whoController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Colors.white;
    const primaryBlue = Color(0xFF4F6EF7);
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF7A7A7A);
    const borderColor = Color(0xFFE9E9EE);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 24,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DCE3),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'New IOU',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Who',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _whoController,
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ToggleOption(
                          label: 'I Owe Them',
                          selected: !theyOweMe,
                          onTap: () {
                            setState(() {
                              theyOweMe = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ToggleOption(
                          label: 'They Owe Me',
                          selected: theyOweMe,
                          onTap: () {
                            setState(() {
                              theyOweMe = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    const borderColor = Color(0xFFE9E9EE);

    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFDFDFE),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F6EF7), width: 1.4),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4F6EF7);
    const textPrimary = Color(0xFF171717);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primaryBlue : Colors.transparent,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? primaryBlue : textPrimary,
          ),
        ),
      ),
    );
  }
}

class _BalanceMiniStat extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _BalanceMiniStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const textSecondary = Color(0xFF7A7A7A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const borderColor = Color(0xFFE9E9EE);
    const textPrimary = Color(0xFF171717);
    const primaryBlue = Color(0xFF4F6EF7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String amount;
  final bool positive;
  final bool isGroup;

  const _BalanceRow({
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.positive,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const borderColor = Color(0xFFE9E9EE);
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF7A7A7A);
    const owedGreen = Color(0xFF2E9B6F);
    const oweRed = Color(0xFFD96B6B);
    const primaryBlue = Color(0xFF4F6EF7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isGroup
                  ? primaryBlue.withOpacity(0.10)
                  : const Color(0xFFF1F2F6),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(
              isGroup ? Icons.groups_rounded : Icons.person_rounded,
              color: isGroup ? primaryBlue : textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: positive ? owedGreen : oweRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: positive ? owedGreen : oweRed,
            ),
          ),
        ],
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