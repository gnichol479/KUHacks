import 'package:flutter/material.dart';
import 'new_ledger.dart';
import '../people/people_list.dart';
import '../people/friend_screen.dart';
import '../groups/group_screen.dart';
import '../profile/profile_page.dart';
import '../../services/auth_service.dart';
import '../../widgets/person_tile.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int currentIndex = 0;
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  late AnimationController bounceController;
  late Animation<double> bounceAnimation;

  late AnimationController rotateController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;

    bounceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    bounceAnimation = Tween<double>(begin: -4, end: 6).animate(
      CurvedAnimation(parent: bounceController, curve: Curves.easeInOut),
    );

    rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    AuthService()
        .fetchProfile()
        .then((data) {
          if (!mounted) return;
          setState(() {
            profileData = data;
            isLoading = false;
          });
        })
        .catchError((Object e) {
          debugPrint('PROFILE ERROR: $e');
          if (!mounted) return;
          setState(() => isLoading = false);
        });
  }

  @override
  void dispose() {
    bounceController.dispose();
    rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (profileData?['profile']?['full_name'] as String?) ?? '';

    final screens = [
      _HomeContent(
        bounceAnimation: bounceAnimation,
        rotateController: rotateController,
        fullName: fullName,
      ),
      const PeopleListScreen(),
      const ProfilePage(),
    ];

    final safeIndex = currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: screens[safeIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: const Color(0xFF111827),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, 0),
              _navItem(Icons.people, 1),
              _navItem(Icons.person, 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: Icon(
        icon,
        size: 26,
        color: isSelected ? Colors.blueAccent : Colors.white54,
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final Animation<double> bounceAnimation;
  final AnimationController rotateController;
  final String fullName;

  const _HomeContent({
    required this.bounceAnimation,
    required this.rotateController,
    required this.fullName,
  });

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  double _youOwe = 0;
  double _owedToYou = 0;

  @override
  void initState() {
    super.initState();
    _load();
    // Refetch whenever any other screen mutates a ledger/group/request.
    peopleListReloadKey.addListener(_load);
  }

  @override
  void dispose() {
    peopleListReloadKey.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final ledgers = await _auth.fetchLedgers();
      final groups = await _auth.fetchGroups();
      if (!mounted) return;

      final rows = <Map<String, dynamic>>[];
      double owe = 0;
      double owed = 0;
      for (final raw in ledgers.cast<Map<String, dynamic>>()) {
        final other = (raw['other_user'] as Map?) ?? {};
        final bal = ((raw['balance'] ?? 0) as num).toDouble();
        final positive = bal >= 0;
        final absAmt = bal.abs();
        final fullName = other['full_name'] as String?;
        final username = other['username'] as String?;
        rows.add(<String, dynamic>{
          'kind': 'ledger',
          'name': (fullName != null && fullName.isNotEmpty)
              ? fullName
              : '@${username ?? 'unknown'}',
          'subtitle': bal == 0
              ? 'Settled'
              : positive
                  ? 'They owe you \$${absAmt.toStringAsFixed(0)}'
                  : 'You owe \$${absAmt.toStringAsFixed(0)}',
          'amount': bal == 0
              ? '\$0'
              : '${positive ? '+' : '-'}\$${absAmt.toStringAsFixed(0)}',
          'positive': positive,
          'ledger_id': raw['ledger_id'],
          'accountability_score':
              (other['accountability_score'] as num?)?.toInt(),
          'avatar_base64': other['avatar_base64'] as String?,
          '_balance': bal,
        });
        if (bal > 0) {
          owed += bal;
        } else if (bal < 0) {
          owe += -bal;
        }
      }

      for (final g in groups.cast<Map<String, dynamic>>()) {
        final bal = ((g['balance'] ?? 0) as num).toDouble();
        final memberCount = (g['member_count'] as num?)?.toInt() ?? 0;
        final positive = bal >= 0;
        final absAmt = bal.abs();
        // Only surface groups in active balances when there's actually
        // money in motion — settled groups stay out of the home list.
        if (bal != 0) {
          rows.add(<String, dynamic>{
            'kind': 'group',
            'name': (g['name'] as String?) ?? 'Group',
            'subtitle': positive
                ? '$memberCount members • You are owed \$${absAmt.toStringAsFixed(0)}'
                : '$memberCount members • You owe \$${absAmt.toStringAsFixed(0)}',
            'amount':
                '${positive ? '+' : '-'}\$${absAmt.toStringAsFixed(0)}',
            'positive': positive,
            'group_id': g['group_id'],
            'accountability_score': null,
            'avatar_base64': null,
            '_balance': bal,
          });
        }
        if (bal > 0) {
          owed += bal;
        } else if (bal < 0) {
          owe += -bal;
        }
      }

      rows.sort(
        (a, b) => (b['_balance'] as double)
            .abs()
            .compareTo((a['_balance'] as double).abs()),
      );

      if (!mounted) return;
      setState(() {
        _items = rows;
        _youOwe = owe;
        _owedToYou = owed;
        _loading = false;
      });
    } catch (e) {
      debugPrint('HOME load error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _money(double v) => '\$${v.abs().toStringAsFixed(0)}';

  String _signed(double v) => v == 0
      ? '\$0'
      : '${v >= 0 ? '+' : '-'}\$${v.abs().toStringAsFixed(0)}';

  String _firstWord(String s) {
    final t = s.trim();
    if (t.isEmpty) return 'them';
    // Strip a leading @ for @username display so the action card reads
    // "Pay alex" instead of "Pay @alex".
    final cleaned = t.startsWith('@') ? t.substring(1) : t;
    final space = cleaned.indexOf(' ');
    return space == -1 ? cleaned : cleaned.substring(0, space);
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.fullName;
    final net = _owedToYou - _youOwe;
    final topDebt = _items.firstWhere(
      (it) => !(it['positive'] as bool) && (it['_balance'] as double) < 0,
      orElse: () => const <String, dynamic>{},
    );
    final optimizedValue = topDebt.isEmpty
        ? 'All settled'
        : 'Pay ${_firstWord(topDebt['name'] as String)}';
    final visibleItems = _items.take(5).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 10),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome back",
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullName.isNotEmpty ? fullName : "Your Ledger",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.flutter_dash, color: Colors.white38),
              ],
            ),

            const SizedBox(height: 20),

            // Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2F4F), Color(0xFF1F243C)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "NET BALANCE",
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _signed(net),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BalanceMini(
                        title: "You Owe",
                        amount: _money(_youOwe),
                      ),
                      BalanceMini(
                        title: "Owed to You",
                        amount: _money(_owedToYou),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Cards
            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    title: "Auto-Settle",
                    value: _money(_youOwe),
                    icon: AnimatedBuilder(
                      animation: widget.bounceAnimation,
                      builder: (_, child) {
                        return Transform.translate(
                          offset: Offset(0, widget.bounceAnimation.value),
                          child: child,
                        );
                      },
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionCard(
                    title: "Optimized",
                    value: optimizedValue,
                    icon: RotationTransition(
                      turns: widget.rotateController,
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Add Ledger
            GestureDetector(
              onTap: () async {
                final result =
                    await showModalBottomSheet<Map<String, dynamic>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const NewLedgerSheet(),
                );
                debugPrint('NEW IOU result=$result');
                if (result != null) {
                  peopleListReloadKey.value++;
                  if (context.mounted) {
                    final friend = result['friend'] as Map?;
                    final name = (friend?['full_name'] as String?) ??
                        ((friend?['username'] as String?) != null
                            ? '@${friend!['username']}'
                            : 'them');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Request sent — waiting on $name to accept.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Add Ledger",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "ACTIVE BALANCES",
              style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
            ),

            const SizedBox(height: 12),

            if (_loading && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'No active balances',
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
                    for (int i = 0; i < visibleItems.length; i++) ...[
                      PersonTile(
                        name: visibleItems[i]['name'] as String,
                        subtitle: visibleItems[i]['subtitle'] as String,
                        amount: visibleItems[i]['amount'] as String,
                        positive: visibleItems[i]['positive'] as bool,
                        accountabilityScore:
                            (visibleItems[i]['accountability_score']
                                    as num?)
                                ?.toInt(),
                        avatarBase64:
                            visibleItems[i]['avatar_base64'] as String?,
                        onTap: () async {
                          final item = visibleItems[i];
                          final kind = item['kind'] as String? ?? 'ledger';
                          if (kind == 'group') {
                            final groupId = item['group_id'] as String?;
                            if (groupId == null) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupScreen(
                                  groupId: groupId,
                                  initialName: item['name'] as String,
                                ),
                              ),
                            );
                          } else {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FriendScreen(
                                  name: item['name'] as String,
                                  net: item['amount'] as String,
                                  isNegative: !(item['positive'] as bool),
                                  ledgerId: item['ledger_id'] as String?,
                                ),
                              ),
                            );
                          }
                          if (mounted) await _load();
                        },
                      ),
                      if (i != visibleItems.length - 1)
                        const Divider(color: Colors.white10),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class BalanceMini extends StatelessWidget {
  final String title;
  final String amount;

  const BalanceMini({super.key, required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final String value;
  final Widget icon;

  const ActionCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

