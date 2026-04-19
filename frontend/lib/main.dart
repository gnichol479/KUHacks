import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/auth/auth_entry_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/auth_service.dart';

// Toggle this to false to ship a non-framed build (e.g. App Store / Play
// Store). When true the whole app renders inside a phone outline with the
// device_preview toolbar — handy for screenshots and for showing the UI in
// Cursor next to the code, SwiftUI-canvas style.
const bool kEnableDevicePreview = true;

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

  // device_preview is intended for development only — never enable it in a
  // release build, since it injects an extra MediaQuery + toolbar.
  final useFrame = kEnableDevicePreview && !kReleaseMode;

  runApp(
    useFrame
        ? DevicePreview(
            enabled: true,
            builder: (context) => LedgerShredderApp(home: startWidget),
          )
        : LedgerShredderApp(home: startWidget),
  );
}

class LedgerShredderApp extends StatelessWidget {
  final Widget home;

  const LedgerShredderApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final useFrame = kEnableDevicePreview && !kReleaseMode;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Wire device_preview's MediaQuery + locale + builder so the framed
      // device actually drives the app's size, theme, and text scale.
      useInheritedMediaQuery: useFrame,
      locale: useFrame ? DevicePreview.locale(context) : null,
      builder: useFrame ? DevicePreview.appBuilder : null,
      home: home,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F1A),
      ),
    );
  }
}
