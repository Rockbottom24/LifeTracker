import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../app_time_picker.dart';

class ReminderFormSection extends StatelessWidget {
  const ReminderFormSection({
    super.key,
    required this.notificationsEnabled,
    required this.reminderTime,
    required this.onNotificationsChanged,
    required this.onReminderChanged,
    this.notificationSubtitle = 'Receive a daily reminder at the selected time',
  });

  final bool notificationsEnabled;
  final TimeOfDay reminderTime;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<TimeOfDay> onReminderChanged;
  final String notificationSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable notifications'),
          subtitle: Text(notificationSubtitle),
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
        ),
        if (notificationsEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          AppTimePicker(
            label: 'Reminder time',
            time: reminderTime,
            onTimeSelected: onReminderChanged,
          ),
        ],
      ],
    );
  }
}
