import 'package:flutter/material.dart';

import '../../theme/house_theme.dart';
import '../../theme/app_spacing.dart';
import '../../utils/dashboard_view_data_mapper.dart';
import '../fade_in_section.dart';
import '../glass_card.dart';

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    super.key,
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.dayStatusMessage,
    required this.house,
    required this.currentDate,
    required this.earnedPoints,
    required this.possiblePoints,
    required this.questCount,
    required this.completedQuests,
    this.caloriesConsumed,
  });

  final String welcomeTitle;
  final String welcomeSubtitle;
  final String dayStatusMessage;
  final HouseTheme house;
  final DateTime currentDate;
  final int earnedPoints;
  final int possiblePoints;
  final int questCount;
  final int completedQuests;
  final double? caloriesConsumed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DashboardFormatters.formatDate(currentDate);
    const gold = Color(0xFFC4B28B);

    return FadeInSection(
      index: 0,
      child: GlassCard(
        borderRadius: 28,
        borderColor: gold.withValues(alpha: 0.35),
        borderWidth: 1.5,
        backgroundColor: Colors.black.withValues(alpha: 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            house.accent.withValues(alpha: 0.20),
            Colors.black.withValues(alpha: 0.32),
            ...house.bannerGradient.map((color) => color.withValues(alpha: 0.25)),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        welcomeTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        welcomeSubtitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: gold.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: house.accent.withValues(alpha: 0.25),
                    border: Border.all(color: gold.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: house.accent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    house.icon,
                    color: gold,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _AccentPill(icon: house.icon, label: house.displayName),
                _AccentPill(icon: Icons.calendar_month_outlined, label: dateLabel),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Today's Realm Chronicle",
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.96),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ProgressPill(
                  label: 'Honor Points',
                  value: '$earnedPoints / $possiblePoints',
                  icon: Icons.workspace_premium_rounded,
                ),
                _ProgressPill(
                  label: 'Quests Completed',
                  value: '$completedQuests / $questCount',
                  icon: Icons.task_alt_rounded,
                ),
                if (caloriesConsumed != null)
                  _ProgressPill(
                    label: 'Kitchen Energy',
                    value: '${caloriesConsumed!.round()} kcal',
                    icon: Icons.local_fire_department_rounded,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              dayStatusMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentPill extends StatelessWidget {
  const _AccentPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC4B28B).withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFC4B28B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: goldColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: goldColor),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
