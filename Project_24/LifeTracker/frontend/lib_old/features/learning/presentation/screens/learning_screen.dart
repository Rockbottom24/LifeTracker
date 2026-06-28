import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/presentation/widgets/empty_state_view.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Learning Tracker',
      child: EmptyStateView(title: 'Learning screen', description: 'The learning tracker shell is ready for future implementation.'),
    );
  }
}
