import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout/workout_template_model.dart';
import '../providers/workout_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class EditTemplateScreen extends StatefulWidget {
  const EditTemplateScreen({this.template, super.key});

  final WorkoutTemplateModel? template;

  @override
  State<EditTemplateScreen> createState() => _EditTemplateScreenState();
}

class _EditTemplateScreenState extends State<EditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _category = 'PUSH';
  final List<_ExerciseFormItem> _exercises = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(text: widget.template?.description ?? '');
    _category = widget.template?.category ?? 'PUSH';

    if (widget.template != null && widget.template!.exercises.isNotEmpty) {
      for (final ex in widget.template!.exercises) {
        _exercises.add(_ExerciseFormItem(
          nameController: TextEditingController(text: ex.exerciseName),
          setsController: TextEditingController(text: ex.sets.toString()),
          repsController: TextEditingController(text: ex.reps),
          restController: TextEditingController(text: ex.restSeconds.toString()),
        ));
      }
    } else {
      _addExercise();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final item in _exercises) {
      item.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exercises.add(_ExerciseFormItem(
        nameController: TextEditingController(text: ''),
        setsController: TextEditingController(text: '3'),
        repsController: TextEditingController(text: '12-15'),
        restController: TextEditingController(text: '45'),
      ));
    });
  }

  void _removeExercise(int index) {
    if (_exercises.length <= 1) return;
    setState(() {
      final removed = _exercises.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<WorkoutProvider>();
    final exerciseModels = <WorkoutTemplateExerciseModel>[];
    for (int i = 0; i < _exercises.length; i++) {
      final item = _exercises[i];
      exerciseModels.add(WorkoutTemplateExerciseModel(
        exerciseName: item.nameController.text.trim(),
        sets: int.tryParse(item.setsController.text.trim()) ?? 3,
        reps: item.repsController.text.trim().isEmpty ? '12-15' : item.repsController.text.trim(),
        restSeconds: int.tryParse(item.restController.text.trim()) ?? 45,
        sequenceOrder: i + 1,
      ));
    }

    final template = WorkoutTemplateModel(
      id: widget.template?.id,
      name: _nameController.text.trim(),
      category: _category,
      description: _descriptionController.text.trim(),
      exercises: exerciseModels,
    );

    final bool ok;
    if (widget.template != null && widget.template!.id != null) {
      ok = await provider.updateTemplate(widget.template!.id!, template);
    } else {
      ok = await provider.createTemplate(template);
    }

    if (!mounted) return;
    if (ok) {
      SnackBarUtils.showMessage(context, 'Template saved successfully');
      Navigator.of(context).pop();
    } else if (provider.errorMessage != null) {
      SnackBarUtils.showError(context, provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? 'Edit Template' : 'Create Template'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Template Name',
                hint: 'e.g. Push Day Heavy',
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                ),
                items: const [
                  DropdownMenuItem(value: 'PUSH', child: Text('Push (Chest/Shoulders/Triceps)')),
                  DropdownMenuItem(value: 'PULL', child: Text('Pull (Back/Biceps)')),
                  DropdownMenuItem(value: 'LEGS', child: Text('Legs / Lower Body')),
                  DropdownMenuItem(value: 'UPPER', child: Text('Upper Body')),
                  DropdownMenuItem(value: 'HIIT', child: Text('HIIT / CrossFit')),
                  DropdownMenuItem(value: 'FULL_BODY', child: Text('Full Body')),
                  DropdownMenuItem(value: 'GENERAL', child: Text('General Workout')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Target areas or notes',
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Exercises (${_exercises.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Exercise'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...List.generate(_exercises.length, (index) {
                final item = _exercises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text('${index + 1}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppTextField(
                                controller: item.nameController,
                                label: 'Exercise Name',
                                hint: 'e.g. Flat Press',
                                validator: (v) => v == null || v.trim().isEmpty ? 'Exercise name required' : null,
                              ),
                            ),
                            if (_exercises.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removeExercise(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: item.setsController,
                                label: 'Sets',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppTextField(
                                controller: item.repsController,
                                label: 'Reps',
                                hint: '12-15',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppTextField(
                                controller: item.restController,
                                label: 'Rest (sec)',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Save Template',
                isLoading: provider.isActionLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseFormItem {
  _ExerciseFormItem({
    required this.nameController,
    required this.setsController,
    required this.repsController,
    required this.restController,
  });

  final TextEditingController nameController;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController restController;

  void dispose() {
    nameController.dispose();
    setsController.dispose();
    repsController.dispose();
    restController.dispose();
  }
}
