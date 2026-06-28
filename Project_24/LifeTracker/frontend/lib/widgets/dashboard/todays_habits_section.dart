import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/dashboard_view_data_mapper.dart';
import '../../utils/habit_ui_utils.dart';
import '../app_card.dart';
import '../fade_in_section.dart';
import '../section_title.dart';

class TodaysHabitsSection extends StatelessWidget {
  const TodaysHabitsSection({
    super.key,
    required this.habits,
    required this.onHabitTap,
    required this.onComplete,
    required this.onUndo,
  });

  final List<TodayHabitViewItem> habits;
  final ValueChanged<int> onHabitTap;
  final ValueChanged<int> onComplete;
  final ValueChanged<int> onUndo;

  @override
  Widget build(BuildContext context) {
    return FadeInSection(
      index: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: "Today's Habits",
            subtitle: 'Quickly complete what matters most today.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (habits.isEmpty)
            AppCard(
              elevation: 1,
              child: Text(
                'No habits scheduled for today.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          else
            ...habits.map(
              (habit) => _TodayHabitTile(
                habit: habit,
                onTap: () => onHabitTap(habit.habitId),
                onComplete: () => onComplete(habit.habitId),
                onUndo: () => onUndo(habit.habitId),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayHabitTile extends StatelessWidget {
  const _TodayHabitTile({
    required this.habit,
    required this.onTap,
    required this.onComplete,
    required this.onUndo,
  });

  final TodayHabitViewItem habit;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = HabitUiUtils.colorFromHex(habit.colorHex, theme.colorScheme);

    return AppCard(
      elevation: 1,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: accent.withValues(alpha: 0.15),
            child: Icon(HabitUiUtils.iconFromName(habit.iconName), color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (habit.reminderLabel != null)
                      _MiniChip(icon: Icons.schedule, label: habit.reminderLabel!),
                    _MiniChip(icon: Icons.repeat, label: habit.frequencyLabel),
                    _MiniChip(
                      icon: habit.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                      label: habit.completed ? 'Completed' : 'Pending',
                    ),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: habit.completed ? onUndo : onComplete,
            icon: Icon(habit.completed ? Icons.undo : Icons.check),
            label: Text(habit.completed ? 'Undo' : 'Done'),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
