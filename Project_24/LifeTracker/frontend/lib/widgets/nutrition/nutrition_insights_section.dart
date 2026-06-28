import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class NutritionInsightsSection extends StatelessWidget {
  const NutritionInsightsSection({
    super.key,
    required this.insights,
  });

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return FadeInSection(
      index: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Insights',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                elevation: 1,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        insight,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
