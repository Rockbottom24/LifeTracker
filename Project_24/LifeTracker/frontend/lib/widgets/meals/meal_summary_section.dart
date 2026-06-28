import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/meal_nutrition_calculator.dart';
import '../../utils/meal_ui_utils.dart';
import '../animated_counter.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class MealSummarySection extends StatelessWidget {
  const MealSummarySection({
    super.key,
    required this.summary,
    required this.isLoading,
    this.errorMessage,
  });

  final MealNutritionSummary summary;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && summary.calories == 0 && summary.protein == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && summary.calories == 0 && summary.protein == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          errorMessage!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeInSection(
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
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.82),
                  theme.colorScheme.tertiary.withValues(alpha: 0.92),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Summary",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedCounter(
                      value: summary.calories.round(),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'kcal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        FadeInSection(
          index: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final cards = [
                _MacroCard(
                  label: 'Protein',
                  value: summary.protein,
                  suffix: 'g',
                  color: theme.colorScheme.primary,
                ),
                _MacroCard(
                  label: 'Carbs',
                  value: summary.carbs,
                  suffix: 'g',
                  color: theme.colorScheme.secondary,
                ),
                _MacroCard(
                  label: 'Fat',
                  value: summary.fat,
                  suffix: 'g',
                  color: theme.colorScheme.tertiary,
                ),
                _MacroCard(
                  label: 'Fiber',
                  value: summary.fiber,
                  suffix: 'g',
                  color: theme.colorScheme.primaryContainer,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    cards[i],
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
  });

  final String label;
  final double value;
  final String suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (value / 100).clamp(0.0, 1.0);

    return AppCard(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: animatedValue,
                        strokeWidth: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: color,
                      ),
                    ),
                    Icon(Icons.circle, size: 8, color: color),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: value),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, child) {
                        return Text(
                          MealUiUtils.formatMacro(animatedValue),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suffix,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
