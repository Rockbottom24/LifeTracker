import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../color_picker_row.dart';
import '../icon_picker_row.dart';

class AppearanceFormSection extends StatelessWidget {
  const AppearanceFormSection({
    super.key,
    required this.selectedColor,
    required this.selectedIcon,
    required this.accentColor,
    required this.onColorChanged,
    required this.onIconChanged,
    this.colorHexValues,
    this.iconNames,
    this.iconResolver,
  });

  final String selectedColor;
  final String selectedIcon;
  final Color accentColor;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onIconChanged;
  final List<String>? colorHexValues;
  final List<String>? iconNames;
  final IconData Function(String)? iconResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        ColorPickerRow(
          selectedColor: selectedColor,
          onColorSelected: onColorChanged,
          colorHexValues: colorHexValues,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Icon',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        IconPickerRow(
          selectedIcon: selectedIcon,
          accentColor: accentColor,
          onIconSelected: onIconChanged,
          iconNames: iconNames,
          iconResolver: iconResolver,
        ),
      ],
    );
  }
}
