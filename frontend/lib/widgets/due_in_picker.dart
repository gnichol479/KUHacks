import 'package:flutter/material.dart';

/// One option in the "Due in" picker. `days == null` means "no due date";
/// the backend treats omitted/null `due_in_days` as a debt without a
/// deadline, which keeps the entry from contributing to overdue penalty.
class DueInOption {
  final int? days;
  final String label;
  const DueInOption(this.days, this.label);
}

/// Whitelisted set kept in sync with `ALLOWED_DUE_IN_DAYS` in
/// `backend/app.py`. The "No due date" option sits last so the more common
/// "1 week" default visually anchors the chip row to the left.
const List<DueInOption> kDueInOptions = [
  DueInOption(3, '3 days'),
  DueInOption(7, '1 week'),
  DueInOption(14, '2 weeks'),
  DueInOption(30, '1 month'),
  DueInOption(90, '3 months'),
  DueInOption(null, 'No due date'),
];

/// Compact dark-themed chip row matching the rest of the New IOU sheet
/// (`#1F2937` selected / `#111827` unselected). The picker is *purely*
/// presentational — owning widgets keep the selected `int? days` in their
/// own state and rebuild the picker on change.
class DueInPicker extends StatelessWidget {
  final int? selectedDays;
  final ValueChanged<int?> onChanged;
  final String label;

  const DueInPicker({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    this.label = 'Due in',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kDueInOptions.map((opt) {
            final selected = opt.days == selectedDays;
            return GestureDetector(
              onTap: () => onChanged(opt.days),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1F2937)
                      : const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF7F8CFF)
                        : Colors.white24,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF7F8CFF)
                        : Colors.white70,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
