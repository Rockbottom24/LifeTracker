import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.track_changes_rounded,
                  size: 44,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'LifeTracker',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.lg),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
