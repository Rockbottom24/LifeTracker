import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_goals_response.dart';
import '../../models/update_nutrition_goals_request.dart';
import '../../providers/meal_provider.dart';
import '../../theme/app_spacing.dart';
import '../../utils/snackbar_utils.dart';
import '../app_text_field.dart';
import '../primary_button.dart';

class EditNutritionGoalsSheet extends StatefulWidget {
  const EditNutritionGoalsSheet({super.key, required this.initialGoals});

  final NutritionGoalsResponse initialGoals;

  static Future<void> show(BuildContext context, NutritionGoalsResponse initialGoals) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => EditNutritionGoalsSheet(initialGoals: initialGoals),
    );
  }

  @override
  State<EditNutritionGoalsSheet> createState() => _EditNutritionGoalsSheetState();
}

class _EditNutritionGoalsSheetState extends State<EditNutritionGoalsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController(text: _format(widget.initialGoals.calorieGoal));
    _proteinController = TextEditingController(text: _format(widget.initialGoals.proteinGoal));
    _carbsController = TextEditingController(text: _format(widget.initialGoals.carbsGoal));
    _fatController = TextEditingController(text: _format(widget.initialGoals.fatGoal));
    _fiberController = TextEditingController(text: _format(widget.initialGoals.fiberGoal));
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<MealProvider>();
    final ok = await provider.updateGoals(
      UpdateNutritionGoalsRequest(
        calorieGoal: double.parse(_caloriesController.text.trim()),
        proteinGoal: double.parse(_proteinController.text.trim()),
        carbsGoal: double.parse(_carbsController.text.trim()),
        fatGoal: double.parse(_fatController.text.trim()),
        fiberGoal: double.parse(_fiberController.text.trim()),
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    SnackBarUtils.showError(context, provider.errorMessage ?? 'Failed to update goals');
  }

  String? _validator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'Enter a valid number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Daily Goals',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Configure your default nutrition targets.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(controller: _caloriesController, label: 'Calories (kcal)', validator: _validator),
                    const SizedBox(height: AppSpacing.sectionGap),
                    AppTextField(controller: _proteinController, label: 'Protein (g)', validator: _validator),
                    const SizedBox(height: AppSpacing.sectionGap),
                    AppTextField(controller: _carbsController, label: 'Carbs (g)', validator: _validator),
                    const SizedBox(height: AppSpacing.sectionGap),
                    AppTextField(controller: _fatController, label: 'Fat (g)', validator: _validator),
                    const SizedBox(height: AppSpacing.sectionGap),
                    AppTextField(controller: _fiberController, label: 'Fiber (g)', validator: _validator),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Save Goals',
                      loadingLabel: 'Saving...',
                      expand: true,
                      isLoading: provider.isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
