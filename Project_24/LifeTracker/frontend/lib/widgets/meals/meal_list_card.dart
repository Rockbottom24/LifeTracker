import 'package:flutter/material.dart';

import '../../models/meal_response.dart';
import '../../theme/app_spacing.dart';
import '../../utils/meal_ui_utils.dart';
import '../app_chip.dart';
import '../lists/accent_list_card_shell.dart';

class MealListCard extends StatelessWidget {
  const MealListCard({
    super.key,
    required this.meal,
    required this.onTap,
  });

  final MealResponse meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = MealUiUtils.colorForType(meal.mealType, theme.colorScheme);
    final foodNames = meal.items.map((item) => item.foodName).join(', ');

    return AccentListCardShell(
      accentColor: accent,
      icon: MealUiUtils.iconForType(meal.mealType),
      title: foodNames.isEmpty ? 'Meal' : foodNames,
      subtitle: meal.notes?.trim().isNotEmpty == true ? meal.notes : null,
      onTap: onTap,
      footer: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppChip(
            label: '${MealUiUtils.formatMacro(meal.totalCalories)} kcal',
            backgroundColor: theme.colorScheme.primaryContainer,
            compact: true,
          ),
          AppChip(
            label: 'P ${MealUiUtils.formatMacro(meal.totalProtein)}g',
            backgroundColor: theme.colorScheme.secondaryContainer,
            compact: true,
          ),
          AppChip(
            label: 'C ${MealUiUtils.formatMacro(meal.totalCarbs)}g',
            backgroundColor: theme.colorScheme.tertiaryContainer,
            compact: true,
          ),
          AppChip(
            label: 'F ${MealUiUtils.formatMacro(meal.totalFat)}g',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            compact: true,
          ),
          AppChip(
            label: 'Fi ${MealUiUtils.formatMacro(meal.totalFiber)}g',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            compact: true,
          ),
        ],
      ),
    );
  }
}
