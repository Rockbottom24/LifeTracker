import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.errorText,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          key: ValueKey(value),
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ],
    );
  }
}
