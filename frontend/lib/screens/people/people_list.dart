import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'add_friend.dart';
import 'friend_screen.dart';
import '../groups/add_group.dart';
import '../groups/group_screen.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_with_score.dart';
import '../../widgets/person_tile.dart';

const List<Map<String, Object>> peopleMockData = [
  {
    'name': 'Sarah Chen',
    'subtitle': 'You owe \$45',
    'amount': '-\$45',
    'positive': false,
  },
  {
    'name': 'Marcus Rivera',
    'subtitle': 'They owe you \$120',
    'amount': '+\$120',
    'positive': true,
  },
  {
    'name': 'Emily Zhang',
    'subtitle': 'You owe \$22',
    'amount': '-\$22',
    'positive': false,
  },
];

/// Bump this anywhere a ledger mutation happens (new IOU, friend accepted,
/// etc.) and the People tab will refetch its ledgers + sent requests on the
/// next frame, even though it's kept alive across bottom-nav switches.
final ValueNotifier<int> peopleListReloadKey = ValueNotifier<int>(0);

enum PeopleTab { people, groups, requests }

enum RequestsSubTab { friend, ledger }

enum LedgerSubTab { received, sent }

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  PeopleTab _activeTab = PeopleTab.people;
  RequestsSubTab _requestsSubTab = RequestsSubTab.friend;
  LedgerSubTab _ledgerSubTab = LedgerSubTab.received;

  final TextEditingController _searchController = TextEditingController();
  final AuthService _auth = AuthService();
  Timer? _debounce;
  Timer? _requestsPoll;
  List<dynamic> _searchResults = [];
  List<dynamic> _ledgers = [];
  List<dynamic> _requests = [];
  List<dynamic> _ledgerReqIncoming = [];
  List<dynamic> _ledgerReqSent = [];
  List<dynamic> _groups = [];
  bool _ledgersLoading = true;
  bool _requestsLoading = true;
  bool _ledgerReqIncomingLoading = true;
  bool _ledgerReqSentLoading = true;
  bool _groupsLoading = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadLedgers();
    _loadRequests();
    _loadLedgerReqIncoming();
    _loadLedgerReqSent();
    _loadGroups();
    peopleListReloadKey.addListener(_handleExternalReload);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _requestsPoll?.cancel();
    _searchController.dispose();
    peopleListReloadKey.removeListener(_handleExternalReload);
    super.dispose();
  }

  void _handleExternalReload() {
    if (!mounted) return;
    _loadLedgers();
    _loadRequests();
    _loadLedgerReqIncoming();
    _loadLedgerReqSent();
    _loadGroups();
  }

  void _switchTab(PeopleTab tab) {
    setState(() => _activeTab = tab);
    if (tab == PeopleTab.requests) {
      _loadRequests();
      _loadLedgerReqIncoming();
      _loadLedgerReqSent();
      _startRequestsPolling();
    } else {
      _stopRequestsPolling();
      if (tab == PeopleTab.people) {
        _loadLedgers();
      } else if (tab == PeopleTab.groups) {
        _loadGroups();
      }
    }
  }

  void _startRequestsPolling() {
    _requestsPoll?.cancel();
    _requestsPoll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _activeTab != PeopleTab.requests) return;
      _loadRequests();
      _loadLedgerReqIncoming();
      _loadLedgerReqSent();
    });
  }

  void _stopRequestsPolling() {
    _requestsPoll?.cancel();
    _requestsPoll = null;
  }

  Future<void> _loadLedgers() async {
    setState(() => _ledgersLoading = true);
    try {
      final data = await _auth.fetchLedgers();
      if (!mounted) return;
      setState(() {
        _ledgers = data;
        _ledgersLoading = false;
      });
    } catch (e) {
      debugPrint('LEDGERS error: $e');
      if (!mounted) return;
      setState(() => _ledgersLoading = false);
    }
  }

  Future<void> _loadGroups() async {
    setState(() => _groupsLoading = true);
    try {
      final data = await _auth.fetchGroups();
      if (!mounted) return;
      setState(() {
        _groups = data;
        _groupsLoading = false;
      });
    } catch (e) {
      debugPrint('GROUPS error: $e');
      if (!mounted) return;
      setState(() => _groupsLoading = false);
    }
  }

  Future<void> _openAddGroupSheet() async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGroupSheet(),
    );
    if (!mounted || res == null) return;
    await _loadGroups();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group created.')),
    );
  }

  Future<void> _loadRequests() async {
    setState(() => _requestsLoading = true);
    try {
      final data = await _auth.fetchRequests();
      if (!mounted) return;
      setState(() {
        _requests = data;
        _requestsLoading = false;
      });
    } catch (e) {
      debugPrint('REQUESTS error: $e');
      if (!mounted) return;
      setState(() => _requestsLoading = false);
      _surfaceFetchError('Requests', e);
    }
  }

  Future<void> _loadLedgerReqIncoming() async {
    setState(() => _ledgerReqIncomingLoading = true);
    try {
      final data = await _auth.fetchEntryRequestsIncoming();
      if (!mounted) return;
      setState(() {
        _ledgerReqIncoming = data;
        _ledgerReqIncomingLoading = false;
      });
    } catch (e) {
      debugPrint('LEDGER REQ INCOMING error: $e');
      if (!mounted) return;
      setState(() => _ledgerReqIncomingLoading = false);
      _surfaceFetchError('Ledger requests', e);
    }
  }

  Future<void> _loadLedgerReqSent() async {
    setState(() => _ledgerReqSentLoading = true);
    try {
      final data = await _auth.fetchEntryRequestsSent();
      if (!mounted) return;
      setState(() {
        _ledgerReqSent = data;
        _ledgerReqSentLoading = false;
      });
    } catch (e) {
      debugPrint('LEDGER REQ SENT error: $e');
      if (!mounted) return;
      setState(() => _ledgerReqSentLoading = false);
      _surfaceFetchError('Ledger requests sent', e);
    }
  }

  Future<void> _handleAcceptEntry(String requestId) async {
    try {
      await _auth.acceptEntryRequest(requestId);
      // Refresh both inboxes (the row is gone) and the People/Groups data
      // since balances just moved.
      await Future.wait([
        _loadLedgerReqIncoming(),
        _loadLedgers(),
        _loadGroups(),
      ]);
      peopleListReloadKey.value++;
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Try again.')),
      );
    }
  }

  Future<void> _handleRejectEntry(String requestId) async {
    try {
      await _auth.rejectEntryRequest(requestId);
      await Future.wait([_loadLedgerReqIncoming(), _loadLedgerReqSent()]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Try again.')),
      );
    }
  }

  /// Debug-only surfacing of silent /contacts/* fetch failures so a stale
  /// deploy or expired token is visible during development instead of an
  /// empty list with no explanation.
  void _surfaceFetchError(String label, Object error) {
    if (!kDebugMode || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final detail = error is ApiException
        ? '${error.statusCode}: ${error.message}'
        : error.toString();
    messenger.showSnackBar(
      SnackBar(content: Text('$label fetch failed — $detail')),
    );
  }

  Future<void> _openAddSheet() async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFriendSheet(),
    );
    if (res == null) return;
    final result = res['result'] as Map<String, dynamic>?;
    if (result != null && isNewPendingAddResult(result)) {
      peopleListReloadKey.value++;
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    try {
      final data = await _auth.searchUsers(q);
      if (!mounted) return;
      setState(() {
        _searchResults = data;
        _searching = false;
      });
    } catch (e) {
      debugPrint('SEARCH error: $e');
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _searching = false;
      });
    }
  }

  Future<void> _handleAddContact(Map<String, dynamic> user) async {
    try {
      final result = await _auth.addContact(user['id'] as String);
      _searchController.clear();
      setState(() => _searchResults = []);
      if (!mounted) return;
      if (isNewPendingAddResult(result)) {
        peopleListReloadKey.value++;
      }
      // Backend creates a pending ledger; the new contact won't appear in the
      // accepted-only ledgers list until the other side accepts.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(addContactSnackText(result))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Try again.')),
      );
    }
  }

  Future<void> _handleAccept(String ledgerId) async {
    try {
      await _auth.acceptRequest(ledgerId);
      await Future.wait([_loadRequests(), _loadLedgers()]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Try again.')),
      );
    }
  }

  Future<void> _handleReject(String ledgerId) async {
    try {
      await _auth.rejectRequest(ledgerId);
      await _loadRequests();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Try again.')),
      );
    }
  }

  // Maps the live `_ledgers` payload into the same shape `_row` already
  // consumes, plus extras (`ledger_id`, `other_user_id`) for navigation.
  List<Map<String, dynamic>> _ledgerItems() {
    return _ledgers.cast<Map<String, dynamic>>().map((l) {
      final other = (l['other_user'] as Map?) ?? {};
      final num bal = (l['balance'] ?? 0) as num;
      final positive = bal >= 0;
      final absAmt = bal.abs();
      final fullName = other['full_name'] as String?;
      final username = other['username'] as String?;
      return <String, dynamic>{
        'name': (fullName != null && fullName.isNotEmpty)
            ? fullName
            : '@${username ?? 'unknown'}',
        'subtitle': positive
            ? 'They owe you \$${absAmt.toStringAsFixed(0)}'
            : 'You owe \$${absAmt.toStringAsFixed(0)}',
        'amount':
            '${positive ? '+' : '-'}\$${absAmt.toStringAsFixed(0)}',
        'positive': positive,
        'ledger_id': l['ledger_id'],
        'other_user_id': other['id'],
        'accountability_score':
            (other['accountability_score'] as num?)?.toInt(),
        'avatar_base64': other['avatar_base64'] as String?,
      };
    }).toList();
  }

  String _titleFor(PeopleTab tab) {
    switch (tab) {
      case PeopleTab.people:
        return 'People';
      case PeopleTab.groups:
        return 'Groups';
      case PeopleTab.requests:
        return 'Requests';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  const SizedBox(height: 10),

              // 🔝 HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _titleFor(_activeTab),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openAddSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.white),
                          SizedBox(width: 6),
                          Text("Add",
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔄 TABS
              Row(
                children: [
                  Expanded(
                    child: _tab(
                      'People',
                      _activeTab == PeopleTab.people,
                      () => _switchTab(PeopleTab.people),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tab(
                      'Groups',
                      _activeTab == PeopleTab.groups,
                      () => _switchTab(PeopleTab.groups),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tab(
                      'Requests',
                      _activeTab == PeopleTab.requests,
                      () => _switchTab(PeopleTab.requests),
                      badgeCount: _requests.length,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ..._buildTabBody(),

              const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          if (_activeTab == PeopleTab.groups)
            Positioned(
              right: 24,
              bottom: 24,
              child: SafeArea(
                child: FloatingActionButton(
                  onPressed: _openAddGroupSheet,
                  backgroundColor: const Color(0xFF5B6CFF),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildTabBody() {
    switch (_activeTab) {
      case PeopleTab.people:
        return _buildPeopleBody();
      case PeopleTab.groups:
        return _buildGroupsBody();
      case PeopleTab.requests:
        return _buildRequestsBody();
    }
  }

  List<Widget> _buildPeopleBody() {
    final activeList = _ledgerItems();
    return [
      // 🔍 SEARCH
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white38),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white70,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
            ),
          ],
        ),
      ),
      if (_searchController.text.trim().isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
          ),
          child: _searching
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _searchResults.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No matches',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : Column(
                      children: [
                        for (final u in _searchResults
                            .cast<Map<String, dynamic>>())
                          ListTile(
                            leading: AvatarWithScore(
                              radius: 20,
                              score: (u['accountability_score'] as num?)
                                  ?.toInt(),
                              avatarBase64:
                                  u['avatar_base64'] as String?,
                              child: Text(
                                _initialFor(
                                  (u['full_name'] as String?) ??
                                      (u['username'] as String?),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              (u['full_name'] as String?) ?? '',
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                            subtitle: Text(
                              '@${u['username'] ?? ''}',
                              style: const TextStyle(
                                  color: Colors.white54),
                            ),
                            trailing: const Icon(
                              Icons.add,
                              color: Colors.lightBlueAccent,
                            ),
                            onTap: () => _handleAddContact(u),
                          ),
                      ],
                    ),
        ),
      ],
      const SizedBox(height: 20),
      if (_ledgersLoading)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: CircularProgressIndicator()),
        )
      else if (activeList.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: const Text(
            'No contacts yet',
            style: TextStyle(color: Colors.white54),
          ),
        )
      else
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              for (int i = 0; i < activeList.length; i++) ...[
                _row(context, activeList[i]),
                if (i != activeList.length - 1)
                  const Divider(color: Colors.white10),
              ]
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildGroupsBody() {
    if (_groupsLoading) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final activeList = _groups.cast<Map<String, dynamic>>();
    if (activeList.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: const Text(
            'No groups yet — tap + to create one',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ];
    }
    return [
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            for (int i = 0; i < activeList.length; i++) ...[
              _groupRow(context, activeList[i]),
              if (i != activeList.length - 1)
                const Divider(color: Colors.white10),
            ]
          ],
        ),
      ),
    ];
  }

  Widget _groupRow(BuildContext context, Map<String, dynamic> group) {
    final name = (group['name'] as String?) ?? 'Group';
    final memberCount = (group['member_count'] as num?)?.toInt() ?? 0;
    final balance = (group['balance'] as num?)?.toDouble() ?? 0.0;
    final positive = balance >= 0;
    final settled = balance == 0;
    final amountText = settled
        ? '\$0'
        : '${positive ? '+' : '-'}\$${balance.abs().toStringAsFixed(0)}';
    final subtitle = settled
        ? '$memberCount members • Settled'
        : positive
            ? '$memberCount members • You are owed \$${balance.toStringAsFixed(0)}'
            : '$memberCount members • You owe \$${balance.abs().toStringAsFixed(0)}';
    return PersonTile(
      name: name,
      subtitle: subtitle,
      amount: amountText,
      positive: positive,
      onTap: () async {
        final groupId = group['group_id'] as String?;
        if (groupId == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupScreen(groupId: groupId, initialName: name),
          ),
        );
        if (!mounted) return;
        await _loadGroups();
      },
    );
  }

  List<Widget> _buildRequestsBody() {
    return [
      _requestsSubTabSelector(),
      const SizedBox(height: 16),
      ..._requestsSubTabBody(),
    ];
  }

  Widget _requestsSubTabSelector() {
    return Row(
      children: [
        Expanded(
          child: _tab(
            'Friend',
            _requestsSubTab == RequestsSubTab.friend,
            () => setState(() => _requestsSubTab = RequestsSubTab.friend),
            badgeCount: _requests.length,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tab(
            'Ledger',
            _requestsSubTab == RequestsSubTab.ledger,
            () => setState(() => _requestsSubTab = RequestsSubTab.ledger),
            badgeCount: _ledgerReqIncoming.length,
          ),
        ),
      ],
    );
  }

  List<Widget> _requestsSubTabBody() {
    if (_requestsSubTab == RequestsSubTab.friend) {
      return [
        _sectionLabel('Incoming friend requests'),
        const SizedBox(height: 10),
        _incomingBlock(),
      ];
    }
    return [
      _ledgerSubTabSelector(),
      const SizedBox(height: 12),
      _ledgerSubTab == LedgerSubTab.received
          ? _ledgerReqIncomingBlock()
          : _ledgerReqSentBlock(),
    ];
  }

  Widget _ledgerSubTabSelector() {
    return Row(
      children: [
        Expanded(
          child: _tab(
            'Received',
            _ledgerSubTab == LedgerSubTab.received,
            () => setState(() => _ledgerSubTab = LedgerSubTab.received),
            badgeCount: _ledgerReqIncoming.length,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tab(
            'Sent',
            _ledgerSubTab == LedgerSubTab.sent,
            () => setState(() => _ledgerSubTab = LedgerSubTab.sent),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _incomingBlock() {
    if (_requestsLoading) {
      return _cardWrap(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_requests.isEmpty) {
      return _cardWrap(
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No incoming requests.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }
    return _cardWrap(
      Column(
        children: [
          for (int i = 0; i < _requests.length; i++) ...[
            _requestRow(_requests[i] as Map<String, dynamic>),
            if (i != _requests.length - 1)
              const Divider(color: Colors.white10),
          ],
        ],
      ),
    );
  }

  Widget _ledgerReqIncomingBlock() {
    if (_ledgerReqIncomingLoading) {
      return _cardWrap(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_ledgerReqIncoming.isEmpty) {
      return _cardWrap(
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No pending ledger requests.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }
    return _cardWrap(
      Column(
        children: [
          for (int i = 0; i < _ledgerReqIncoming.length; i++) ...[
            _ledgerReqIncomingRow(
              _ledgerReqIncoming[i] as Map<String, dynamic>,
            ),
            if (i != _ledgerReqIncoming.length - 1)
              const Divider(color: Colors.white10),
          ],
        ],
      ),
    );
  }

  Widget _ledgerReqSentBlock() {
    if (_ledgerReqSentLoading) {
      return _cardWrap(
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_ledgerReqSent.isEmpty) {
      return _cardWrap(
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "You haven't sent any ledger requests.",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }
    return _cardWrap(
      Column(
        children: [
          for (int i = 0; i < _ledgerReqSent.length; i++) ...[
            _ledgerReqSentRow(_ledgerReqSent[i] as Map<String, dynamic>),
            if (i != _ledgerReqSent.length - 1)
              const Divider(color: Colors.white10),
          ],
        ],
      ),
    );
  }

  Widget _cardWrap(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _tab(
    String text,
    bool selected,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F2937) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B6CFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _requestRow(Map<String, dynamic> r) {
    final from = (r['from_user'] as Map?) ?? {};
    final ledgerId = r['ledger_id'] as String;
    return ListTile(
      leading: AvatarWithScore(
        radius: 20,
        score: (from['accountability_score'] as num?)?.toInt(),
        avatarBase64: from['avatar_base64'] as String?,
        child: Text(
          _initialFor(
            (from['full_name'] as String?) ??
                (from['username'] as String?),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        (from['full_name'] as String?) ?? '',
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        '@${from['username'] ?? ''}',
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _handleAccept(ledgerId),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.lightGreenAccent),
            ),
          ),
          TextButton(
            onPressed: () => _handleReject(ledgerId),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _initialFor(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  String _displayName(Map? user) {
    final fullName = user?['full_name'] as String?;
    final username = user?['username'] as String?;
    if (fullName != null && fullName.isNotEmpty) return fullName;
    if (username != null && username.isNotEmpty) return '@$username';
    return 'Unknown';
  }

  Widget _ledgerReqIncomingRow(Map<String, dynamic> r) {
    final from = (r['from_user'] as Map?) ?? {};
    final id = r['id'] as String;
    final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
    final desc = (r['description'] as String?) ?? '';
    final scope = (r['scope'] as String?) ?? 'ledger';
    final groupName = r['group_name'] as String?;
    // Direction is stored from sender's POV; flip it for the recipient.
    final senderDirection = (r['direction'] as String?) ?? 'i_owe_them';
    final recipientOwes = senderDirection == 'they_owe_me';
    final senderName = _displayName(from);
    final intent = recipientOwes
        ? 'You owe $senderName'
        : '$senderName owes you';
    final scopeLabel = scope == 'group' && groupName != null
        ? ' • $groupName'
        : '';
    return ListTile(
      leading: AvatarWithScore(
        radius: 20,
        score: (from['accountability_score'] as num?)?.toInt(),
        avatarBase64: from['avatar_base64'] as String?,
        child: Text(
          _initialFor(senderName),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        senderName,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        '\$${amount.toStringAsFixed(2)} • $desc\n$intent$scopeLabel',
        style: const TextStyle(color: Colors.white54),
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _handleAcceptEntry(id),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.lightGreenAccent),
            ),
          ),
          TextButton(
            onPressed: () => _handleRejectEntry(id),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ledgerReqSentRow(Map<String, dynamic> r) {
    final to = (r['to_user'] as Map?) ?? {};
    final id = r['id'] as String;
    final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
    final desc = (r['description'] as String?) ?? '';
    final scope = (r['scope'] as String?) ?? 'ledger';
    final groupName = r['group_name'] as String?;
    final scopeLabel = scope == 'group' && groupName != null
        ? ' • $groupName'
        : '';
    return ListTile(
      leading: AvatarWithScore(
        radius: 20,
        score: (to['accountability_score'] as num?)?.toInt(),
        avatarBase64: to['avatar_base64'] as String?,
        child: Text(
          _initialFor(_displayName(to)),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        _displayName(to),
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        '\$${amount.toStringAsFixed(2)} • $desc$scopeLabel\nPending',
        style: const TextStyle(color: Colors.white54),
      ),
      isThreeLine: true,
      trailing: TextButton(
        onPressed: () => _handleRejectEntry(id),
        child: const Text(
          'Cancel',
          style: TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Map item) {
    final positive = item['positive'] as bool;

    return PersonTile(
      name: item['name'] as String,
      subtitle: item['subtitle'] as String,
      amount: item['amount'] as String,
      positive: positive,
      accountabilityScore: (item['accountability_score'] as num?)?.toInt(),
      avatarBase64: item['avatar_base64'] as String?,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FriendScreen(
              name: item['name'] as String,
              net: item['amount'] as String,
              isNegative: !positive,
              ledgerId: item['ledger_id'] as String?,
            ),
          ),
        );
      },
    );
  }
}
