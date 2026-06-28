import 'package:flutter/material.dart';

import '../../theme/house_theme.dart';
import '../../theme/app_spacing.dart';
import '../../utils/dashboard_view_data_mapper.dart';
import '../fade_in_section.dart';

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    super.key,
    required this.profileLabel,
    required this.house,
    required this.houseMotto,
    required this.currentDate,
    required this.experience,
    required this.level,
    required this.rank,
  });

  final String profileLabel;
  final HouseTheme house;
  final String houseMotto;
  final DateTime currentDate;
  final int experience;
  final int level;
  final String rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DashboardFormatters.formatDate(currentDate);

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
            colors: house.bannerGradient.map((color) => color.withValues(alpha: 0.98)).toList(),
          ),
          boxShadow: [
            BoxShadow(
              color: house.accent.withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: house.accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              profileLabel,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
              houseMotto,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ProgressPill(label: 'Experience', value: '$experience XP'),
                _ProgressPill(label: 'Level', value: '$level'),
                _ProgressPill(label: 'Rank', value: rank),
              ],
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
