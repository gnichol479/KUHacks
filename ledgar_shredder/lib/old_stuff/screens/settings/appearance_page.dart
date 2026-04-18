import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';
import 'settings_detail_scaffold.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  bool compactMode = false;
  String selectedTheme = 'Light';
  String textSize = 'Standard';

  void _openThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SelectionSheet(
          title: 'Choose Theme',
          options: ['Light'],
          selected: selectedTheme,
          onSelected: (value) {
            setState(() {
              selectedTheme = value;
            });
          },
        );
      },
    );
  }

  void _openTextSizeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SelectionSheet(
          title: 'Text Size',
          options: ['Small', 'Standard', 'Large'],
          selected: textSize,
          onSelected: (value) {
            setState(() {
              textSize = value;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Appearance',
      children: [
        SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Theme',
          subtitle: '$selectedTheme mode',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _openThemeSelector,
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.view_agenda_outlined,
          title: 'Compact Mode',
          subtitle: 'Reduce spacing and fit more balances on screen.',
          trailing: Switch(
            value: compactMode,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                compactMode = value;
              });
            },
          ),
        ),
        const Divider(),

        SettingsTile(
          icon: Icons.text_fields_rounded,
          title: 'Text Size',
          subtitle: textSize,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _openTextSizeSelector,
        ),
      ],
    );
  }
}

class _SelectionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final Function(String) onSelected;

  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
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

            ...options.map((option) {
              final isSelected = option == selected;

              return GestureDetector(
                onTap: () {
                  onSelected(option);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}