import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppTimePicker extends StatelessWidget {
  const AppTimePicker({
    super.key,
    required this.label,
    required this.time,
    required this.onTimeSelected,
  });

  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeSelected;

  Future<void> _pickTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      onTimeSelected(selected);
    }
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

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
        InkWell(
          onTap: () => _pickTime(context),
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: const Icon(Icons.schedule_outlined),
            ),
            child: Text(
              _formatTime(time),
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}
