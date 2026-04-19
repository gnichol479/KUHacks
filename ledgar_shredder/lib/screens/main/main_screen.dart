import 'package:flutter/material.dart';
import 'new_ledgar.dart';
import '../people/people_list.dart';
import '../scan/scan_screen.dart';
import '../profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  int currentIndex = 0;

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
  }

  @override
  void dispose() {
    bounceController.dispose();
    rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
  _HomeContent(
    bounceAnimation: bounceAnimation,
    rotateController: rotateController,
  ),
  const PeopleListScreen(),
  const ScanScreen(), // ✅ THIS IS NEW
  const ProfilePage(),
  const Center(child: Text("Profile", style: TextStyle(color: Colors.white))),
];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: const Color(0xFF111827),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, 0),
            _navItem(Icons.people, 1),
            _navItem(Icons.camera_alt, 2),
            _navItem(Icons.person, 3),
          ],
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

class _HomeContent extends StatelessWidget {
  final Animation<double> bounceAnimation;
  final AnimationController rotateController;

  const _HomeContent({
    required this.bounceAnimation,
    required this.rotateController,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome back", style: TextStyle(color: Colors.white60)),
                    SizedBox(height: 4),
                    Text(
                      "Your Ledger",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.flutter_dash, color: Colors.white38),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("NET BALANCE", style: TextStyle(color: Colors.white54)),
                  SizedBox(height: 10),
                  Text("+\$133.00",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BalanceMini(title: "You Owe", amount: "\$82.00"),
                      BalanceMini(title: "Owed to You", amount: "\$215.00"),
                    ],
                  )
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
                    value: "\$40",
                    icon: AnimatedBuilder(
                      animation: bounceAnimation,
                      builder: (_, child) {
                        return Transform.translate(
                          offset: Offset(0, bounceAnimation.value),
                          child: child,
                        );
                      },
                      child: const Icon(Icons.flash_on,
                          color: Colors.lightBlueAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionCard(
                    title: "Optimized",
                    value: "Pay Sarah",
                    icon: RotationTransition(
                      turns: rotateController,
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.purpleAccent),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Add Ledger
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const NewLedgerSheet(),
                );
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
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "ACTIVE BALANCES",
              style: TextStyle(color: Colors.white54, letterSpacing: 1.5),
            ),

            const SizedBox(height: 12),

            const BalanceItem(
                name: "Sarah Chen",
                subtitle: "You owe",
                amount: "-\$45",
                positive: false),
            const BalanceItem(
                name: "Marcus Rivera",
                subtitle: "They owe you",
                amount: "+\$120",
                positive: true),
            const BalanceItem(
                name: "Emily Zhang",
                subtitle: "You owe",
                amount: "-\$22",
                positive: false),

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
        Text(amount,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
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
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }
}

class BalanceItem extends StatelessWidget {
  final String name;
  final String subtitle;
  final String amount;
  final bool positive;

  const BalanceItem({
    super.key,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: positive ? Colors.lightBlueAccent : Colors.purpleAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }
}