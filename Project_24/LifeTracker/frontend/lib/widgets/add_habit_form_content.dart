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

class AddHabitFormContent extends StatelessWidget {
  const AddHabitFormContent({
    super.key,
    required this.nameController,
    required this.descriptionController,
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
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
          AppDropdown<HabitCategoryResponse>(
            label: 'Category',
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
