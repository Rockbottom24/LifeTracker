import 'package:flutter/material.dart';

import '../../models/macro_progress_item.dart';
import '../../theme/app_spacing.dart';
import '../../utils/meal_ui_utils.dart';
import '../animated_counter.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class NutritionProgressRingsSection extends StatelessWidget {
  const NutritionProgressRingsSection({
    super.key,
    required this.progress,
  });

  final List<MacroProgressItem> progress;

  Color _colorForKey(String key, ColorScheme scheme) {
    return switch (key) {
      'CALORIES' => scheme.primary,
      'PROTEIN' => scheme.secondary,
      'CARBS' => scheme.tertiary,
      'FAT' => scheme.error,
      'FIBER' => scheme.primaryContainer,
      _ => scheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final crossCount = isWide ? 5 : 2;
        final spacing = AppSpacing.md;

        return FadeInSection(
          index: 1,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: isWide ? 0.95 : 0.82,
            ),
            itemCount: progress.length,
            itemBuilder: (context, index) {
              final item = progress[index];
              final color = _colorForKey(item.key, theme.colorScheme);
              final ringProgress = (item.progressPercent / 100).clamp(0.0, 1.0);

              return AppCard(
                elevation: 1,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: ringProgress),
                        duration: Duration(milliseconds: 800 + (index * 80)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 7,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  color: color,
                                ),
                              ),
                              AnimatedCounter(
                                value: item.progressPercent.round(),
                                suffix: '%',
                                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.key == 'CALORIES'
                          ? '${MealUiUtils.formatMacro(item.consumed)} kcal'
                          : '${MealUiUtils.formatMacro(item.consumed)} g',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
