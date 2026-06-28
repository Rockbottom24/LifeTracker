import 'package:flutter/material.dart';

import '../../models/meal_response.dart';
import '../../models/meal_type.dart';
import '../../theme/app_spacing.dart';
import '../../utils/meal_ui_utils.dart';
import '../app_chip.dart';

class ExpandableMealCard extends StatefulWidget {
  const ExpandableMealCard({
    super.key,
    required this.meal,
    required this.onTapDetails,
  });

  final MealResponse meal;
  final VoidCallback onTapDetails;

  @override
  State<ExpandableMealCard> createState() => _ExpandableMealCardState();
}

class _ExpandableMealCardState extends State<ExpandableMealCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meal = widget.meal;
    final accent = MealUiUtils.colorForType(meal.mealType, theme.colorScheme);
    final foodNames = meal.items.map((item) => item.foodName).join(', ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(MealUiUtils.iconForType(meal.mealType), color: accent, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foodNames.isEmpty ? 'Meal' : foodNames,
                          maxLines: _expanded ? 4 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${MealUiUtils.formatMacro(meal.totalCalories)} kcal · P ${MealUiUtils.formatMacro(meal.totalProtein)}g',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  ...meal.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.foodName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            MealUiUtils.formatQuantity(item.quantity, item.unit.label),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
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
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: widget.onTapDetails,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('View details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealTimelineSection extends StatelessWidget {
  const MealTimelineSection({
    super.key,
    required this.mealType,
    required this.meals,
    required this.onAddFood,
    required this.onDuplicateYesterday,
    required this.onClearMeal,
    required this.onMealDetails,
    this.isSaving = false,
  });

  final MealType mealType;
  final List<MealResponse> meals;
  final VoidCallback onAddFood;
  final VoidCallback onDuplicateYesterday;
  final VoidCallback onClearMeal;
  final ValueChanged<MealResponse> onMealDetails;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = MealUiUtils.colorForType(mealType, theme.colorScheme);

    final sectionCalories = meals.fold<double>(0, (sum, meal) => sum + meal.totalCalories);
    final sectionProtein = meals.fold<double>(0, (sum, meal) => sum + meal.totalProtein);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(MealUiUtils.iconForType(mealType), color: accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType.label,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (meals.isNotEmpty)
                    Text(
                      '${MealUiUtils.formatMacro(sectionCalories)} kcal · P ${MealUiUtils.formatMacro(sectionProtein)}g',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Food'),
              onPressed: isSaving ? null : onAddFood,
            ),
            ActionChip(
              avatar: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text('Duplicate Yesterday'),
              onPressed: isSaving ? null : onDuplicateYesterday,
            ),
            ActionChip(
              avatar: Icon(Icons.delete_outline_rounded, size: 18, color: theme.colorScheme.error),
              label: Text('Clear Meal', style: TextStyle(color: theme.colorScheme.error)),
              onPressed: isSaving ? null : onClearMeal,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (meals.isEmpty)
          Text(
            'No ${mealType.label.toLowerCase()} logged yet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < meals.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sectionGap),
                ExpandableMealCard(
                  key: ValueKey('timeline-meal-${meals[i].id}'),
                  meal: meals[i],
                  onTapDetails: () => onMealDetails(meals[i]),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
