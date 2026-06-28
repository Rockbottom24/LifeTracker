import 'package:flutter/material.dart';

import '../../models/macro_progress_item.dart';
import '../../theme/app_spacing.dart';
import '../../utils/meal_ui_utils.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class NutritionMacroCardsSection extends StatelessWidget {
  const NutritionMacroCardsSection({
    super.key,
    required this.progress,
  });

  final List<MacroProgressItem> progress;

  Color _progressColor(double percent, ColorScheme scheme) {
    if (percent >= 100) return scheme.error;
    if (percent >= 75) return scheme.tertiary;
    if (percent >= 50) return scheme.primary;
    return scheme.secondary;
  }

  String _unitFor(String key) => key == 'CALORIES' ? 'kcal' : 'g';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        final cards = [
          for (var i = 0; i < progress.length; i++)
            FadeInSection(
              index: 2 + i,
              child: _MacroDetailCard(
                item: progress[i],
                unit: _unitFor(progress[i].key),
                progressColor: _progressColor(progress[i].progressPercent, theme.colorScheme),
              ),
            ),
        ];

        if (isWide) {
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: (constraints.maxWidth - AppSpacing.md) / 2,
                    child: card,
                  ),
                )
                .toList(),
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
    );
  }
}

class _MacroDetailCard extends StatelessWidget {
  const _MacroDetailCard({
    required this.item,
    required this.unit,
    required this.progressColor,
  });

  final MacroProgressItem item;
  final String unit;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (item.progressPercent / 100).clamp(0.0, 1.0);

    return AppCard(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${item.progressPercent.round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: progressColor,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _StatRow(label: 'Consumed', value: '${MealUiUtils.formatMacro(item.consumed)} $unit'),
          const SizedBox(height: AppSpacing.xs),
          _StatRow(label: 'Goal', value: '${MealUiUtils.formatMacro(item.goal)} $unit'),
          const SizedBox(height: AppSpacing.xs),
          _StatRow(
            label: 'Remaining',
            value: '${MealUiUtils.formatMacro(item.remaining)} $unit',
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: (emphasized ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)?.copyWith(
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
