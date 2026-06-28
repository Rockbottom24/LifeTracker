import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/presentation/widgets/empty_state_view.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Settings',
      child: EmptyStateView(title: 'Settings screen', description: 'The settings shell is ready for future implementation.'),
    );
  }
}
