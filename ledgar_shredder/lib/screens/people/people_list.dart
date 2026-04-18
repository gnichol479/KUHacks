import 'package:flutter/material.dart';
import 'add_friend.dart';
import 'friend_screen.dart';

class PeopleListScreen extends StatelessWidget {
  const PeopleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 10),

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "People",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // ✅ FIXED ADD BUTTON
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddFriendSheet(),
                      );
                    },
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

              // TOGGLE (People / Groups)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Expanded(child: _Tab(selected: true, text: "People")),
                    Expanded(child: _Tab(selected: false, text: "Groups")),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SEARCH
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white38),
                    SizedBox(width: 10),
                    Text(
                      "Search contacts...",
                      style: TextStyle(color: Colors.white38),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const _SectionTitle("ACTIVE"),

              const SizedBox(height: 10),

              _PeopleCard(
                children: const [
                  _PersonRow(
                    name: "Sarah Chen",
                    subtitle: "You owe \$45",
                    amount: "-\$45",
                    positive: false,
                  ),
                  _Divider(),
                  _PersonRow(
                    name: "Marcus Rivera",
                    subtitle: "Owes you \$120",
                    amount: "+\$120",
                    positive: true,
                  ),
                  _Divider(),
                  _PersonRow(
                    name: "Emily Zhang",
                    subtitle: "You owe \$22",
                    amount: "-\$22",
                    positive: false,
                  ),
                  _Divider(),
                  _PersonRow(
                    name: "James Okafor",
                    subtitle: "Owes you \$35",
                    amount: "+\$35",
                    positive: true,
                  ),
                  _Divider(),
                  _PersonRow(
                    name: "Lily Nguyen",
                    subtitle: "Owes you \$45",
                    amount: "+\$45",
                    positive: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const _SectionTitle("SETTLED"),

              const SizedBox(height: 10),

              _PeopleCard(
                children: const [
                  _PersonRow(
                    name: "David Kim",
                    subtitle: "All settled up",
                    amount: "✓",
                    positive: true,
                    isSettled: true,
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final bool selected;
  final String text;

  const _Tab({required this.selected, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1F2937) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _PeopleCard extends StatelessWidget {
  final List<Widget> children;

  const _PeopleCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String amount;
  final bool positive;
  final bool isSettled;

  const _PersonRow({
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.positive,
    this.isSettled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FriendScreen(
              name: name,
              net: amount,
              isNegative: !positive,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),

            Text(
              amount,
              style: TextStyle(
                color: isSettled
                    ? Colors.white54
                    : positive
                        ? Colors.lightBlueAccent
                        : Colors.purpleAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white10,
    );
  }
}