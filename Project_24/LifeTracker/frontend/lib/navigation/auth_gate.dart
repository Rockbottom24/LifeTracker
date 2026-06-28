import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/splash_screen.dart';
import 'app_navigation.dart';
import '../sync/sync_engine.dart';
import '../services/api_client.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.apiClient,
    required this.syncEngine,
    super.key,
  });

  final DioApiClient apiClient;
  final SyncEngine syncEngine;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) {
      return const SplashScreen();
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return AppNavigation(apiClient: apiClient, syncEngine: syncEngine);
  }
}
