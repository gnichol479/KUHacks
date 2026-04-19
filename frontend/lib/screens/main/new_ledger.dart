import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_with_score.dart';
import '../../widgets/due_in_picker.dart';

class NewLedgerSheet extends StatefulWidget {
  const NewLedgerSheet({super.key});

  @override
  State<NewLedgerSheet> createState() => _NewLedgerSheetState();
}

class _NewLedgerSheetState extends State<NewLedgerSheet> {
  final TextEditingController descController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();
  final FocusNode _filterFocus = FocusNode();
  final AuthService _auth = AuthService();

  bool theyOweMe = true;
  // Default to 1 week — matches the most common informal IOU horizon and
  // gives the score helper something to react to without forcing the user
  // to think.
  int? _dueInDays = 7;
  bool _loadingContacts = true;
  bool _loadFailed = false;
  bool _picking = false;
  bool _submitting = false;
  bool _scanning = false;
  String _filter = '';
  String? _error;
  List<Map<String, dynamic>> _contacts = [];
  Map<String, dynamic>? _selected;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    descController.dispose();
    amountController.dispose();
    _filterController.dispose();
    _filterFocus.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final raw = await _auth.fetchLedgers();
      if (!mounted) return;
      final mapped = <Map<String, dynamic>>[];
      for (final l in raw.cast<Map<String, dynamic>>()) {
        final other = (l['other_user'] as Map?) ?? {};
        final id = other['id'] as String?;
        if (id == null) continue;
        mapped.add({
          'id': id,
          'ledger_id': l['ledger_id'],
          'full_name': other['full_name'] as String?,
          'username': other['username'] as String?,
          'accountability_score':
              (other['accountability_score'] as num?)?.toInt(),
          'avatar_base64': other['avatar_base64'] as String?,
        });
      }
      setState(() {
        _contacts = mapped;
        _loadingContacts = false;
        _loadFailed = false;
      });
    } catch (e) {
      debugPrint('NEW_LEDGER fetchLedgers error: $e');
      if (!mounted) return;
      setState(() {
        _contacts = [];
        _loadingContacts = false;
        _loadFailed = true;
      });
    }
  }

  String _initialFor(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  void _openPicker() {
    setState(() => _picking = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _filterFocus.requestFocus();
    });
  }

  void _closePicker({bool keepFilter = false}) {
    FocusScope.of(context).unfocus();
    setState(() {
      _picking = false;
      if (!keepFilter) {
        _filter = '';
        _filterController.clear();
      }
    });
  }

  void _choose(Map<String, dynamic> contact) {
    setState(() {
      _selected = contact;
      _picking = false;
      _filter = '';
      _filterController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  String _humanize(ApiException e) {
    switch (e.statusCode) {
      case 404:
        return 'Server is missing this endpoint. Redeploy the backend so /ledgers/<id>/entry-requests exists.';
      case 401:
        return 'Session expired — log in again.';
      case 403:
        return 'You are not part of this ledger anymore.';
      default:
        return e.message;
    }
  }

  void _setError(String? message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  Future<void> _scanReceipt() async {
    if (_scanning) return;
    _setError(null);

    final XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('SCAN pickImage error: $e');
      _setError('Could not open the camera.');
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
        setState(() => _scanning = false);
        _setError("Couldn't read that receipt. Try a clearer photo.");
        return;
      }

      setState(() {
        if (store.isNotEmpty) descController.text = store;
        if (totalNum != null && totalNum > 0) {
          amountController.text = totalNum.toStringAsFixed(2);
        }
        _scanning = false;
      });
    } on ApiException catch (e) {
      debugPrint('SCAN ApiException ${e.statusCode}: ${e.message}');
      if (!mounted) return;
      setState(() => _scanning = false);
      _setError(_humanizeScan(e));
    } catch (e) {
      debugPrint('SCAN error: $e');
      if (!mounted) return;
      setState(() => _scanning = false);
      _setError('Network error while scanning. Try again.');
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

  Future<void> _submit() async {
    _setError(null);

    final selected = _selected;
    if (selected == null) {
      _setError('Pick a friend first.');
      return;
    }
    final ledgerId = selected['ledger_id'] as String?;
    if (ledgerId == null || ledgerId.isEmpty) {
      _setError('Selected friend has no ledger.');
      return;
    }

    final description = descController.text.trim();
    if (description.isEmpty) {
      _setError('Add a description.');
      return;
    }

    final raw = amountController.text
        .trim()
        .replaceAll(r'$', '')
        .replaceAll(',', '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      _setError('Enter an amount greater than 0.');
      return;
    }

    debugPrint(
      'IOU REQUEST ledgerId=$ledgerId amount=$amount theyOweMe=$theyOweMe desc="$description"',
    );

    setState(() => _submitting = true);
    try {
      final request = await _auth.createLedgerEntryRequest(
        ledgerId: ledgerId,
        description: description,
        amount: amount,
        theyOweMe: theyOweMe,
        dueInDays: _dueInDays,
      );
      if (!mounted) return;
      debugPrint('IOU REQUEST result=$request');

      // The other side must accept before the entry actually mutates the
      // ledger balance, so there's nothing to apply locally yet — the
      // People tab will refetch and reflect the change once they accept.
      // Auto-pay used to fire here right after addLedgerEntry; with the
      // request flow that needs to be re-wired on the recipient-accept
      // path (see plan).
      Navigator.pop(context, {
        'friend': selected,
        'request': request,
      });
    } on ApiException catch (e) {
      debugPrint('IOU REQUEST ApiException ${e.statusCode}: ${e.message}');
      if (!mounted) return;
      setState(() => _submitting = false);
      _setError(_humanize(e));
    } catch (e) {
      debugPrint('IOU REQUEST error: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      _setError('Network error. Try again.');
    }
  }

  List<Map<String, dynamic>> _filtered() {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts.where((c) {
      final name = (c['full_name'] as String?)?.toLowerCase() ?? '';
      final user = (c['username'] as String?)?.toLowerCase() ?? '';
      return name.contains(q) || user.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dimSubmit = _selected == null || _submitting;
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

              const Text(
                "New IOU",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text("Who", style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 8),
              _whoBlock(),

              const SizedBox(height: 16),

              _inputField(
                label: "Description",
                hint: "e.g. Dinner, Uber",
                controller: descController,
                onChanged: (_) {
                  if (_error != null) _setError(null);
                },
              ),

              const SizedBox(height: 16),

              _inputField(
                label: "Amount",
                hint: "\$0.00",
                controller: amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  if (_error != null) _setError(null);
                },
              ),

              const SizedBox(height: 12),

              _scanReceiptButton(),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _toggleButton(
                      text: "I Owe Them",
                      selected: !theyOweMe,
                      onTap: () => setState(() => theyOweMe = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _toggleButton(
                      text: "They Owe Me",
                      selected: theyOweMe,
                      onTap: () => setState(() => theyOweMe = true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              DueInPicker(
                selectedDays: _dueInDays,
                onChanged: (v) => setState(() => _dueInDays = v),
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
                      const Icon(Icons.error_outline,
                          color: Color(0xFFFFB4B4), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style:
                              const TextStyle(color: Color(0xFFFFB4B4)),
                        ),
                      ),
                    ],
                  ),
                ),

              Opacity(
                opacity: dimSubmit ? 0.4 : 1.0,
                child: GestureDetector(
                  onTap: _submitting ? null : _submit,
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
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : const Text(
                            "Add IOU",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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

  Widget _whoBlock() {
    if (_picking) return _pickerPanel();
    return _selectorTile();
  }

  Widget _selectorTile() {
    final selected = _selected;
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AvatarWithScore(
              radius: 16,
              score: (selected?['accountability_score'] as num?)?.toInt(),
              avatarBase64: selected?['avatar_base64'] as String?,
              child: Text(
                _initialFor(
                  (selected?['full_name'] as String?) ??
                      (selected?['username'] as String?),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: selected == null
                  ? const Text(
                      'Select a friend',
                      style: TextStyle(color: Colors.white38),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (selected['full_name'] as String?) ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          '@${selected['username'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
            Text(
              selected == null ? '' : 'Change',
              style: const TextStyle(
                color: Color(0xFF7F8CFF),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white38),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _filterController,
                    focusNode: _filterFocus,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white70,
                    onChanged: (v) => setState(() => _filter = v),
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Search your contacts...',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: _closePicker,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          _pickerBody(),
        ],
      ),
    );
  }

  Widget _pickerBody() {
    if (_loadingContacts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadFailed) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "Couldn't load contacts.",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _loadingContacts = true);
                _loadContacts();
              },
              child: const Text(
                'Retry',
                style: TextStyle(color: Color(0xFF7F8CFF)),
              ),
            ),
          ],
        ),
      );
    }
    if (_contacts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No contacts yet — add a friend first.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    final results = _filtered();
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No matches',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: results.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Colors.white10, height: 1),
        itemBuilder: (_, i) {
          final c = results[i];
          return ListTile(
            leading: AvatarWithScore(
              radius: 18,
              score: (c['accountability_score'] as num?)?.toInt(),
              avatarBase64: c['avatar_base64'] as String?,
              child: Text(
                _initialFor(
                  (c['full_name'] as String?) ??
                      (c['username'] as String?),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              (c['full_name'] as String?) ?? '',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '@${c['username'] ?? ''}',
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: () => _choose(c),
          );
        },
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7F8CFF)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt,
                      color: Color(0xFF7F8CFF), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Scan a receipt",
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

  Widget _toggleButton({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F2937) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF7F8CFF)
                : Colors.white24,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: selected ? const Color(0xFF7F8CFF) : Colors.white60,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
