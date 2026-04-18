import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'settings_detail_scaffold.dart';

class BankWalletPage extends StatefulWidget {
  const BankWalletPage({super.key});

  @override
  State<BankWalletPage> createState() => _BankWalletPageState();
}

class _BankWalletPageState extends State<BankWalletPage> {
  bool cardEnabled = true;

  void _openWalletSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WalletSheet(),
    );
  }

  void _openCardSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CardSheet(),
    );
  }

  void _openBankSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BankSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Bank and Wallet',
      children: [
        SettingsTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Primary Wallet',
          subtitle: 'Auto-Settle Balance available: \$40.00',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _openWalletSheet,
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.credit_card_outlined,
          title: 'Default Payment Method',
          subtitle: 'Visa ending in 2048',
          trailing: Switch(
            value: cardEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                cardEnabled = value;
              });
            },
          ),
          onTap: _openCardSheet,
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.account_balance_outlined,
          title: 'Linked Bank',
          subtitle: 'Midwest Federal Checking',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _openBankSheet,
        ),
      ],
    );
  }
}

class _WalletSheet extends StatelessWidget {
  const _WalletSheet();

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'Wallet',
      children: [
        const Text(
          '\$40.00',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text('Available for auto-settle'),

        const SizedBox(height: 20),

        _ActionButton(label: 'Add Funds'),
        const SizedBox(height: 10),
        _ActionButton(label: 'Withdraw'),
      ],
    );
  }
}

class _CardSheet extends StatelessWidget {
  const _CardSheet();

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'Payment Method',
      children: [
        const Text('Visa •••• 2048'),
        const SizedBox(height: 16),
        _ActionButton(label: 'Change Card'),
        const SizedBox(height: 10),
        _ActionButton(label: 'Remove Card'),
      ],
    );
  }
}

class _BankSheet extends StatelessWidget {
  const _BankSheet();

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'Linked Bank',
      children: [
        const Text('Midwest Federal Checking'),
        const SizedBox(height: 16),
        _ActionButton(label: 'Change Bank'),
        const SizedBox(height: 10),
        _ActionButton(label: 'Unlink Bank'),
      ],
    );
  }
}

class _BaseSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _BaseSheet({
    required this.title,
    required this.children,
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

            const SizedBox(height: 16),

            ...children,
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;

  const _ActionButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
        child: Text(label),
      ),
    );
  }
}