import 'package:flutter/material.dart';

import '../screens/login_screen.dart';

/// Registration is no longer needed — Google Sign-In handles account creation.
/// This screen simply redirects back to the login screen.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to login screen immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    });
    return const SizedBox.shrink();
  }
}
