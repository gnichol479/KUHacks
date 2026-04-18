import 'package:flutter/material.dart';
import 'settings_detail_scaffold.dart';

class BankWalletPage extends StatefulWidget {
  const BankWalletPage({super.key});

  @override
  State<BankWalletPage> createState() => _BankWalletPageState();
}

class _BankWalletPageState extends State<BankWalletPage> {
  bool cardEnabled = true;

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
        ),
        const Divider(),
        SettingsTile(
          icon: Icons.credit_card_outlined,
          title: 'Default Payment Method',
          subtitle: 'Visa ending in 2048',
          trailing: Switch(
            value: cardEnabled,
            onChanged: (value) {
              setState(() {
                cardEnabled = value;
              });
            },
          ),
        ),
        const Divider(),
        const SettingsTile(
          icon: Icons.account_balance_outlined,
          title: 'Linked Bank',
          subtitle: 'Midwest Federal Checking',
          trailing: Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}