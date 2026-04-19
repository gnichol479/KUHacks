import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_with_score.dart';
import '../../widgets/due_in_picker.dart';
import '../people/people_list.dart';

/// Detail view for a single group. Shows the running net per member from
/// the viewer's POV and lets the viewer record what they owe a member or
/// settle it via XRPL — mirrors the per-friend `FriendScreen` flow.
class GroupScreen extends StatefulWidget {
  final String groupId;
  final String? initialName;

  const GroupScreen({
    super.key,
    required this.groupId,
    this.initialName,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  bool _failed = false;
  Map<String, dynamic>? _group;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await _auth.fetchGroup(widget.groupId);
      if (!mounted) return;
      setState(() {
        _group = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('FETCH group error: $e');
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

  String _memberDisplayName(Map<String, dynamic> member) {
    final fullName = member['full_name'] as String?;
    final username = member['username'] as String?;
    if (fullName != null && fullName.isNotEmpty) return fullName;
    if (username != null && username.isNotEmpty) return '@$username';
    return 'Unknown';
  }

  Future<void> _openMemberActions(Map<String, dynamic> member) async {
    final memberName = _memberDisplayName(member);
    final net = (member['net'] as num?)?.toDouble() ?? 0.0;
    // net > 0 => they owe me; net < 0 => I owe them.
    final canSettle = net < 0;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                memberName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.note_add, color: Colors.lightBlueAccent),
              title: Text(
                'I owe $memberName',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Record what you owe them',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, 'iou'),
            ),
            ListTile(
              leading: const Icon(
                Icons.call_received,
                color: Colors.greenAccent,
              ),
              title: Text(
                '$memberName owes me',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Record what they owe you',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, 'owed'),
            ),
            ListTile(
              leading: Icon(
                Icons.flash_on,
                color: canSettle ? Colors.greenAccent : Colors.white24,
              ),
              title: Text(
                'Settle Up',
                style: TextStyle(
                  color: canSettle ? Colors.white : Colors.white38,
                ),
              ),
              subtitle: Text(
                canSettle
                    ? 'Pay ${_formatNet(net)} via XRPL'
                    : 'Nothing to settle with this member',
                style: const TextStyle(color: Colors.white54),
              ),
              enabled: canSettle,
              onTap: canSettle ? () => Navigator.pop(context, 'settle') : null,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'iou') {
      await _openAddIouSheet(member);
    } else if (action == 'owed') {
      await _openAddIouSheet(member, theyOweMe: true);
    } else if (action == 'settle') {
      await _openSettleSheet(member, net);
    }
  }

  Future<void> _openAddIouSheet(
    Map<String, dynamic> member, {
    bool theyOweMe = false,
  }) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupEntrySheet(
        groupId: widget.groupId,
        toUserId: member['id'] as String,
        toUserName: _memberDisplayName(member),
        theyOweMe: theyOweMe,
      ),
    );
    if (!mounted || result == null) return;
    // The IOU is now a pending request; the group balance only changes once
    // `member` accepts via the Requests > Ledger tab. Skip _load() so the
    // UI doesn't briefly imply the entry has been applied.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Request sent — waiting on ${_memberDisplayName(member)} to accept.',
        ),
      ),
    );
  }

  Future<void> _openSettleSheet(
    Map<String, dynamic> member,
    double net,
  ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupSettleSheet(
        groupId: widget.groupId,
        toUserId: member['id'] as String,
        toUserName: _memberDisplayName(member),
        debt: net.abs(),
      ),
    );
    if (!mounted || result == null) return;
    await _load();
    peopleListReloadKey.value++;
    final txHash = result['tx_hash'] as String?;
    final message = txHash != null
        ? 'Settled via XRPL (${txHash.substring(0, 8)}…)'
        : 'Settlement recorded.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupName = (_group?['name'] as String?) ?? widget.initialName ?? 'Group';
    final members =
        ((_group?['members'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final history =
        ((_group?['history'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final net = (_group?['balance'] as num?)?.toDouble() ?? 0.0;
    final isNegative = net < 0;
    final netLabel = _formatNet(net);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
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
                    Text(
                      "Back",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Text('👥', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${members.length} members',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOUR NET BALANCE',
                      style: TextStyle(
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      netLabel,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isNegative ? Colors.redAccent : Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      net == 0
                          ? 'All settled with this group'
                          : isNegative
                              ? 'You owe in this group'
                              : 'You are owed in this group',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'MEMBERS',
                style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              if (_loading)
                _loadingBox()
              else if (_failed)
                _failedBox()
              else
                _membersBlock(members),
              const SizedBox(height: 24),
              const Text(
                'HISTORY',
                style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              if (_loading)
                _loadingBox()
              else if (_failed)
                _failedBox()
              else
                _historyBlock(history),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _failedBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Couldn't load group.",
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
    );
  }

  Widget _membersBlock(List<Map<String, dynamic>> members) {
    final others =
        members.where((m) => (m['is_self'] as bool?) != true).toList();
    if (others.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No other members.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < others.length; i++) ...[
            _memberTile(others[i]),
            if (i != others.length - 1) const Divider(color: Colors.white10),
          ],
        ],
      ),
    );
  }

  Widget _memberTile(Map<String, dynamic> member) {
    final net = (member['net'] as num?)?.toDouble() ?? 0.0;
    final positive = net >= 0;
    final label = net == 0
        ? 'Settled'
        : positive
            ? 'Owes you ${_formatNet(net)}'
            : 'You owe ${_formatNet(net)}';
    final color = net == 0
        ? Colors.white54
        : positive
            ? Colors.greenAccent
            : Colors.redAccent;
    final memberName = _memberDisplayName(member);
    final initial =
        (memberName.trim().isNotEmpty ? memberName.trim()[0] : '?').toUpperCase();
    return ListTile(
      leading: AvatarWithScore(
        radius: 20,
        score: (member['accountability_score'] as num?)?.toInt(),
        avatarBase64: member['avatar_base64'] as String?,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        memberName,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: () => _openMemberActions(member),
    );
  }

  Widget _historyBlock(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return Container(
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
      );
    }
    return Column(
      children: [
        for (final e in history) _historyTile(e),
      ],
    );
  }

  Widget _historyTile(Map<String, dynamic> entry) {
    final from = (entry['from_user'] as Map?) ?? {};
    final to = (entry['to_user'] as Map?) ?? {};
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
    final method = (entry['method'] as String?) ?? 'iou';
    final fromName = _memberDisplayName(from.cast<String, dynamic>());
    final toName = _memberDisplayName(to.cast<String, dynamic>());
    final desc = (entry['description'] as String?) ?? '';
    final isSettle = method == 'xrp';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$fromName → $toName',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isSettle ? Colors.greenAccent : Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isSettle)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'XRP',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupEntrySheet extends StatefulWidget {
  final String groupId;
  final String toUserId;
  final String toUserName;
  final bool theyOweMe;

  const _GroupEntrySheet({
    required this.groupId,
    required this.toUserId,
    required this.toUserName,
    this.theyOweMe = false,
  });

  @override
  State<_GroupEntrySheet> createState() => _GroupEntrySheetState();
}

class _GroupEntrySheetState extends State<_GroupEntrySheet> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final AuthService _auth = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _submitting = false;
  bool _scanning = false;
  String? _error;
  // Mirror NewLedgerSheet's default so 1:1 and group IOUs feel consistent.
  int? _dueInDays = 7;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (desc.isEmpty) {
      setState(() => _error = 'Description is required');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _auth.createGroupEntryRequest(
        groupId: widget.groupId,
        toUserId: widget.toUserId,
        amount: amount,
        description: desc,
        theyOweMe: widget.theyOweMe,
        dueInDays: _dueInDays,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (e) {
      debugPrint('GROUP IOU REQUEST error: $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Network error. Try again.';
      });
    }
  }

  Future<void> _scanReceipt() async {
    if (_scanning) return;
    setState(() => _error = null);

    final XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('SCAN pickImage error: $e');
      if (!mounted) return;
      setState(() => _error = 'Could not open the camera.');
      return;
    }
    if (picked == null) return;

    setState(() => _scanning = true);
    try {
      final bytes = await picked.readAsBytes();
      final mimeType = picked.mimeType ?? _guessMime(picked.path);
      final result = await _auth.scanReceipt(
        bytes: bytes,
        mimeType: mimeType,
      );
      if (!mounted) return;

      final store = (result['store'] as String?)?.trim() ?? '';
      final total = result['total'];
      final totalNum = total is num ? total : null;

      if (store.isEmpty && (totalNum == null || totalNum <= 0)) {
        setState(() {
          _scanning = false;
          _error = "Couldn't read that receipt. Try a clearer photo.";
        });
        return;
      }

      setState(() {
        if (store.isNotEmpty) _descController.text = store;
        if (totalNum != null && totalNum > 0) {
          _amountController.text = totalNum.toStringAsFixed(2);
        }
        _scanning = false;
      });
    } on ApiException catch (e) {
      debugPrint('SCAN ApiException ${e.statusCode}: ${e.message}');
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = _humanizeScan(e);
      });
    } catch (e) {
      debugPrint('SCAN error: $e');
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = 'Network error while scanning. Try again.';
      });
    }
  }

  String _humanizeScan(ApiException e) {
    switch (e.statusCode) {
      case 503:
        return 'Receipt scanning is not configured on the server yet.';
      case 502:
        return 'Gemini could not process this receipt. Try another photo.';
      case 422:
        return "Couldn't read that receipt. Try a clearer photo.";
      case 401:
        return 'Session expired — log in again.';
      default:
        return e.message;
    }
  }

  String _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.theyOweMe
        ? '${widget.toUserName} owes me'
        : 'I owe ${widget.toUserName}';
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _field(
                controller: _descController,
                hint: 'What for? (e.g. Pizza Friday)',
              ),
              const SizedBox(height: 12),
              _field(
                controller: _amountController,
                hint: 'Amount in USD',
                keyboard:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              _scanReceiptButton(),
              const SizedBox(height: 16),
              DueInPicker(
                selectedDays: _dueInDays,
                onChanged: (v) => setState(() => _dueInDays = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Opacity(
                  opacity: _submitting ? 0.6 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Add IOU',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanReceiptButton() {
    return GestureDetector(
      onTap: _scanning ? null : _scanReceipt,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7F8CFF)),
        ),
        alignment: Alignment.center,
        child: _scanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF7F8CFF)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt,
                      color: Color(0xFF7F8CFF), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Scan a receipt',
                    style: TextStyle(
                      color: Color(0xFF7F8CFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white70,
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
        ),
      ),
    );
  }
}

