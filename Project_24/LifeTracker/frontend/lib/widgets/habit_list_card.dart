import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/habit_ui_utils.dart';
import '../../models/habit_response.dart';
import 'app_chip.dart';
import 'lists/accent_list_card_shell.dart';

class HabitListCard extends StatelessWidget {
  const HabitListCard({
    super.key,
    required this.habit,
    required this.completed,
    required this.onTap,
    required this.onComplete,
    required this.onUndo,
    required this.onDelete,
    this.isPendingSync = false,
  });

  final HabitResponse habit;
  final bool completed;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onUndo;
  final VoidCallback onDelete;
  final bool isPendingSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = HabitUiUtils.colorFromHex(habit.colorHex, theme.colorScheme);

    return AccentListCardShell(
      accentColor: accentColor,
      icon: HabitUiUtils.iconFromName(habit.iconName),
      title: habit.name,
      subtitle: habit.description,
      onTap: onTap,
      trailing: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onDelete,
        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error.withValues(alpha: 0.85)),
        tooltip: 'Delete habit',
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                icon: Icons.repeat,
                label: habit.frequencyLabel,
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
              if (habit.formattedReminderTime != null)
                AppChip(
                  icon: Icons.schedule_outlined,
                  label: habit.formattedReminderTime!,
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                ),
              if (completed)
                AppChip(
                  icon: Icons.check_circle,
                  label: 'Done today',
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              if (isPendingSync)
                AppChip(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Pending sync',
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: completed ? onUndo : onComplete,
              icon: Icon(completed ? Icons.undo : Icons.check_circle_outline),
              label: Text(completed ? 'Undo' : 'Complete'),
            ),
          ),
        ],
      ),
    );
  }
}
