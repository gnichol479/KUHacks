import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';

class SettleUpSheet extends StatefulWidget {
  final String ledgerId;
  final String friendName;
  final double currentBalance;

  const SettleUpSheet({
    super.key,
    required this.ledgerId,
    required this.friendName,
    required this.currentBalance,
  });

  @override
  State<SettleUpSheet> createState() => _SettleUpSheetState();
}

class _SettleUpSheetState extends State<SettleUpSheet> {
  final AuthService _auth = AuthService();
  late final TextEditingController _amountController;
  bool _submitting = false;
  String? _error;

  double get _debt => widget.currentBalance < 0
      ? widget.currentBalance.abs()
      : 0.0;

  double get _credit => widget.currentBalance > 0
      ? widget.currentBalance
      : 0.0;

  bool get _isCredit => widget.currentBalance > 0;

  @override
  void initState() {
    super.initState();
    final initial = _isCredit ? _credit : _debt;
    _amountController =
        TextEditingController(text: initial.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setError(String? message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  String _humanize(ApiException e) {
    switch (e.statusCode) {
      case 502:
        return 'XRPL payment failed. Try again in a moment.';
      case 409:
        return 'Wallet not set up for one of you yet.';
      case 404:
        return 'Server is missing this endpoint. Redeploy the backend so /ledgers/<id>/settle exists.';
      case 401:
        return 'Session expired — log in again.';
      case 403:
        return 'You are not part of this ledger anymore.';
      default:
        return e.message;
    }
  }

  double? _parseAmount() {
    final raw = _amountController.text
        .trim()
        .replaceAll(r'$', '')
        .replaceAll(',', '');
    return double.tryParse(raw);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: const TextStyle(
                color: Color(0xFF7F8CFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _payWithXrp() async {
    _setError(null);

    if (_debt <= 0) {
      _setError('Nothing to settle on this ledger.');
      return;
    }
    final amount = _parseAmount();
    if (amount == null || amount <= 0) {
      _setError('Enter an amount greater than 0.');
      return;
    }
    if (amount > _debt + 0.01) {
      _setError('Amount exceeds your current debt of '
          '\$${_debt.toStringAsFixed(2)}.');
      return;
    }

    final confirmed = await _confirm(
      title: 'Send via XRPL?',
      message:
          'Send \$${amount.toStringAsFixed(2)} to ${widget.friendName} via XRPL? '
          'This cannot be undone.',
      confirmLabel: 'Send',
    );
    if (!confirmed || !mounted) return;

    debugPrint(
      'SETTLE UP ledgerId=${widget.ledgerId} amount=$amount method=xrp',
    );

    setState(() => _submitting = true);
    try {
      final result = await _auth.settleUp(
        ledgerId: widget.ledgerId,
        amount: amount,
        method: 'xrp',
      );
      if (!mounted) return;
      debugPrint('SETTLE UP result=$result');

      final entry = result['entry'];
      final balance = result['balance'];
      if (entry is! Map || balance is! num) {
        debugPrint('SETTLE UP malformed response: $result');
        setState(() => _submitting = false);
        _setError(
          'Server returned an unexpected response. See console for details.',
        );
        return;
      }

      Navigator.pop(context, {
        'entry': entry,
        'balance': balance,
        'tx_hash': result['tx_hash'],
      });
    } on ApiException catch (e) {
      debugPrint('SETTLE UP ApiException ${e.statusCode}: ${e.message}');
      if (!mounted) return;
      setState(() => _submitting = false);
      _setError(_humanize(e));
    } catch (e) {
      debugPrint('SETTLE UP error: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      _setError('Network error. Try again.');
    }
  }

  Future<void> _payFromBank() async {
    final amount = _parseAmount();
    final amountText = (amount != null && amount > 0)
        ? '\$${amount.toStringAsFixed(2)}'
        : 'this amount';
    final confirmed = await _confirm(
      title: 'Pay from bank?',
      message:
          'Send $amountText to ${widget.friendName} from Chase Checking?',
      confirmLabel: 'Continue',
    );
    if (!confirmed || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BankPaySheet(
        amount: amount,
        friendName: widget.friendName,
      ),
    );
  }

  Future<void> _forgive() async {
    _setError(null);

    if (_credit <= 0) {
      _setError('Nothing to forgive on this ledger.');
      return;
    }
    final amount = _parseAmount();
    if (amount == null || amount <= 0) {
      _setError('Enter an amount greater than 0.');
      return;
    }
    if (amount > _credit + 0.01) {
      _setError('Amount exceeds what they owe you '
          '(\$${_credit.toStringAsFixed(2)}).');
      return;
    }

    final confirmed = await _confirm(
      title: "Let 'em slide?",
      message:
          "Forgive \$${amount.toStringAsFixed(2)} of ${widget.friendName}'s "
          'debt? This will be recorded in the ledger history and cannot be '
          'undone.',
      confirmLabel: "Let 'em slide",
    );
    if (!confirmed || !mounted) return;

    debugPrint(
      'FORGIVE ledgerId=${widget.ledgerId} amount=$amount',
    );

    setState(() => _submitting = true);
    try {
      final result = await _auth.forgiveDebt(
        ledgerId: widget.ledgerId,
        amount: amount,
      );
      if (!mounted) return;
      debugPrint('FORGIVE result=$result');

      final entry = result['entry'];
      final balance = result['balance'];
      if (entry is! Map || balance is! num) {
        debugPrint('FORGIVE malformed response: $result');
        setState(() => _submitting = false);
        _setError(
          'Server returned an unexpected response. See console for details.',
        );
        return;
      }

      Navigator.pop(context, {
        'entry': entry,
        'balance': balance,
      });
    } on ApiException catch (e) {
      debugPrint('FORGIVE ApiException ${e.statusCode}: ${e.message}');
      if (!mounted) return;
      setState(() => _submitting = false);
      _setError(_humanize(e));
    } catch (e) {
      debugPrint('FORGIVE error: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      _setError('Network error. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canTap = !_submitting;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                _isCredit ? "Let 'em Slide" : 'Settle Up',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isCredit
                    ? '${widget.friendName} owes you '
                        '\$${_credit.toStringAsFixed(2)}'
                    : (_debt > 0
                        ? 'You owe ${widget.friendName} '
                            '\$${_debt.toStringAsFixed(2)}'
                        : 'Nothing to settle with ${widget.friendName}.'),
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 20),
              _inputField(
                label: 'Amount (USD)',
                hint: '\$0.00',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  if (_error != null) _setError(null);
                },
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x33FF5C5C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFF5C5C)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFFB4B4),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFFB4B4)),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isCredit)
                Opacity(
                  opacity: canTap ? 1.0 : 0.5,
                  child: GestureDetector(
                    onTap: canTap ? _forgive : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5B6CFF),
                            Color(0xFF7F8CFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Let 'em slide",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: canTap ? 1.0 : 0.5,
                        child: GestureDetector(
                          onTap: canTap ? _payWithXrp : null,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5B6CFF),
                                  Color(0xFF7F8CFF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Pay in XRP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Opacity(
                        opacity: canTap ? 1.0 : 0.5,
                        child: GestureDetector(
                          onTap: canTap ? _payFromBank : null,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Pay from Bank',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                _isCredit
                    ? 'Forgiving the debt removes it from your ledger.'
                    : 'XRP transfers settle on the XRPL testnet.',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    String? hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1F2937),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class BankPaySheet extends StatelessWidget {
  final double? amount;
  final String friendName;

  const BankPaySheet({
    super.key,
    required this.amount,
    required this.friendName,
  });

  @override
  Widget build(BuildContext context) {
    final amountText = (amount != null && amount! > 0)
        ? '\$${amount!.toStringAsFixed(2)}'
        : '\$0.00';
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              'Pay from Bank',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Send $amountText to $friendName',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1B3A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.account_balance,
                          color: Color(0xFF7F8CFF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chase Checking',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '••••2451',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _row('Amount', amountText),
                  const SizedBox(height: 8),
                  _row('Recipient', friendName),
                  const SizedBox(height: 8),
                  _row('Network', 'ACH (1-3 business days)'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Confirm Payment (Coming Soon)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF7F8CFF)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
