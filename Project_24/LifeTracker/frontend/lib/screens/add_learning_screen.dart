import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/learning_form_options.dart';
import '../models/create_learning_request.dart';
import '../models/learning_priority.dart';
import '../models/learning_session_response.dart';
import '../models/learning_status.dart';
import '../models/update_learning_request.dart';
import '../providers/learning_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/learning_notification_helper.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/forms/form_screen_scaffold.dart';
import '../widgets/learning/add_learning_form_content.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';

class AddLearningScreen extends StatefulWidget {
  const AddLearningScreen({super.key, this.session});

  final LearningSessionResponse? session;

  bool get isEditMode => session != null;

  @override
  State<AddLearningScreen> createState() => _AddLearningScreenState();
}

class _AddLearningScreenState extends State<AddLearningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _topicController = TextEditingController();
  final _plannedMinutesController = TextEditingController(text: '30');

  LearningPriority _priority = LearningPriority.medium;
  LearningStatus _status = LearningStatus.planned;
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _notificationsEnabled = true;
  String _selectedColor = LearningFormOptions.colorHexValues.first;
  String _selectedIcon = LearningFormOptions.iconNames.first;
  String? _successMessage;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    _prefill(widget.session);
  }

  void _prefill(LearningSessionResponse? session) {
    if (session == null) return;
    _titleController.text = session.title;
    _descriptionController.text = session.description ?? '';
    _topicController.text = session.topic ?? '';
    _plannedMinutesController.text = session.plannedMinutes.toString();
    _priority = session.priorityEnum;
    _status = session.statusEnum;
    _scheduledDate = session.scheduledDate ?? DateTime.now();
    _notificationsEnabled = session.notificationsEnabled;
    if (session.reminderTime != null) {
      _reminderTime = TimeOfDay(hour: session.reminderTime!.hour, minute: session.reminderTime!.minute);
    }
    if (session.colorHex != null && session.colorHex!.isNotEmpty) _selectedColor = session.colorHex!;
    if (session.iconName != null && session.iconName!.isNotEmpty) _selectedIcon = session.iconName!;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _topicController.dispose();
    _plannedMinutesController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _save() async {
    _dismissKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<LearningProvider>();
    final planned = int.parse(_plannedMinutesController.text.trim());
    final reminder = DateTime(1970, 1, 1, _reminderTime.hour, _reminderTime.minute);

    if (_isEditMode) {
      final ok = await provider.updateSession(
        widget.session!.id,
        UpdateLearningRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          topic: _topicController.text.trim(),
          plannedMinutes: planned,
          completedMinutes: widget.session!.completedMinutes,
          status: _status.apiValue,
          priority: _priority.apiValue,
          scheduledDate: _scheduledDate,
          completedDate: widget.session!.completedDate,
          reminderTime: reminder,
          notificationsEnabled: _notificationsEnabled,
          colorHex: _selectedColor,
          iconName: _selectedIcon,
        ),
      );
      if (!mounted) return;
      if (!ok) {
        SnackBarUtils.showError(context, provider.errorMessage ?? 'Save failed');
        return;
      }
      await LearningNotificationHelper.scheduleIfEnabled(
        sessionId: widget.session!.id,
        title: _titleController.text.trim(),
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
        notificationsEnabled: _notificationsEnabled,
      );
      setState(() => _successMessage = 'Session updated successfully');
      return;
    }

    final created = await provider.createSession(
      CreateLearningRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        topic: _topicController.text.trim(),
        plannedMinutes: planned,
        status: _status.apiValue,
        priority: _priority.apiValue,
        scheduledDate: _scheduledDate,
        reminderTime: reminder,
        notificationsEnabled: _notificationsEnabled,
        colorHex: _selectedColor,
        iconName: _selectedIcon,
      ),
    );
    if (!mounted) return;
    if (created == null) {
      SnackBarUtils.showError(context, provider.errorMessage ?? 'Save failed');
      return;
    }
    await LearningNotificationHelper.scheduleIfEnabled(
      sessionId: created.id,
      title: created.title,
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
      notificationsEnabled: _notificationsEnabled,
    );
    setState(() => _successMessage = '"${created.title}" created successfully');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Learning' : 'Add Learning'),
      ),
      body: FormScreenScaffold(
        formKey: _formKey,
        scrollController: _scrollController,
        onDismissKeyboard: _dismissKeyboard,
        successMessage: _successMessage,
        onSuccessComplete: () => Navigator.of(context).pop(),
        children: [
          SectionTitle(
            title: _isEditMode ? 'Edit session' : 'Plan a session',
            subtitle: 'Set your topic, schedule, and reminders.',
          ),
          const SizedBox(height: AppSpacing.xl),
          AddLearningFormContent(
            titleController: _titleController,
            descriptionController: _descriptionController,
            topicController: _topicController,
            plannedMinutesController: _plannedMinutesController,
            selectedPriority: _priority,
            selectedStatus: _status,
            scheduledDate: _scheduledDate,
            reminderTime: _reminderTime,
            notificationsEnabled: _notificationsEnabled,
            selectedColor: _selectedColor,
            selectedIcon: _selectedIcon,
            onPriorityChanged: (v) => setState(() => _priority = v),
            onStatusChanged: (v) => setState(() => _status = v),
            onDateChanged: (v) => setState(() => _scheduledDate = v),
            onReminderChanged: (v) => setState(() => _reminderTime = v),
            onNotificationsChanged: (v) => setState(() => _notificationsEnabled = v),
            onColorChanged: (v) => setState(() => _selectedColor = v),
            onIconChanged: (v) => setState(() => _selectedIcon = v),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AnimatedOpacity(
            opacity: _successMessage == null ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _successMessage != null,
              child: PrimaryButton(
                label: _isEditMode ? 'Update Session' : 'Save Session',
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
      ),
    );
  }
}
