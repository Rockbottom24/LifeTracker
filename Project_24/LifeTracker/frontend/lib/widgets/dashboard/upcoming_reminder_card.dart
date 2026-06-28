import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/dashboard_view_data_mapper.dart';
import '../../utils/habit_ui_utils.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class UpcomingReminderCard extends StatelessWidget {
  const UpcomingReminderCard({
    super.key,
    required this.reminder,
  });

  final UpcomingReminder? reminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeInSection(
      index: 3,
      child: AppCard(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Reminder',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            if (reminder == null)
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "You're all caught up today.",
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      HabitUiUtils.iconFromName(reminder!.iconName),
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder!.habitName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          reminder!.reminderLabel,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
