import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'auto_pay.dart';
import 'add_funds.dart';
import '../settings/settings_page.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/auto_pay_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _auth = AuthService();
  AutoPaySettings _autoPay = const AutoPaySettings.off();
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool _autoPayBusy = false;
  // Memory NFTs minted via the "let 'em slide" flow. Hydrated from
  // /memories on every profile load so the list stays in sync after a
  // forgive happens elsewhere in the app.
  List<Map<String, dynamic>> _memories = const [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _hydrateAutoPay();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    try {
      final raw = await _auth.fetchMemories();
      if (!mounted) return;
      setState(() => _memories = raw.cast<Map<String, dynamic>>());
    } catch (e) {
      debugPrint('Failed to load memories: $e');
    }
  }

  Future<void> _hydrateAutoPay() async {
    final s = await AutoPayService.instance.load();
    if (!mounted) return;
    setState(() => _autoPay = s);
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _auth.fetchProfile();
      if (!mounted) return;
      setState(() {
        profileData = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String _scopeLabel(AutoPaySettings s) {
    switch (s.scope) {
      case AutoPayScope.off:
        return 'Auto-Settle is off. Turn it on to pick who to auto-pay.';
      case AutoPayScope.all:
        return 'Auto-paying everyone you owe.';
      case AutoPayScope.friends:
        if (s.friendIds.isEmpty) {
          return 'Auto-paying selected friends when you owe them.';
        }
        final names = s.friendIds
            .map((id) => s.nameFor(id) ?? 'friend')
            .toList();
        if (names.length == 1) {
          return 'Auto-paying ${names.first} when you owe them.';
        }
        if (names.length <= 3) {
          return 'Auto-paying ${names.join(', ')} when you owe them.';
        }
        return 'Auto-paying ${names.length} friends when you owe them.';
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
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

  Future<void> _onAutoPayToggle(bool turningOn) async {
    if (_autoPayBusy) return;
    if (!turningOn) {
      final ok = await _confirm(
        title: 'Disable Auto-Settle?',
        message: "Future IOUs won't be auto-paid until you turn this back on.",
        confirmLabel: 'Disable',
      );
      if (!ok) return;
      await AutoPayService.instance.save(const AutoPaySettings.off());
      if (!mounted) return;
      setState(() => _autoPay = const AutoPaySettings.off());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Auto-Settle disabled.')));
      return;
    }

    setState(() => _autoPayBusy = true);
    try {
      await _runEnableFlow();
    } finally {
      if (mounted) setState(() => _autoPayBusy = false);
    }
  }

  Future<void> _runEnableFlow() async {
    final scopeChoice = await showModalBottomSheet<_ScopeChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScopePickerSheet(auth: _auth),
    );
    if (!mounted || scopeChoice == null) return;

    List<Map<String, dynamic>> ledgers;
    try {
      final raw = await _auth.fetchLedgers();
      ledgers = raw.cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      _snack('Could not load ledgers: ${e.message}');
      return;
    } catch (e) {
      _snack('Network error loading ledgers.');
      return;
    }

    final inScope = <Map<String, dynamic>>[];
    for (final l in ledgers) {
      final num bal = (l['balance'] ?? 0) as num;
      if (bal >= 0) continue;
      final other = (l['other_user'] as Map?) ?? {};
      final id = other['id'] as String?;
      if (scopeChoice.scope == AutoPayScope.friends &&
          (id == null || !scopeChoice.friendIds.contains(id))) {
        continue;
      }
      inScope.add({
        'ledger_id': l['ledger_id'],
        'friend_id': id,
        'friend_name':
            (other['full_name'] as String?) ??
            ((other['username'] as String?) != null
                ? '@${other['username']}'
                : 'Unknown'),
        'debt': bal.abs().toDouble(),
      });
    }

    if (!mounted) return;
    final scopeLabel = scopeChoice.scope == AutoPayScope.all
        ? 'Auto-Settle ALL'
        : (scopeChoice.friendIds.length == 1
              ? 'Auto-Settle ${scopeChoice.friendNames[scopeChoice.friendIds.first] ?? "friend"}'
              : 'Auto-Settle ${scopeChoice.friendIds.length} friends');
    final previewOk = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DebtPreviewSheet(scopeLabel: scopeLabel, debts: inScope),
    );
    if (!mounted || previewOk != true) return;

    final total = inScope.fold<double>(
      0,
      (sum, e) => sum + (e['debt'] as double),
    );

    if (inScope.isNotEmpty) {
      final confirmed = await _confirm(
        title: 'Confirm Auto-Pay',
        message:
            'Auto-pay \$${total.toStringAsFixed(2)} across ${inScope.length} '
            'ledger${inScope.length == 1 ? '' : 's'} via XRPL? '
            'This cannot be undone.',
        confirmLabel: 'Pay now',
      );
      if (!mounted || !confirmed) return;
      await _runBatch(inScope);
      if (!mounted) return;
    }

    final newSettings = scopeChoice.scope == AutoPayScope.all
        ? const AutoPaySettings.all()
        : AutoPaySettings.friends(
            scopeChoice.friendIds,
            scopeChoice.friendNames,
          );
    await AutoPayService.instance.save(newSettings);
    if (!mounted) return;
    setState(() => _autoPay = newSettings);

    if (inScope.isEmpty) {
      _snack('Auto-Settle enabled. Future IOUs in this scope will auto-pay.');
    }
  }

  Future<void> _runBatch(List<Map<String, dynamic>> debts) async {
    // XRPL Batch caps inner transactions at 8. If the user owes more than
    // 8 people, fan out into chunks of 8 — each chunk is its own atomic
    // ALLORNOTHING batch so partial chunks failing won't undo the ones
    // that already succeeded.
    const int maxPerBatch = 8;
    final chunks = <List<Map<String, dynamic>>>[];
    for (var i = 0; i < debts.length; i += maxPerBatch) {
      chunks.add(debts.sublist(i, (i + maxPerBatch).clamp(0, debts.length)));
    }

    final total = debts.length;
    final progress = ValueNotifier<AutoPayProgress>(
      AutoPayProgress(
        friendName: debts.first['friend_name'] as String,
        amount: debts.first['debt'] as double,
        status: chunks.length == 1
            ? 'Submitting XRPL Batch (1 tx, $total payments)...'
            : 'Submitting batch 1 of ${chunks.length}...',
      ),
    );

    final overlayCtx = context;
    Navigator.push(
      overlayCtx,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => AutoPayOverlay(progress: progress),
      ),
    );

    int settledCount = 0;
    double settledAmount = 0;
    final failures = <String>[];
    String? lastTxHash;

    for (var c = 0; c < chunks.length; c++) {
      final chunk = chunks[c];
      final chunkTotal = chunk.fold<double>(
        0,
        (a, b) => a + (b['debt'] as double),
      );
      progress.value = AutoPayProgress(
        friendName: chunks.length == 1
            ? '${chunk.length} recipient${chunk.length == 1 ? '' : 's'}'
            : 'Batch ${c + 1} of ${chunks.length}',
        amount: chunkTotal,
        status:
            'Submitting XRPL Batch '
            '(${c + 1}/${chunks.length}, ${chunk.length} payments)...',
      );

      try {
        final result = await _auth.settleBatch(
          items: chunk
              .map((d) => {'ledger_id': d['ledger_id'], 'amount': d['debt']})
              .toList(),
          mode: 'ALLORNOTHING',
        );
        // ALLORNOTHING means every settlement in this chunk landed.
        settledCount += chunk.length;
        settledAmount += chunkTotal;
        lastTxHash = (result['tx_hash'] as String?) ?? lastTxHash;
      } on ApiException catch (e) {
        failures.add('Batch ${c + 1}: ${e.message}');
      } catch (e) {
        failures.add('Batch ${c + 1}: $e');
      }
    }

    if (mounted) Navigator.of(overlayCtx).pop();
    progress.dispose();

    if (!mounted) return;
    if (failures.isEmpty) {
      final hashSuffix = lastTxHash != null
          ? ' (tx ${lastTxHash.substring(0, 8)}…)'
          : '';
      _snack(
        'Auto-paid \$${settledAmount.toStringAsFixed(2)} across '
        '$settledCount ledger${settledCount == 1 ? '' : 's'} '
        'in ${chunks.length} XRPL Batch tx'
        '${chunks.length == 1 ? '' : 's'}$hashSuffix.',
      );
    } else {
      _snack(
        'Settled $settledCount of $total. '
        '${failures.first}${failures.length > 1 ? '…' : ''}',
      );
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final fullName = (profileData?['profile']?['full_name'] as String?) ?? '';
    final username = (profileData?['profile']?['username'] as String?) ?? '';
    final balanceUsd = profileData?['xrpl']?['balance_usd'] ?? 0;
    final balanceText = '\$${balanceUsd.toString()}';
    final score = profileData?['profile']?['accountability_score'] ?? 0;
    final avatarB64 = profileData?['profile']?['avatar_base64'] as String?;
    final Uint8List? avatarBytes = (avatarB64 != null && avatarB64.isNotEmpty)
        ? _tryDecode(avatarB64)
        : null;
    final initial = (fullName.isNotEmpty ? fullName[0] : 'A').toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                        ),
                        image: avatarBytes != null
                            ? DecorationImage(
                                image: MemoryImage(avatarBytes),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: avatarBytes == null
                          ? Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SettingsSheet(),
                    );
                    if (!mounted) return;
                    await _loadProfile();
                    await _loadMemories();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.settings, color: Colors.white70),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "AUTO-SETTLE BALANCE",
              style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balanceText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "We'll automatically pay your debts when possible.",
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Auto-Settle Enabled",
                        style: TextStyle(color: Colors.white),
                      ),
                      _autoPayBusy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF7F8CFF),
                              ),
                            )
                          : Switch(
                              value: _autoPay.isOn,
                              onChanged: (v) => _onAutoPayToggle(v),
                              activeColor: const Color(0xFF7F8CFF),
                            ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _autoPay.isOn ? Icons.flash_on : Icons.flash_off,
                          color: _autoPay.isOn
                              ? Colors.lightBlueAccent
                              : Colors.white54,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _scopeLabel(_autoPay),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddFundsSheet(),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "+ Add Funds",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "ACCOUNTABILITY SCORE",
              style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      "",
                      style: TextStyle(color: Colors.lightBlueAccent),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "MEMORIES",
                  style:
                      TextStyle(color: Colors.white54, letterSpacing: 1.5),
                ),
                if (_memories.isNotEmpty)
                  Text(
                    "${_memories.length} on XRPL",
                    style: const TextStyle(
                      color: Colors.white38,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (_memories.isEmpty)
              _emptyMemories()
            else
              Column(
                children: [
                  for (final m in _memories.take(8))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _memoryCard(m),
                    ),
                ],
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Uint8List? _tryDecode(String b64) {
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Widget _emptyMemories() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: Color(0xFF7F8CFF),
            size: 28,
          ),
          const SizedBox(height: 10),
          const Text(
            'No memories yet',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Forgive a friend's debt and mint a memory NFT to "
            'commemorate it on the XRPL.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _memoryCard(Map<String, dynamic> memory) {
    final direction = (memory['direction'] as String?) ?? 'received';
    final issued = direction == 'issued';
    final issuer = (memory['issuer'] as Map?) ?? const {};
    final recipient = (memory['recipient'] as Map?) ?? const {};
    final counterpart = issued ? recipient : issuer;
    final counterpartName =
        (counterpart['full_name'] as String?)?.trim().isNotEmpty == true
            ? counterpart['full_name'] as String
            : ((counterpart['username'] as String?) != null
                ? '@${counterpart['username']}'
                : 'someone');
    final amount = (memory['amount'] as num?)?.toDouble() ?? 0;
    final message = (memory['message'] as String?)?.trim() ?? '';
    final nftId = (memory['nft_id'] as String?) ?? '';
    final nftShort = nftId.length >= 12
        ? '${nftId.substring(0, 8)}…${nftId.substring(nftId.length - 4)}'
        : nftId;
    final createdAt = memory['created_at'] as String?;
    final dateLabel = _shortDate(createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: issued
              ? const Color(0xFF7F8CFF).withOpacity(0.4)
              : const Color(0xFF22C55E).withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: issued
                        ? const [Color(0xFF5B6CFF), Color(0xFF7F8CFF)]
                        : const [Color(0xFF22C55E), Color(0xFF4ADE80)],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issued
                          ? 'You forgave $counterpartName'
                          : '$counterpartName forgave you',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${amount.toStringAsFixed(2)}'
                      '${dateLabel.isNotEmpty ? ' · $dateLabel' : ''}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: issued
                      ? const Color(0xFF7F8CFF).withOpacity(0.18)
                      : const Color(0xFF22C55E).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  issued ? 'ISSUED' : 'RECEIVED',
                  style: TextStyle(
                    color: issued
                        ? const Color(0xFF7F8CFF)
                        : const Color(0xFF22C55E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"$message"',
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (nftId.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.link,
                  color: Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'NFT $nftShort',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = dt.toLocal();
    return '${months[local.month - 1]} ${local.day}';
  }
}

class _ScopeChoice {
  final AutoPayScope scope;
  final List<String> friendIds;
  final Map<String, String> friendNames;
  const _ScopeChoice.all()
    : scope = AutoPayScope.all,
      friendIds = const [],
      friendNames = const {};
  const _ScopeChoice.friends(this.friendIds, this.friendNames)
    : scope = AutoPayScope.friends;
}

class _ScopePickerSheet extends StatefulWidget {
  final AuthService auth;
  const _ScopePickerSheet({required this.auth});

  @override
  State<_ScopePickerSheet> createState() => _ScopePickerSheetState();
}

class _ScopePickerSheetState extends State<_ScopePickerSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _contacts = [];
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await widget.auth.fetchLedgers();
      if (!mounted) return;
      final mapped = <Map<String, dynamic>>[];
      for (final l in raw.cast<Map<String, dynamic>>()) {
        final other = (l['other_user'] as Map?) ?? {};
        final id = other['id'] as String?;
        if (id == null) continue;
        mapped.add({
          'id': id,
          'name':
              (other['full_name'] as String?) ??
              ((other['username'] as String?) != null
                  ? '@${other['username']}'
                  : 'Unknown'),
        });
      }
      setState(() {
        _contacts = mapped;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load contacts.';
        _loading = false;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.toList();
    final names = <String, String>{
      for (final c in _contacts)
        if (_selectedIds.contains(c['id']))
          c['id'] as String: c['name'] as String,
    };
    Navigator.pop(context, _ScopeChoice.friends(ids, names));
  }

  @override
  Widget build(BuildContext context) {
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
              'Who should we auto-pay?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Auto-pay everyone, or pick the specific friends you want covered.',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () => Navigator.pop(context, const _ScopeChoice.all()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Auto-Settle ALL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Or pick specific friends',
                  style: TextStyle(color: Colors.white54),
                ),
                if (_contacts.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      if (_selectedIds.length == _contacts.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds
                          ..clear()
                          ..addAll(_contacts.map((c) => c['id'] as String));
                      }
                    }),
                    child: Text(
                      _selectedIds.length == _contacts.length
                          ? 'Clear all'
                          : 'Select all',
                      style: const TextStyle(color: Color(0xFF7F8CFF)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF7F8CFF)),
                ),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4)))
            else if (_contacts.isEmpty)
              const Text(
                'No friends with ledgers yet.',
                style: TextStyle(color: Colors.white54),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _contacts.length,
                    itemBuilder: (_, i) {
                      final c = _contacts[i];
                      final id = c['id'] as String;
                      final selected = _selectedIds.contains(id);
                      return InkWell(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedIds.remove(id);
                          } else {
                            _selectedIds.add(id);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selected,
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selectedIds.add(id);
                                  } else {
                                    _selectedIds.remove(id);
                                  }
                                }),
                                activeColor: const Color(0xFF7F8CFF),
                                checkColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                              Expanded(
                                child: Text(
                                  c['name'] as String,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectedIds.isEmpty ? null : _confirmSelection,
                    child: Opacity(
                      opacity: _selectedIds.isEmpty ? 0.4 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _selectedIds.isEmpty
                              ? 'Use selected'
                              : 'Use ${_selectedIds.length} friend${_selectedIds.length == 1 ? '' : 's'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtPreviewSheet extends StatelessWidget {
  final String scopeLabel;
  final List<Map<String, dynamic>> debts;

  const _DebtPreviewSheet({required this.scopeLabel, required this.debts});

  @override
  Widget build(BuildContext context) {
    final total = debts.fold<double>(
      0,
      (sum, e) => sum + (e['debt'] as double),
    );
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
            Text(
              scopeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              debts.isEmpty
                  ? "You don't owe anyone in this scope right now."
                  : 'Review what will be auto-paid:',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 16),
            if (debts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Nothing to pay now. Auto-Settle will activate for future IOUs.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: debts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = debts[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              d['friend_name'] as String,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Text(
                            '-\$${(d['debt'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFFFB4B4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (debts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.white60)),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        debts.isEmpty ? 'Save preference' : 'Continue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
