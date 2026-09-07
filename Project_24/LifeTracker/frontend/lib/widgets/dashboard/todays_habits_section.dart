import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/dashboard_view_data_mapper.dart';
import '../../utils/habit_ui_utils.dart';
import '../fade_in_section.dart';
import '../glass_card.dart';
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
            GlassCard(
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
    const goldColor = Color(0xFFC4B28B);

    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      borderColor: habit.completed
          ? Colors.green.withValues(alpha: 0.3)
          : accent.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: habit.completed
                  ? Colors.green.withValues(alpha: 0.18)
                  : accent.withValues(alpha: 0.18),
              border: Border.all(
                color: habit.completed
                    ? Colors.green.withValues(alpha: 0.4)
                    : accent.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              habit.completed ? Icons.check_circle_rounded : HabitUiUtils.iconFromName(habit.iconName),
              color: habit.completed ? Colors.greenAccent : accent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              habit.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: habit.completed ? TextDecoration.lineThrough : null,
                color: habit.completed ? theme.colorScheme.onSurfaceVariant : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          habit.completed
              ? OutlinedButton(
                  onPressed: onUndo,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Undo', style: TextStyle(fontSize: 13)),
                )
              : FilledButton.icon(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.black),
                  label: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
        ],
      ),
    );
  }
}
