import 'package:flutter/material.dart';

import '../../models/dashboard_response.dart';
import '../../services/user_xp_manager.dart';
import '../../theme/app_spacing.dart';
import '../animated_counter.dart';
import '../fade_in_section.dart';
import '../glass_card.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const goldColor = Color(0xFFC4B28B);

    return FutureBuilder<int>(
      future: UserXpManager.getXp(),
      builder: (context, snapshot) {
        final totalXp = (snapshot.data ?? 0) + (summary.completedHabits * 120);
        final level = UserXpManager.getLevel(totalXp);
        final rank = UserXpManager.getRank(level);
        final formattedXp = UserXpManager.formatXp(totalXp);

        final items = [
          _StatItem(
            title: 'Honor Points',
            value: summary.earnedPoints,
            suffix: ' / ${summary.possiblePoints}',
            icon: Icons.shield_rounded,
          ),
          _StatItem(
            title: 'Experience',
            value: '$formattedXp XP',
            isText: true,
            icon: Icons.auto_awesome_rounded,
          ),
          _StatItem(
            title: 'Level',
            value: level,
            icon: Icons.military_tech_rounded,
          ),
          _StatItem(
            title: 'Rank',
            value: rank,
            isText: true,
            icon: Icons.workspace_premium_rounded,
          ),
          _StatItem(
            title: 'Completed Today',
            value: summary.completedHabits,
            icon: Icons.check_circle_rounded,
          ),
          _StatItem(
            title: 'Daily Quests',
            value: summary.totalHabits,
            icon: Icons.format_list_bulleted_rounded,
          ),
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
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return GlassCard(
                padding: const EdgeInsets.all(12),
                margin: EdgeInsets.zero,
                borderColor: goldColor.withValues(alpha: 0.22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(item.icon, size: 16, color: goldColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (item.isText)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.value.toString(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedCounter(
                          value: item.value as num,
                          suffix: item.suffix,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.title,
    required this.value,
    this.suffix = '',
    this.isText = false,
    required this.icon,
  });

  final String title;
  final dynamic value;
  final String suffix;
  final bool isText;
  final IconData icon;
}
