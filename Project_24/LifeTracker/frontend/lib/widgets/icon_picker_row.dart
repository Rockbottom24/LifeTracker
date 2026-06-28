import 'package:flutter/material.dart';

import '../constants/habit_form_options.dart';
import '../theme/app_spacing.dart';

class IconPickerRow extends StatelessWidget {
  const IconPickerRow({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
    required this.accentColor,
    this.iconNames,
    this.iconResolver,
  });

  final String selectedIcon;
  final ValueChanged<String> onIconSelected;
  final Color accentColor;
  final List<String>? iconNames;
  final IconData Function(String)? iconResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: (iconNames ?? HabitFormOptions.iconNames).length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final icons = iconNames ?? HabitFormOptions.iconNames;
          final iconName = icons[index];
          final resolver = iconResolver ?? HabitFormOptions.iconData;
          final isSelected = iconName == selectedIcon;

          return AnimatedScale(
            scale: isSelected ? 1.08 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: isSelected ? accentColor.withValues(alpha: 0.16) : theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? accentColor : theme.colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => onIconSelected(iconName),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isSelected ? 52 : 48,
                    height: isSelected ? 52 : 48,
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        resolver(iconName),
                        key: ValueKey('$iconName-$isSelected'),
                        color: isSelected ? accentColor : theme.colorScheme.onSurfaceVariant,
                        size: isSelected ? 26 : 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
