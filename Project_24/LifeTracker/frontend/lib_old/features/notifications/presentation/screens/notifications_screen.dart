import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/presentation/widgets/empty_state_view.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Notifications',
      child: EmptyStateView(title: 'Notifications screen', description: 'The notification shell is ready for future implementation.'),
    );
  }
}
