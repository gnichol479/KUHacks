import 'package:flutter/material.dart';
import 'receipt_pop_up.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // TITLE
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Scan Receipt",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CAMERA BOX
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F243C),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      // CORNERS
                      Positioned(
                        top: 20,
                        left: 20,
                        child: _corner(),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Transform.rotate(
                          angle: 1.57,
                          child: _corner(),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Transform.rotate(
                          angle: -1.57,
                          child: _corner(),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Transform.rotate(
                          angle: 3.14,
                          child: _corner(),
                        ),
                      ),

                      // CENTER CONTENT
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.camera_alt,
                                color: Colors.white38, size: 40),
                            SizedBox(height: 10),
                            Text(
                              "Point at a receipt or take a photo",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CAPTURE BUTTON
              GestureDetector(
onTap: () {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ReceiptPopup(),
  );
},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B6CFF), Color(0xFF7F8CFF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Capture",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 CORNER UI
  Widget _corner() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF5B6CFF), width: 3),
          left: BorderSide(color: Color(0xFF5B6CFF), width: 3),
        ),
      ),
    );
  }
}