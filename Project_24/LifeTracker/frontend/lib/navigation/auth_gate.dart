import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/local_auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/splash_screen.dart';
import 'app_navigation.dart';
import '../sync/sync_engine.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.syncEngine,
    super.key,
  });

  final SyncEngine syncEngine;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<LocalAuthProvider>();

    if (auth.isInitializing) {
      return const SplashScreen();
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    if (!auth.isRegistered) {
      return const RegistrationScreen();
    }

    return AppNavigation(syncEngine: syncEngine);
  }
}

