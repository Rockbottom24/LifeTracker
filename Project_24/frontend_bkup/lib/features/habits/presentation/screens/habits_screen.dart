import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/presentation/widgets/empty_state_view.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Daily Habits',
      child: EmptyStateView(title: 'Habits screen', description: 'The habits screen shell is ready for future implementation.'),
    );
  }
}
