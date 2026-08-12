import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A Mon–Sun weekday toggle picker.
/// Selected days are represented as ISO weekday numbers: 1=Mon, 2=Tue … 7=Sun.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    this.errorText,
  });

  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;
  final String? errorText;

  static const _days = [
    (label: 'M', day: 1),
    (label: 'T', day: 2),
    (label: 'W', day: 3),
    (label: 'T', day: 4),
    (label: 'F', day: 5),
    (label: 'S', day: 6),
    (label: 'S', day: 7),
  ];

  static const _fullNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active days',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Quick presets row
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _PresetChip(
              label: 'Weekdays',
              onTap: () => onChanged([1, 2, 3, 4, 5]),
            ),
            _PresetChip(
              label: 'Weekends',
              onTap: () => onChanged([6, 7]),
            ),
            _PresetChip(
              label: 'Every day',
              onTap: () => onChanged([1, 2, 3, 4, 5, 6, 7]),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Day toggle row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_days.length, (index) {
            final dayNum = _days[index].day;
            final label = _days[index].label;
            final isSelected = selectedDays.contains(dayNum);

            return Tooltip(
              message: _fullNames[index],
              child: GestureDetector(
                onTap: () {
                  final newDays = List<int>.from(selectedDays);
                  if (isSelected) {
                    newDays.remove(dayNum);
                  } else {
                    newDays.add(dayNum);
                    newDays.sort();
                  }
                  onChanged(newDays);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (selectedDays.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            selectedDays
                .map((d) => _fullNames[d - 1])
                .join(', '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