class _GroupSettleSheet extends StatefulWidget {
  final String groupId;
  final String toUserId;
  final String toUserName;
  final double debt;

  const _GroupSettleSheet({
    required this.groupId,
    required this.toUserId,
    required this.toUserName,
    required this.debt,
  });

  @override
  State<_GroupSettleSheet> createState() => _GroupSettleSheetState();
}

class _GroupSettleSheetState extends State<_GroupSettleSheet> {
  late final TextEditingController _amountController;
  final AuthService _auth = AuthService();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.debt.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (amount > widget.debt + 0.01) {
      setState(() => _error =
          'Amount exceeds what you owe (\$${widget.debt.toStringAsFixed(2)})');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _auth.settleGroup(
        groupId: widget.groupId,
        toUserId: widget.toUserId,
        amount: amount,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _humanize(e);
      });
    } catch (e) {
      debugPrint('SETTLE GROUP error: $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Network error. Try again.';
      });
    }
  }

  String _humanize(ApiException e) {
    switch (e.statusCode) {
      case 502:
        return 'XRPL payment failed. Try again in a moment.';
      case 409:
        return 'Wallet not provisioned for one of the users.';
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Settle with ${widget.toUserName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You owe \$${widget.debt.toStringAsFixed(2)}. The amount '
                'below will be sent on XRPL Testnet.',
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white70,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Amount in USD',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Opacity(
                  opacity: _submitting ? 0.6 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Pay via XRPL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
