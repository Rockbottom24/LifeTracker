import 'package:flutter/material.dart';

import '../../theme/house_theme.dart';
import '../../theme/app_spacing.dart';
import '../../utils/dashboard_view_data_mapper.dart';
import '../fade_in_section.dart';

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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B0D10),
              ...house.bannerGradient.map((color) => color.withValues(alpha: 0.92)),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: house.accent.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: gold.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              welcomeTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              welcomeSubtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: gold.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
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
              "Today's Chronicle",
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.96),
                fontWeight: FontWeight.w700,
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
                ),
                _ProgressPill(
                  label: 'Quests',
                  value: '$completedQuests / $questCount',
                ),
                if (caloriesConsumed != null)
                  _ProgressPill(
                    label: 'Calories',
                    value: '${caloriesConsumed!.round()} kcal',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              dayStatusMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
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
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC4B28B).withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
