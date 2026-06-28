import 'package:flutter/material.dart';

import '../../models/dashboard_response.dart';
import '../../theme/app_spacing.dart';
import '../animated_counter.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class ProgressRingCard extends StatelessWidget {
  const ProgressRingCard({
    super.key,
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (summary.completionPercentage / 100).clamp(0.0, 1.0);

    return FadeInSection(
      index: 1,
      child: AppCard(
        elevation: 1,
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 112,
                        height: 112,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 10,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      AnimatedCounter(
                        value: summary.completionPercentage,
                        suffix: '%',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Progress',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProgressStat(label: 'Completed', value: summary.completedHabits, color: theme.colorScheme.primary),
                  const SizedBox(height: AppSpacing.sm),
                  _ProgressStat(label: 'Pending', value: summary.pendingHabits, color: theme.colorScheme.tertiary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        AnimatedCounter(
          value: value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
