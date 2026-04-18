import 'package:flutter/material.dart';

class NewLedgerSheet extends StatefulWidget {
  const NewLedgerSheet({super.key});

  @override
  State<NewLedgerSheet> createState() => _NewLedgerSheetState();
}

class _NewLedgerSheetState extends State<NewLedgerSheet> {
  final TextEditingController whoController =
      TextEditingController(text: "Sarah Chen");
  final TextEditingController descController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  bool theyOweMe = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 🔥 THIS makes it move up with keyboard
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
              // drag handle
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

              // WHO
              _inputField(
                label: "Who",
                controller: whoController,
              ),

              const SizedBox(height: 16),

              // DESCRIPTION
              _inputField(
                label: "Description",
                hint: "e.g. Dinner, Uber",
                controller: descController,
              ),

              const SizedBox(height: 16),

              // AMOUNT
              _inputField(
                label: "Amount",
                hint: "\$0.00",
                controller: amountController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              // TOGGLE BUTTONS
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

              // ADD BUTTON
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
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
                    "Add IOU",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  // 🔹 INPUT FIELD (inline so you don’t need separate file)
  Widget _inputField({
    required String label,
    String? hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
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