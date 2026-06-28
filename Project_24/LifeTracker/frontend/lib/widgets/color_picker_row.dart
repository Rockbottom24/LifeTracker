import 'package:flutter/material.dart';

import '../constants/habit_form_options.dart';
import '../theme/app_spacing.dart';

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colorHexValues,
  });

  final String selectedColor;
  final ValueChanged<String> onColorSelected;
  final List<String>? colorHexValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: (colorHexValues ?? HabitFormOptions.colorHexValues).length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final colors = colorHexValues ?? HabitFormOptions.colorHexValues;
          final colorHex = colors[index];
          final isSelected = colorHex == selectedColor;
          final color = HabitFormOptions.parseColor(colorHex);

          return AnimatedScale(
            scale: isSelected ? 1.12 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: GestureDetector(
              onTap: () => onColorSelected(colorHex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: isSelected ? 48 : 44,
                height: isSelected ? 48 : 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
                    width: isSelected ? 2.5 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Icon(Icons.check_rounded, key: ValueKey(colorHex), color: Colors.white, size: 22)
                      : SizedBox(key: ValueKey('empty_$colorHex')),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
