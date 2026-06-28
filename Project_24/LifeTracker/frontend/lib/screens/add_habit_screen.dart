import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/habit_form_options.dart';
import '../models/create_habit_request.dart';
import '../models/habit_category_response.dart';
import '../models/habit_frequency.dart';
import '../models/habit_response.dart';
import '../models/update_habit_request.dart';
import '../providers/habit_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/habit_notification_helper.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/add_habit_form_content.dart';
import '../widgets/empty_state.dart';
import '../widgets/forms/form_screen_scaffold.dart';
import '../widgets/loading_view.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key, this.habit});

  final HabitResponse? habit;

  bool get isEditMode => habit != null;

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _scrollController = ScrollController();

  HabitCategoryResponse? _selectedCategory;
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _notificationsEnabled = true;
  String _selectedColor = HabitFormOptions.colorHexValues.first;
  String _selectedIcon = HabitFormOptions.iconNames.first;
  int? _pendingCategoryId;

  String? _categoryError;
  String? _frequencyError;
  String? _successMessage;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    _prefillFromHabit(widget.habit);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadCategories();
      if (!_isEditMode) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  void _prefillFromHabit(HabitResponse? habit) {
    if (habit == null) return;

    _nameController.text = habit.name;
    _descriptionController.text = habit.description ?? '';
    _selectedFrequency = HabitFrequency.fromApiValue(habit.frequency);
    _notificationsEnabled = habit.notificationsEnabled;
    _pendingCategoryId = habit.habitCategoryId;

    if (habit.reminderTime != null) {
      _reminderTime = TimeOfDay(
        hour: habit.reminderTime!.hour,
        minute: habit.reminderTime!.minute,
      );
    }

    if (habit.colorHex != null && habit.colorHex!.isNotEmpty) {
      _selectedColor = habit.colorHex!;
    }

    if (habit.iconName != null && habit.iconName!.isNotEmpty) {
      _selectedIcon = habit.iconName!;
    }
  }

  void _applyCategoryIfReady(List<HabitCategoryResponse> categories) {
    if (_selectedCategory != null || _pendingCategoryId == null || categories.isEmpty) {
      return;
    }

    for (final category in categories) {
      if (category.id == _pendingCategoryId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedCategory == null) {
            setState(() => _selectedCategory = category);
          }
        });
        return;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  bool _validateSelections() {
    var isValid = true;

    setState(() {
      _categoryError = _selectedCategory == null ? 'Please select a category' : null;
      _frequencyError = null;
    });

    if (_selectedCategory == null) {
      isValid = false;
    }

    return isValid;
  }

  Future<void> _save() async {
    _dismissKeyboard();

    final formValid = _formKey.currentState?.validate() ?? false;
    final selectionsValid = _validateSelections();

    if (!formValid || !selectionsValid) return;

    final provider = context.read<HabitProvider>();
    final reminderDateTime = DateTime(1970, 1, 1, _reminderTime.hour, _reminderTime.minute);

    if (_isEditMode) {
      await _saveEdit(provider, reminderDateTime);
    } else {
      await _saveCreate(provider, reminderDateTime);
    }
  }

  Future<void> _saveCreate(HabitProvider provider, DateTime reminderDateTime) async {
    final request = CreateHabitRequest(
      habitCategoryId: _selectedCategory!.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: DateTime.now(),
      frequency: _selectedFrequency.apiValue,
      reminderTime: reminderDateTime,
      notificationsEnabled: _notificationsEnabled,
      iconName: _selectedIcon,
      colorHex: _selectedColor,
    );

    final habit = await provider.createHabit(request);

    if (!mounted) return;

    if (habit == null) {
      SnackBarUtils.showError(context, provider.errorMessage ?? 'Failed to create habit');
      return;
    }

    await HabitNotificationHelper.scheduleIfEnabled(
      habitId: habit.id,
      name: habit.name,
      description: habit.description ?? _descriptionController.text.trim(),
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
      notificationsEnabled: _notificationsEnabled,
      frequency: _selectedFrequency,
      anchorDate: habit.startDate,
    );

    if (!mounted) return;

    setState(() {
      _successMessage = '"${habit.name}" created successfully';
    });
  }

  Future<void> _saveEdit(HabitProvider provider, DateTime reminderDateTime) async {
    final habit = widget.habit!;
    final request = UpdateHabitRequest(
      habitCategoryId: _selectedCategory!.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: habit.startDate,
      endDate: habit.endDate,
      frequency: _selectedFrequency.apiValue,
      reminderTime: reminderDateTime,
      notificationsEnabled: _notificationsEnabled,
      iconName: _selectedIcon,
      colorHex: _selectedColor,
    );

    final success = await provider.updateHabit(habit.id, request);

    if (!mounted) return;

    if (!success) {
      SnackBarUtils.showError(context, provider.errorMessage ?? 'Failed to update habit');
      return;
    }

    await HabitNotificationHelper.scheduleIfEnabled(
      habitId: habit.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
      notificationsEnabled: _notificationsEnabled,
      frequency: _selectedFrequency,
      anchorDate: habit.startDate,
    );

    if (!mounted) return;

    setState(() {
      _successMessage = '"${_nameController.text.trim()}" updated successfully';
    });
  }

  void _onSuccessComplete() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    _applyCategoryIfReady(provider.categories);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Habit' : 'Add Habit'),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(HabitProvider provider) {
    if (provider.isLoadingCategories && provider.categories.isEmpty) {
      return LoadingView(message: _isEditMode ? 'Loading habit details...' : 'Loading categories...');
    }

    if (provider.categoriesErrorMessage != null && provider.categories.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load categories',
        message: provider.categoriesErrorMessage!,
        actionLabel: 'Retry',
        onAction: provider.loadCategories,
      );
    }

    if (provider.categories.isEmpty) {
      return const EmptyState(
        icon: Icons.category_outlined,
        title: 'No categories available',
        message: 'Habit categories must be configured on the server before you can save a habit.',
      );
    }

    return FormScreenScaffold(
      formKey: _formKey,
      scrollController: _scrollController,
      onDismissKeyboard: _dismissKeyboard,
      successMessage: _successMessage,
      onSuccessComplete: _onSuccessComplete,
      children: [
        SectionTitle(
          title: _isEditMode ? 'Edit your habit' : 'Create a habit',
          subtitle: _isEditMode
              ? 'Update the details and reminder settings for this habit.'
              : 'Define what you want to track and when you want to be reminded.',
        ),
        const SizedBox(height: AppSpacing.xl),
        AddHabitFormContent(
          nameController: _nameController,
          descriptionController: _descriptionController,
          nameFocusNode: _nameFocusNode,
          descriptionFocusNode: _descriptionFocusNode,
          autofocusName: !_isEditMode,
          categories: provider.categories,
          selectedCategory: _selectedCategory,
          selectedFrequency: _selectedFrequency,
          reminderTime: _reminderTime,
          notificationsEnabled: _notificationsEnabled,
          selectedColor: _selectedColor,
          selectedIcon: _selectedIcon,
          categoryError: _categoryError,
          frequencyError: _frequencyError,
          onCategoryChanged: (value) => setState(() {
            _selectedCategory = value;
            _categoryError = null;
          }),
          onFrequencyChanged: (frequency) => setState(() {
            _selectedFrequency = frequency;
            _frequencyError = null;
          }),
          onReminderTimeChanged: (time) => setState(() => _reminderTime = time),
          onNotificationsChanged: (value) => setState(() => _notificationsEnabled = value),
          onColorChanged: (color) => setState(() => _selectedColor = color),
          onIconChanged: (icon) => setState(() => _selectedIcon = icon),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AnimatedOpacity(
          opacity: _successMessage == null ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: _successMessage != null,
            child: PrimaryButton(
              label: _isEditMode ? 'Update Habit' : 'Save Habit',
              loadingLabel: _isEditMode ? 'Updating...' : 'Saving...',
              expand: true,
              isLoading: provider.isSaving,
              icon: Icons.check_rounded,
              onPressed: provider.isSaving ? null : _save,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
