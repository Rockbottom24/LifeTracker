import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/feature_card.dart';
import '../../../../shared/presentation/widgets/empty_state_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Dashboard',
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FeatureCard(title: 'Today at a glance', description: 'Overview and quick actions will appear here.'),
            SizedBox(height: 16),
            EmptyStateView(title: 'Dashboard ready', description: 'The dashboard UI shell is in place. Add widgets and data next.'),
          ],
        ),
      ),
    );
  }
}
