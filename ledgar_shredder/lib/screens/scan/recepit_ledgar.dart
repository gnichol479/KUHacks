import 'package:flutter/material.dart';
import '../main/main_screen.dart';

class RecepitLedgarScreen extends StatefulWidget {
  const RecepitLedgarScreen({super.key});

  @override
  State<RecepitLedgarScreen> createState() => _RecepitLedgarScreenState();
}

class _RecepitLedgarScreenState extends State<RecepitLedgarScreen> {
  final TextEditingController descController =
      TextEditingController(text: "Sushi Dinner — Nobu");
  final TextEditingController amountController =
      TextEditingController(text: "63.75");
  final TextEditingController splitController =
      TextEditingController(text: "Sarah Chen");

  bool iOwe = true;

  void _goBack() {
    Navigator.pop(context);
  }

void _createIOU() {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const MainScreen(initialIndex: 2), // 👈 Scan tab
    ),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 🔙 BACK
              GestureDetector(
                onTap: _goBack,
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                    SizedBox(width: 6),
                    Text(
                      "Back",
                      style:
                          TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // TITLE
              Text(
                "Create IOU",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Review scanned details and confirm",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 30),

              // CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _inputField("Description", descController),

                    const SizedBox(height: 20),

                    _amountField("Amount", amountController),

                    const SizedBox(height: 20),

                    _inputField("Split With", splitController),

                    const SizedBox(height: 20),

                    // 🔥 DIRECTION
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Direction",
                            style: TextStyle(color: Colors.white60)),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _toggleButton(
                                text: "I Owe Them",
                                selected: iOwe,
                                onTap: () =>
                                    setState(() => iOwe = true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _toggleButton(
                                text: "They Owe Me",
                                selected: !iOwe,
                                onTap: () =>
                                    setState(() => iOwe = false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔥 BUTTON
              GestureDetector(
                onTap: _createIOU,
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
                    "Create IOU",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 INPUT
  Widget _inputField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
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

  // 🔹 AMOUNT WITH $
  Widget _amountField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixText: "\$ ",
            prefixStyle:
                const TextStyle(color: Colors.white70),
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

  // 🔹 TOGGLE BUTTON
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
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                )
              : null,
          color: selected ? null : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}