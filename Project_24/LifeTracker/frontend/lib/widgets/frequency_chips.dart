import 'package:flutter/material.dart';

import '../models/habit_frequency.dart';
import '../theme/app_spacing.dart';

class FrequencyChips extends StatelessWidget {
  const FrequencyChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  final HabitFrequency? selected;
  final ValueChanged<HabitFrequency> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: HabitFrequency.values.map((frequency) {
            final isSelected = selected == frequency;

            return AnimatedScale(
              scale: isSelected ? 1.04 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: ChoiceChip(
                  label: Text(frequency.label),
                  selected: isSelected,
                  onSelected: (_) => onSelected(frequency),
                  showCheckmark: true,
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                  ),
                  side: BorderSide(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}
