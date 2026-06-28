import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/learning_form_options.dart';
import '../../utils/learning_ui_utils.dart';
import '../../models/learning_priority.dart';
import '../../models/learning_status.dart';
import '../../theme/app_spacing.dart';
import '../app_dropdown.dart';
import '../app_text_field.dart';
import '../form_section_card.dart';
import '../forms/appearance_form_section.dart';
import '../forms/form_tablet_grid.dart';
import '../forms/reminder_form_section.dart';
import '../responsive_form_container.dart';

class AddLearningFormContent extends StatelessWidget {
  const AddLearningFormContent({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.topicController,
    required this.plannedMinutesController,
    required this.selectedPriority,
    required this.selectedStatus,
    required this.scheduledDate,
    required this.reminderTime,
    required this.notificationsEnabled,
    required this.selectedColor,
    required this.selectedIcon,
    required this.onPriorityChanged,
    required this.onStatusChanged,
    required this.onDateChanged,
    required this.onReminderChanged,
    required this.onNotificationsChanged,
    required this.onColorChanged,
    required this.onIconChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController topicController;
  final TextEditingController plannedMinutesController;
  final LearningPriority selectedPriority;
  final LearningStatus selectedStatus;
  final DateTime scheduledDate;
  final TimeOfDay reminderTime;
  final bool notificationsEnabled;
  final String selectedColor;
  final String selectedIcon;
  final ValueChanged<LearningPriority> onPriorityChanged;
  final ValueChanged<LearningStatus> onStatusChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onReminderChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onIconChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = LearningUiUtils.colorFromHex(selectedColor, theme.colorScheme);
    final isTablet = ResponsiveFormContainer.isTablet(context);

    final basicSection = FormSectionCard(
      index: 0,
      title: 'Basic information',
      subtitle: 'Describe what you want to learn and why it matters.',
      child: Column(
        children: [
          AppTextField(
            controller: titleController,
            label: 'Title',
            hint: 'e.g. Read Clean Code',
            validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: descriptionController,
            label: 'Description',
            hint: 'Optional notes or goals',
            maxLines: isTablet ? 2 : 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: topicController,
            label: 'Topic',
            hint: 'e.g. Software Engineering',
          ),
        ],
      ),
    );

    final planningSection = FormSectionCard(
      index: 1,
      title: 'Planning',
      subtitle: 'Set priority, status, and how long you plan to study.',
      child: Column(
        children: [
          AppDropdown<LearningPriority>(
            label: 'Priority',
            value: selectedPriority,
            items: LearningPriority.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) onPriorityChanged(v);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppDropdown<LearningStatus>(
            label: 'Status',
            value: selectedStatus,
            items: LearningStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) onStatusChanged(v);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: plannedMinutesController,
            label: 'Planned minutes',
            hint: '30',
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 1) return 'Enter planned minutes';
              return null;
            },
          ),
        ],
      ),
    );

    final scheduleSection = FormSectionCard(
      index: 2,
      title: 'Schedule & reminder',
      subtitle: 'Pick when you want to learn and get notified.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduled date',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: scheduledDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) onDateChanged(picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined)),
              child: Text(DateFormat.yMMMd().format(scheduledDate)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ReminderFormSection(
            notificationsEnabled: notificationsEnabled,
            reminderTime: reminderTime,
            onNotificationsChanged: onNotificationsChanged,
            onReminderChanged: onReminderChanged,
            notificationSubtitle: 'Receive a reminder at the selected time',
          ),
        ],
      ),
    );

    final appearanceSection = FormSectionCard(
      index: 3,
      title: 'Appearance',
      subtitle: 'Personalize how this session appears in your list.',
      child: AppearanceFormSection(
        selectedColor: selectedColor,
        selectedIcon: selectedIcon,
        accentColor: accent,
        onColorChanged: onColorChanged,
        onIconChanged: onIconChanged,
        colorHexValues: LearningFormOptions.colorHexValues,
        iconNames: LearningFormOptions.iconNames,
        iconResolver: LearningUiUtils.iconFromName,
      ),
    );

    if (isTablet) {
      return FormTabletTwoRowGrid(
        topLeft: basicSection,
        topRight: planningSection,
        bottomLeft: scheduleSection,
        bottomRight: appearanceSection,
      );
    }

    return Column(
      children: [
        basicSection,
        planningSection,
        scheduleSection,
        appearanceSection,
      ],
    );
  }
}
