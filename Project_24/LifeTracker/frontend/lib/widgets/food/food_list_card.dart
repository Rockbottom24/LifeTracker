import 'package:flutter/material.dart';

import '../../models/food_response.dart';
import '../../theme/app_spacing.dart';
import '../../utils/food_ui_utils.dart';
import '../app_chip.dart';
import '../lists/accent_list_card_shell.dart';

class FoodListCard extends StatelessWidget {
  const FoodListCard({
    super.key,
    required this.food,
    required this.onTap,
  });

  final FoodResponse food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = FoodUiUtils.colorForCategory(food.category, theme.colorScheme);

    return AccentListCardShell(
      accentColor: accent,
      icon: FoodUiUtils.iconForCategory(food.category),
      title: food.name,
      subtitle: '${food.category.label} • ${food.referenceServingLabel}',
      onTap: onTap,
      footer: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppChip(
            icon: Icons.local_fire_department_outlined,
            label: FoodUiUtils.formatMacro(food.calories, 'kcal'),
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
          ),
          AppChip(
            icon: Icons.fitness_center_outlined,
            label: 'P ${FoodUiUtils.formatMacro(food.protein, 'g')}',
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          AppChip(
            icon: Icons.grain_outlined,
            label: 'C ${FoodUiUtils.formatMacro(food.carbs, 'g')}',
            backgroundColor: theme.colorScheme.tertiaryContainer,
            foregroundColor: theme.colorScheme.onTertiaryContainer,
          ),
          AppChip(
            icon: Icons.water_drop_outlined,
            label: 'F ${FoodUiUtils.formatMacro(food.fat, 'g')}',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          AppChip(
            icon: Icons.eco_outlined,
            label: 'Fi ${FoodUiUtils.formatMacro(food.fiber, 'g')}',
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
