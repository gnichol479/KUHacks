import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import 'auth_entry_screen.dart';

/// Decides which screen to show on cold start by inspecting the persisted JWT.
///
/// Flow:
///   1. No token in SharedPreferences → AuthEntryScreen.
///   2. Token present and `/profile` returns 200 → HomeScreen.
///   3. Token present but `/profile` returns 401/expired → clear token and
///      fall back to AuthEntryScreen.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  late final Future<Widget> _decision = _decide();

  Future<Widget> _decide() async {
    if (!await AuthService.hasToken()) {
      return const AuthEntryScreen();
    }
    try {
      await AuthService.fetchProfile();
      return const HomeScreen();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await AuthService.logout();
      }
      return const AuthEntryScreen();
    } catch (_) {
      // Network error — keep the user logged in optimistically so they don't
      // get bounced to login when the backend is briefly unreachable.
      return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _decision,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        return snapshot.data ?? const AuthEntryScreen();
      },
    );
  }
}
