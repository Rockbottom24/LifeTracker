import 'package:flutter/material.dart';

import '../../models/dashboard_response.dart';
import '../../theme/app_spacing.dart';
import '../animated_counter.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final experience = (summary.completedHabits * 120) + (summary.totalHabits * 35) + (summary.currentStreak * 45);
    final level = (experience ~/ 500) + 1;
    final rank = _rankForLevel(level);

    final items = [
      _StatItem(title: 'Experience', value: experience, suffix: ' XP'),
      _StatItem(title: 'Level', value: level),
      _StatItem(title: 'Rank', value: rank, isText: true),
      _StatItem(title: 'Completed Today', value: summary.completedHabits),
      _StatItem(title: 'Daily Quests', value: summary.totalHabits),
      _StatItem(title: 'Completion Rate', value: summary.completionPercentage.round(), suffix: '%'),
    ];

    return FadeInSection(
      index: 5,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 720 ? 3 : 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return AppCard(
            elevation: 1,
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (item.isText)
                  Text(
                    item.value.toString(),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  )
                else
                  AnimatedCounter(
                    value: item.value as num,
                    suffix: item.suffix,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _rankForLevel(int level) {
    if (level >= 20) return 'King';
    if (level >= 16) return 'Hand of the King';
    if (level >= 12) return 'Warden';
    if (level >= 8) return 'Lord';
    if (level >= 5) return 'Knight';
    if (level >= 3) return 'Squire';
    return 'Smallfolk';
  }
}

class _StatItem {
  const _StatItem({
    required this.title,
    required this.value,
    this.suffix = '',
    this.isText = false,
  });

  final String title;
  final Object value;
  final String suffix;
  final bool isText;
}
