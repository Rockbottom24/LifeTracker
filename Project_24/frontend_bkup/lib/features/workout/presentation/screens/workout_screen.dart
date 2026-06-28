import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/presentation/widgets/empty_state_view.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Workout',
      child: EmptyStateView(title: 'Workout screen', description: 'The workout screen shell is ready for future implementation.'),
    );
  }
}
