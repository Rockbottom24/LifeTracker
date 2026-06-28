import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/dashboard_view_data_mapper.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class WeeklyProgressCard extends StatelessWidget {
  const WeeklyProgressCard({
    super.key,
    required this.days,
  });

  final List<WeeklyDayProgress> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeInSection(
      index: 4,
      child: AppCard(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Progress',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((day) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: day.value),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Container(
                                height: 90 * value + 8,
                                decoration: BoxDecoration(
                                  color: day.isToday
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            day.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
                              color: day.isToday
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
