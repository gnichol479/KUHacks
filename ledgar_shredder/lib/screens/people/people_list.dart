import 'package:flutter/material.dart';
import 'add_friend.dart';
import 'friend_screen.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  bool showPeople = true;

  final people = const [
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

  final groups = const [
    {
      'name': 'Lake Trip',
      'subtitle': '4 members • You are owed \$58',
      'amount': '+\$58',
      'positive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeList = showPeople ? people : groups;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
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
                    showPeople ? "People" : "Groups",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

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

              // 🔄 TABS
              Row(
                children: [
                  Expanded(
                    child: _tab("People", showPeople, () {
                      setState(() => showPeople = true);
                    }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tab("Groups", !showPeople, () {
                      setState(() => showPeople = false);
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔍 SEARCH
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

              // 📋 LIST
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

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }

  Widget _row(BuildContext context, Map item) {
    final positive = item['positive'] as bool;

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FriendScreen(
              name: item['name'],
              net: item['amount'],
              isNegative: !positive,
            ),
          ),
        );
      },
      leading: const CircleAvatar(radius: 22),
      title: Text(
        item['name'],
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        item['subtitle'],
        style: const TextStyle(color: Colors.white60),
      ),
      trailing: Text(
        item['amount'],
        style: TextStyle(
          color: positive
              ? Colors.lightBlueAccent
              : Colors.purpleAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}