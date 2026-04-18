import 'package:flutter/material.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {

  String selectedTheme = "dark";
  String selectedColor = "blue";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 16),

              // HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Appearance",
                    style: TextStyle(
                      color: Color(0xFFEDEFF3),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= THEME =================
              _sectionTitle("THEME"),

              _card([
                _themeTile("dark", "Dark"),
                _divider(),
                _themeTile("light", "Light"),
                _divider(),
                _themeTile("auto", "Auto"),
              ]),

              const SizedBox(height: 20),

              // ================= ACCENT COLOR =================
              _sectionTitle("ACCENT COLOR"),

              Row(
                children: [
                  Expanded(child: _colorTile("blue", Colors.blue, "Blue")),
                  const SizedBox(width: 12),
                  Expanded(child: _colorTile("purple", Colors.purple, "Purple")),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _colorTile("cyan", Colors.cyan, "Cyan")),
                  const SizedBox(width: 12),
                  Expanded(child: _colorTile("green", Colors.green, "Green")),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ================= THEME TILE =================
  Widget _themeTile(String value, String label) {
    bool selected = selectedTheme == value;

    return ListTile(
      onTap: () {
        setState(() {
          selectedTheme = value;
        });

        // TODO: connect to global theme system
      },
      leading: const Icon(Icons.dark_mode, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF4F6EF7))
          : null,
    );
  }

  // ================= COLOR TILE =================
  Widget _colorTile(String value, Color color, String label) {
    bool selected = selectedColor == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = value;
        });

        // TODO: connect to theme accent system
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF4F6EF7)
                : const Color(0xFF2A2F3A),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9AA0A6),
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2F3A)),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      color: Color(0xFF222633),
    );
  }
}