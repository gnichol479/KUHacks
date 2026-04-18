import 'package:flutter/material.dart';

class BankPage extends StatelessWidget {
  const BankPage({super.key});

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
                    "Bank & Wallet",
                    style: TextStyle(
                      color: Color(0xFFEDEFF3),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SECTION TITLE
              const Text(
                "CONNECTED ACCOUNTS",
                style: TextStyle(
                  color: Color(0xFF9AA0A6),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              // ACCOUNT LIST
              _accountCard(
                title: "Chase Checking",
                subtitle: "•••• 4829 • Primary",
                icon: Icons.account_balance,
              ),

              const SizedBox(height: 12),

              _accountCard(
                title: "Visa",
                subtitle: "•••• 1234",
                icon: Icons.credit_card,
              ),

              const SizedBox(height: 16),

              // ADD PAYMENT BUTTON
              GestureDetector(
                onTap: () {
                  _showAddPayment(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2A2F3A)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      "Add Payment Method",
                      style: TextStyle(
                        color: Color(0xFF9AA0A6),
                        fontWeight: FontWeight.w600,
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

  // ================= ACCOUNT CARD =================
  Widget _accountCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2F3A)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2F3A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFEDEFF3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9AA0A6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  // ================= ADD PAYMENT SHEET =================
  void _showAddPayment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D24),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Add Payment Method",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Card Number",
                  hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
                  filled: true,
                  fillColor: const Color(0xFF12141A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "MM/YY",
                  hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
                  filled: true,
                  fillColor: const Color(0xFF12141A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F6EF7),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Add Card"),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}