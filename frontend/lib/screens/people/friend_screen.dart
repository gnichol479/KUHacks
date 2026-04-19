import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/avatar_with_score.dart';
import 'people_list.dart';
import 'settle_up.dart';

class FriendScreen extends StatefulWidget {
  final String name;
  final String net;
  final bool isNegative;
  final String? ledgerId;

  const FriendScreen({
    super.key,
    required this.name,
    required this.net,
    required this.isNegative,
    this.ledgerId,
  });

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final AuthService _auth = AuthService();
  bool _loading = false;
  bool _failed = false;
  Map<String, dynamic>? _ledger;

  @override
  void initState() {
    super.initState();
    if (widget.ledgerId != null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await _auth.fetchLedger(widget.ledgerId!);
      if (!mounted) return;
      setState(() {
        _ledger = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('FETCH ledger error: $e');
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  String _formatNet(double balance) {
    final sign = balance >= 0 ? '+' : '-';
    return '$sign\$${balance.abs().toStringAsFixed(2)}';
  }

  Future<void> _openSettleUp() async {
    if (widget.ledgerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a real ledger to settle up.')),
      );
      return;
    }
    if (_ledger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading ledger — try again in a moment.')),
      );
      return;
    }
    final balance = ((_ledger!['balance'] ?? 0) as num).toDouble();
    if (balance == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All settled up with this person.')),
      );
      return;
    }
    final friendName =
        ((_ledger!['other_user'] as Map?)?['full_name'] as String?) ??
            widget.name;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettleUpSheet(
        ledgerId: widget.ledgerId!,
        friendName: friendName,
        currentBalance: balance,
      ),
    );

    if (!mounted) return;
    debugPrint('SETTLE UP sheet result=$result');
    if (result != null) {
      await _load();
      peopleListReloadKey.value++;
      if (!mounted) return;
      final txHash = result['tx_hash'] as String?;
      final entry = result['entry'];
      final method = entry is Map ? entry['method'] as String? : null;
      final amount = entry is Map ? (entry['amount'] as num?)?.toDouble() : null;
      final amountText =
          amount != null ? '\$${amount.toStringAsFixed(2)}' : '';
      String message;
      if (method == 'forgive') {
        message = amountText.isEmpty
            ? 'Forgave the debt.'
            : 'Forgave $amountText.';
      } else if (txHash != null) {
        message = 'Settled via XRPL (${txHash.substring(0, 8)}…)';
      } else {
        message = 'Settlement recorded.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLive = _ledger != null;
    final liveBalance =
        hasLive ? ((_ledger!['balance'] ?? 0) as num).toDouble() : null;
    final displayName = hasLive
        ? (((_ledger!['other_user'] as Map?)?['full_name'] as String?) ??
            widget.name)
        : widget.name;
    final net = liveBalance != null ? _formatNet(liveBalance) : widget.net;
    final isNegative =
        liveBalance != null ? liveBalance < 0 : widget.isNegative;
    final history = hasLive
        ? ((_ledger!['history'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
        : null;
    final otherScore = hasLive
        ? ((_ledger!['other_user'] as Map?)?['accountability_score']
            as num?)
        : null;
    final otherAvatar = hasLive
        ? ((_ledger!['other_user'] as Map?)?['avatar_base64'] as String?)
        : null;
    final headerInitial =
        (displayName.trim().isNotEmpty ? displayName.trim()[0] : '?')
            .toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (widget.ledgerId != null) await _load();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                    SizedBox(width: 6),
                    Text("Back",
                        style: TextStyle(
                            color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  AvatarWithScore(
                    radius: 32,
                    score: otherScore?.toInt(),
                    avatarBase64: otherAvatar,
                    child: Text(
                      headerInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Net: $net",
                        style: TextStyle(
                          color: isNegative ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white10,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            net,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isNegative ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(8, (i) {
                      return Transform.rotate(
                        angle: i * 0.785,
                        child: Center(
                          child: Container(
                            width: 2,
                            height: 100,
                            color: Colors.white10,
                          ),
                        ),
                      );
                    })
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _primary("Settle Up", onTap: _openSettleUp),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _secondary("Remind")),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                "ANALYTICS",
                style:
                    TextStyle(color: Colors.white54, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat("Total Paid", "\$320"),
                    _stat("You Paid", "\$150"),
                    _stat("They Paid", "\$170"),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "HISTORY",
                style:
                    TextStyle(color: Colors.white54, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              ..._historyContent(history),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _historyContent(List<Map<String, dynamic>>? history) {
    if (widget.ledgerId == null) {
      return [
        _history("Dinner at Nobu", "-\$45", true),
        _history("Movie Night", "+\$20", false),
        _history("Uber Split", "-\$15", true),
      ];
    }
    if (_loading) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ];
    }
    if (_failed) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Couldn't load history.",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: _load,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFF7F8CFF)),
                ),
              ),
            ],
          ),
        ),
      ];
    }
    if (history == null || history.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Text(
            'No transactions yet.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ];
    }
    return [
      for (final e in history) _historyTile(e),
    ];
  }

  Widget _historyTile(Map<String, dynamic> e) {
    final title = (e['description'] as String?) ?? '';
    final amount = _formatEntryAmount(e);
    final negative = ((e['signed_amount'] ?? 0) as num).toDouble() < 0;
    final method = (e['method'] as String?) ?? 'iou';
    final dueChip = method == 'iou' ? _dueChip(e['due_at'] as String?) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: negative ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (dueChip != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: dueChip),
          ],
        ],
      ),
    );
  }

  /// Renders the small "Due Apr 26" / "Overdue 4d" / "No due date" pill
  /// underneath an IOU entry. Settlement entries skip this entirely
  /// (they're not debts that can be late).
  Widget _dueChip(String? dueAtIso) {
    final now = DateTime.now();
    String label;
    Color bg;
    Color fg;
    if (dueAtIso == null || dueAtIso.isEmpty) {
      label = 'No due date';
      bg = const Color(0x33FFFFFF);
      fg = Colors.white60;
    } else {
      final due = DateTime.tryParse(dueAtIso)?.toLocal();
      if (due == null) {
        label = 'No due date';
        bg = const Color(0x33FFFFFF);
        fg = Colors.white60;
      } else {
        final diff = due.difference(
          DateTime(now.year, now.month, now.day),
        );
        final days = diff.inDays;
        if (days < 0) {
          final overdueBy = -days;
          label = 'Overdue ${overdueBy}d';
          bg = const Color(0x33EF4444);
          fg = const Color(0xFFFCA5A5);
        } else {
          label = 'Due ${_formatDueDate(due)}';
          bg = const Color(0x3322C55E);
          fg = const Color(0xFFA7F3D0);
        }
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDueDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  String _formatEntryAmount(Map<String, dynamic> entry) {
    final signed = ((entry['signed_amount'] ?? 0) as num).toDouble();
    final sign = signed >= 0 ? '+' : '-';
    return '$sign\$${signed.abs().toStringAsFixed(2)}';
  }

  Widget _primary(String text, {VoidCallback? onTap}) {
    final button = Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
    );
    if (onTap == null) return button;
    return GestureDetector(onTap: onTap, child: button);
  }

  Widget _secondary(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  static Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }

  Widget _history(String title, String amount, bool negative) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Text(
            amount,
            style: TextStyle(
              color: negative ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}
