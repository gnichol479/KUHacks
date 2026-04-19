import 'package:flutter/material.dart';
import 'screens/auth/auth_entry_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthService();
  Widget startWidget = const AuthScreen();

  if (await auth.isLoggedIn()) {
    try {
      final profile = await auth.fetchProfile();
      final completed =
          (profile['profile']?['onboarding_completed'] ?? false) == true;
      startWidget = completed ? const MainScreen() : const OnboardingScreen();
    } catch (_) {
      // Token expired / network down — fall back to the auth entry screen.
      await auth.logout();
      startWidget = const AuthScreen();
    }
  }

  runApp(LedgerShredderApp(home: startWidget));
}

class LedgerShredderApp extends StatelessWidget {
  final Widget home;

  const LedgerShredderApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: home,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F1A),
      ),
    );
  }
}
