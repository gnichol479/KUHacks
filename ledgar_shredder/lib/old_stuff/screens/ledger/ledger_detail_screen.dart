import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../screens/theme/app_colors.dart';

class LedgerDetailScreen extends StatelessWidget {
  final String name;
  final String subtitle;
  final String amount;
  final bool positive;
  final bool isGroup;

  const LedgerDetailScreen({
    super.key,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.positive,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF7F7F8);
    const cardColor = Colors.white;
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF7A7A7A);
    const borderColor = Color(0xFFE9E9EE);
    const primaryBlue = Color(0xFF4F6EF7);
    const owedGreen = Color(0xFF2E9B6F);
    const oweRed = Color(0xFFD96B6B);

final statusColor = positive
    ? AppColors.positive
    : AppColors.negative;    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: textPrimary,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                label: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isGroup
                          ? primaryBlue.withOpacity(0.10)
                          : const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Icon(
                      isGroup ? Icons.groups_rounded : Icons.person_rounded,
                      color: isGroup ? primaryBlue : textSecondary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

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
                      'CURRENT STATUS',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.2,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      positive ? 'They owe you' : 'You owe them',
                      style: const TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Pay',
                      icon: Icons.payments_outlined,
                      filled: true,
                      onTap: () {
                        _showMiniSheet(
                          context,
                          title: 'Make Payment',
                          content: const _SimpleActionContent(
                            lines: [
                              'Partial or full payment',
                              'Mock Venmo / Apple Pay / Cash',
                              'No backend hooked up yet',
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Write',
                      icon: Icons.edit_note_rounded,
                      filled: false,
                      onTap: () {
                        _showMiniSheet(
                          context,
                          title: 'Write New Ledger',
                          content: _WriteLedgerContent(name: name),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Notify',
                      icon: Icons.notifications_outlined,
                      filled: false,
                      onTap: () {
                        _showMiniSheet(
                          context,
                          title: 'Send Reminder',
                          content: _NotifyContent(name: name),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                'RELATIONSHIP SNAPSHOT',
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 240,
                      child: RadarChart(
                        values: const [0.82, 0.64, 0.76, 0.58, 0.44, 0.71],
                        labels: const [
                          'Trust',
                          'Speed',
                          'Activity',
                          'Response',
                          'Tokens',
                          'Completion',
                        ],
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _TrendChip(label: 'Paid on time', value: '82%'),
                        _TrendChip(label: 'Avg response', value: '1.2d'),
                        _TrendChip(label: 'Open items', value: '3'),
                        _TrendChip(label: 'This month', value: '+2'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'OPEN OBLIGATIONS',
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
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: const Column(
                  children: [
                    _ObligationRow(
                      title: 'Dinner split',
                      subtitle: 'Created 2 days ago',
                      amount: '\$22',
                    ),
                    Divider(height: 1, color: borderColor),
                    _ObligationRow(
                      title: 'Gas money',
                      subtitle: 'Created 5 days ago',
                      amount: '\$18',
                    ),
                    Divider(height: 1, color: borderColor),
                    _ObligationRow(
                      title: 'Movie tickets',
                      subtitle: 'Awaiting confirmation',
                      amount: '\$12',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'RECENT ACTIVITY',
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
                    _ActivityRow(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'New ledger created',
                      subtitle: 'Dinner split • 2 days ago',
                    ),
                    SizedBox(height: 18),
                    _ActivityRow(
                      icon: Icons.notifications_outlined,
                      title: 'Reminder sent',
                      subtitle: 'Gas money • 4 days ago',
                    ),
                    SizedBox(height: 18),
                    _ActivityRow(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Partial payment received',
                      subtitle: 'Movie tickets • 1 week ago',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showMiniSheet(
    BuildContext context, {
    required String title,
    required Widget content,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LedgerActionSheet(
        title: title,
        child: content,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4F6EF7);
    const borderColor = Color(0xFFE9E9EE);
    const textPrimary = Color(0xFF171717);

    return SizedBox(
      height: 54,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: const BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final String label;
  final String value;

  const _TrendChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE9E9EE);
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF7A7A7A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObligationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;

  const _ObligationRow({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF7A7A7A);
    const primaryBlue = Color(0xFF4F6EF7);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
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
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4F6EF7);
    const textPrimary = Color(0xFF171717);
    const textSecondary = Color(0xFF7A7A7A);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryBlue),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerActionSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _LedgerActionSheet({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF171717);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
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
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleActionContent extends StatelessWidget {
  final List<String> lines;

  const _SimpleActionContent({
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE9E9EE);
    const textPrimary = Color(0xFF171717);

    return Column(
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              lines[i],
              style: const TextStyle(
                fontSize: 15,
                color: textPrimary,
              ),
            ),
          ),
          if (i != lines.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _WriteLedgerContent extends StatelessWidget {
  final String name;

  const _WriteLedgerContent({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4F6EF7);
    const borderColor = Color(0xFFE9E9EE);

    return Column(
      children: [
        _MiniField(label: 'Who', value: name),
        const SizedBox(height: 14),
        const _MiniField(label: 'Description', value: 'Dinner, gas, tickets...'),
        const SizedBox(height: 14),
        const _MiniField(label: 'Amount', value: '\$0.00'),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotifyContent extends StatelessWidget {
  final String name;

  const _NotifyContent({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4F6EF7);
    const textSecondary = Color(0xFF7A7A7A);
    const borderColor = Color(0xFFE9E9EE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Send $name a reminder about the open balance.',
          style: const TextStyle(
            fontSize: 15,
            color: textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: const Text(
            'Friendly ping — this balance is still open.',
            style: TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Send Reminder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniField extends StatelessWidget {
  final String label;
  final String value;

  const _MiniField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF171717);
    const borderColor = Color(0xFFE9E9EE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class RadarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;

  const RadarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarChartPainter(
        values: values,
        labels: labels,
        color: color,
      ),
      child: Container(),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;

  _RadarChartPainter({
    required this.values,
    required this.labels,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.32;
    final sides = values.length;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E9F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final dataFill = Paint()
      ..color = color.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final dataStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int layer = 1; layer <= 4; layer++) {
      final r = radius * (layer / 4);
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = (-math.pi / 2) + (2 * math.pi * i / sides);
        final point = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < sides; i++) {
      final angle = (-math.pi / 2) + (2 * math.pi * i / sides);
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }

    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (-math.pi / 2) + (2 * math.pi * i / sides);
      final r = radius * values[i];
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, dataFill);
    canvas.drawPath(dataPath, dataStroke);

    final textStyle = const TextStyle(
      color: Color(0xFF7A7A7A),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < sides; i++) {
      final angle = (-math.pi / 2) + (2 * math.pi * i / sides);
      final labelOffset = Offset(
        center.dx + (radius + 28) * math.cos(angle),
        center.dy + (radius + 28) * math.sin(angle),
      );

      final textSpan = TextSpan(text: labels[i], style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          labelOffset.dx - tp.width / 2,
          labelOffset.dy - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.color != color;
  }
}