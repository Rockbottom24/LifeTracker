import 'package:flutter/material.dart';

import '../constants/habit_form_options.dart';
import '../models/habit_category_response.dart';
import '../models/habit_frequency.dart';
import '../theme/app_spacing.dart';
import '../utils/habit_ui_utils.dart';
import 'app_dropdown.dart';
import 'app_text_field.dart';
import 'form_section_card.dart';
import 'forms/appearance_form_section.dart';
import 'forms/form_tablet_grid.dart';
import 'forms/reminder_form_section.dart';
import 'frequency_chips.dart';
import 'responsive_form_container.dart';
import 'weekday_picker.dart';

class AddHabitFormContent extends StatelessWidget {
  const AddHabitFormContent({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.pointsController,
    required this.nameFocusNode,
    required this.descriptionFocusNode,
    this.autofocusName = false,
    required this.categories,
    required this.selectedCategory,
    required this.selectedFrequency,
    required this.reminderTime,
    required this.notificationsEnabled,
    required this.selectedColor,
    required this.selectedIcon,
    required this.categoryError,
    required this.frequencyError,
    required this.onCategoryChanged,
    required this.onFrequencyChanged,
    required this.onReminderTimeChanged,
    required this.onNotificationsChanged,
    required this.onColorChanged,
    required this.onIconChanged,
    this.selectedScheduleDays = const [],
    required this.onScheduleDaysChanged,
    this.targetDate,
    this.onTargetDateChanged,
    this.onAddNewCategory,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController pointsController;
  final FocusNode nameFocusNode;
  final FocusNode descriptionFocusNode;
  final bool autofocusName;
  final List<HabitCategoryResponse> categories;
  final HabitCategoryResponse? selectedCategory;
  final HabitFrequency selectedFrequency;
  final TimeOfDay reminderTime;
  final bool notificationsEnabled;
  final String selectedColor;
  final String selectedIcon;
  final String? categoryError;
  final String? frequencyError;
  final ValueChanged<HabitCategoryResponse?> onCategoryChanged;
  final ValueChanged<HabitFrequency> onFrequencyChanged;
  final ValueChanged<TimeOfDay> onReminderTimeChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onIconChanged;
  final List<int> selectedScheduleDays;
  final ValueChanged<List<int>> onScheduleDaysChanged;
  final DateTime? targetDate;
  final ValueChanged<DateTime>? onTargetDateChanged;
  final VoidCallback? onAddNewCategory;

  @override
  Widget build(BuildContext context) {
    final accentColor = HabitUiUtils.colorFromHex(selectedColor, Theme.of(context).colorScheme);
    final isTablet = ResponsiveFormContainer.isTablet(context);

    final basicSection = FormSectionCard(
      index: 0,
      title: 'Basic information',
      subtitle: 'Give your habit a clear name and optional description.',
      child: Column(
        children: [
          AppTextField(
            controller: nameController,
            focusNode: nameFocusNode,
            autofocus: autofocusName,
            label: 'Name',
            hint: 'e.g. Morning meditation',
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => descriptionFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: descriptionController,
            focusNode: descriptionFocusNode,
            label: 'Description',
            hint: 'Optional details about this habit',
            maxLines: isTablet ? 2 : 3,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: pointsController,
            label: 'Honor Points',
            hint: 'e.g. 10',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null;
              }
              final parsed = int.tryParse(value.trim());
              if (parsed == null || parsed < 0) {
                return 'Enter a non-negative whole number';
              }
              return null;
            },
          ),
        ],
      ),
    );

    final categorySection = FormSectionCard(
      index: 1,
      title: 'Category & frequency',
      subtitle: 'Choose where this habit fits and how often you want to do it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (onAddNewCategory != null)
                TextButton.icon(
                  onPressed: onAddNewCategory,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdown<HabitCategoryResponse>(
            label: null,
            hint: 'Select a category',
            value: selectedCategory,
            errorText: categoryError,
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          FrequencyChips(
            selected: selectedFrequency,
            errorText: frequencyError,
            onSelected: onFrequencyChanged,
          ),
          if (selectedFrequency == HabitFrequency.custom) ...[
            const SizedBox(height: AppSpacing.lg),
            WeekdayPicker(
              selectedDays: selectedScheduleDays,
              onChanged: onScheduleDaysChanged,
            ),
          ] else if (selectedFrequency == HabitFrequency.monthly || selectedFrequency == HabitFrequency.specificDate) ...[
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: targetDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) onTargetDateChanged?.call(picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(selectedFrequency == HabitFrequency.monthly ? Icons.calendar_month_rounded : Icons.calendar_today_rounded, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedFrequency == HabitFrequency.monthly
                                ? 'Monthly Repeat Day'
                                : 'Target Date',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            targetDate != null
                                ? (selectedFrequency == HabitFrequency.monthly
                                    ? 'Day ${targetDate!.day} of every month (${targetDate!.day}/${targetDate!.month}/${targetDate!.year})'
                                    : '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}')
                                : 'Select Date',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final reminderSection = FormSectionCard(
      index: 2,
      title: 'Reminder',
      subtitle: 'Stay on track with a gentle nudge at the right time.',
      child: ReminderFormSection(
        notificationsEnabled: notificationsEnabled,
        reminderTime: reminderTime,
        onNotificationsChanged: onNotificationsChanged,
        onReminderChanged: onReminderTimeChanged,
      ),
    );

    final appearanceSection = FormSectionCard(
      index: 3,
      title: 'Appearance',
      subtitle: 'Pick a color and icon that feels right for this habit.',
      child: AppearanceFormSection(
        selectedColor: selectedColor,
        selectedIcon: selectedIcon,
        accentColor: accentColor,
        onColorChanged: onColorChanged,
        onIconChanged: onIconChanged,
        colorHexValues: HabitFormOptions.colorHexValues,
        iconNames: HabitFormOptions.iconNames,
        iconResolver: HabitUiUtils.iconFromName,
      ),
    );

    if (isTablet) {
      return FormTabletTwoRowGrid(
        topLeft: basicSection,
        topRight: categorySection,
        bottomLeft: reminderSection,
        bottomRight: appearanceSection,
      );
    }

    return Column(
      children: [
        basicSection,
        categorySection,
        reminderSection,
        appearanceSection,
      ],
    );
  }
}
