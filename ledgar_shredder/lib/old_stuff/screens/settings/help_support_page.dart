import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';
import 'settings_detail_scaffold.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  void _openFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _FAQSheet(),
    );
  }

  void _openContact(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ContactSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Help and Support',
      children: [
        SettingsTile(
          icon: Icons.help_outline_rounded,
          title: 'FAQ',
          subtitle: 'Find quick answers to common questions.',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openFAQ(context),
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Contact Support',
          subtitle: 'Reach out if something is not working right.',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openContact(context),
        ),
        const Divider(),

        const SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'App Version',
          subtitle: 'Ledgar Shredder v0.1 MVP',
        ),
      ],
    );
  }
}

class _FAQSheet extends StatelessWidget {
  const _FAQSheet();

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'FAQ',
      child: Column(
        children: const [
          _FAQItem(
            question: 'How does auto-settle work?',
            answer:
                'We automatically balance debts between people to minimize transactions.',
          ),
          SizedBox(height: 14),
          _FAQItem(
            question: 'Are payments real?',
            answer:
                'Not yet — this is a prototype. Payments are simulated.',
          ),
          SizedBox(height: 14),
          _FAQItem(
            question: 'Can I use this with groups?',
            answer:
                'Yes — groups track shared balances between multiple people.',
          ),
        ],
      ),
    );
  }
}

class _ContactSheet extends StatelessWidget {
  const _ContactSheet();

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'Contact Support',
      child: Column(
        children: [
          const Text(
            'Describe your issue and we’ll get back to you.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const TextField(
              maxLines: 4,
              decoration: InputDecoration.collapsed(
                hintText: 'Type your message...',
              ),
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
              child: const Text('Send Message'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(answer),
        ],
      ),
    );
  }
}

class _BaseSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _BaseSheet({
    required this.title,
    required this.child,
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
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
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

                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}