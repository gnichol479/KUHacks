import 'package:flutter/material.dart';
import 'recepit_ledgar.dart'; // next screen

class ReceiptPopup extends StatefulWidget {
  const ReceiptPopup({super.key});

  @override
  State<ReceiptPopup> createState() => _ReceiptPopupState();
}

class _ReceiptPopupState extends State<ReceiptPopup> {
  final TextEditingController descController =
      TextEditingController(text: "Sushi Dinner — Nobu");
  final TextEditingController totalController =
      TextEditingController(text: "127.50");
  final TextEditingController splitController =
      TextEditingController(text: "Sarah Chen");
  final TextEditingController shareController =
      TextEditingController(text: "63.75");

  void _createLedger() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecepitLedgarScreen(),
      ),
    );
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

              // 🔥 AI HEADER
              Row(
                children: const [
                  Icon(Icons.flash_on, color: Colors.lightBlueAccent),
                  SizedBox(width: 8),
                  Text(
                    "AI Auto-filled",
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _input("Description", descController),
              _input("Total", totalController),
              _input("Split with", splitController),
              _input("Your share", shareController),

              const SizedBox(height: 20),

              // 🔥 BUTTON
              GestureDetector(
                onTap: _createLedger,
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
                    "Create Ledger",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔥 TOAST STYLE MESSAGE
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white30),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "Receipt detected! Details filled in.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 INPUT FIELD
  Widget _input(String label, TextEditingController controller) {
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
        const SizedBox(height: 16),
      ],
    );
  }
}