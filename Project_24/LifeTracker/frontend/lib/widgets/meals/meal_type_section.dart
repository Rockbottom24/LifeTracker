import 'package:flutter/material.dart';

import '../../models/meal_response.dart';
import '../../models/meal_type.dart';
import '../../theme/app_spacing.dart';
import '../../utils/meal_ui_utils.dart';

class MealTypeSection extends StatelessWidget {
  const MealTypeSection({
    super.key,
    required this.mealType,
    required this.meals,
    required this.itemBuilder,
  });

  final MealType mealType;
  final List<MealResponse> meals;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = MealUiUtils.colorForType(mealType, theme.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(MealUiUtils.iconForType(mealType), color: accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                mealType.label,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
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
                itemBuilder(context, i),
              ],
            ],
          ),
      ],
    );
  }
}
