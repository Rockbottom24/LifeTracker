import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/habit_ui_utils.dart';
import '../../models/habit_response.dart';
import 'glass_card.dart';

class HabitListCard extends StatelessWidget {
  const HabitListCard({
    super.key,
    required this.habit,
    required this.completed,
    this.streak = 0,
    required this.onTap,
    required this.onComplete,
    required this.onUndo,
    required this.onDelete,
    this.isPendingSync = false,
  });

  final HabitResponse habit;
  final bool completed;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onUndo;
  final VoidCallback onDelete;
  final bool isPendingSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = HabitUiUtils.colorFromHex(habit.colorHex, theme.colorScheme);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
      onTap: onTap,
      child: Row(
        children: [
          // Habit Icon Badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(
              HabitUiUtils.iconFromName(habit.iconName),
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Habit Title + Points
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (habit.points > 0)
                      Text(
                        '+${habit.points} pts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC4B28B),
                        ),
                      ),
                    Text(
                      '🔥 $streak Streak',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8A65),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            ),
            onPressed: onDelete,
            tooltip: 'Delete habit',
          ),
          const SizedBox(width: 4),

          // Done / Undo Action Button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: completed
                ? OutlinedButton.icon(
                    key: const ValueKey('undo_btn'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: const Color(0xFFC4B28B).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onUndo,
                    icon: const Icon(Icons.undo_rounded, size: 16, color: Color(0xFFC4B28B)),
                    label: const Text(
                      'Undo',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC4B28B)),
                    ),
                  )
                : Container(
                    key: const ValueKey('done_btn_container'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFAA771C)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      key: const ValueKey('done_btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.black),
                      label: const Text(
                        'Done',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

