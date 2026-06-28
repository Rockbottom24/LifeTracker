import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/create_food_request.dart';
import '../models/food_category.dart';
import '../models/food_response.dart';
import '../models/serving_unit.dart';
import '../models/update_food_request.dart';
import '../providers/food_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';
import '../widgets/form_section_card.dart';
import '../widgets/forms/form_screen_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({
    super.key,
    this.food,
    this.initialName,
  });

  final FoodResponse? food;
  final String? initialName;

  bool get isEditMode => food != null;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _referenceQuantityController = TextEditingController(text: '1');
  final _referenceWeightController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();

  FoodCategory _category = FoodCategory.other;
  ServingUnit _servingUnit = ServingUnit.gram;
  String? _successMessage;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    if (widget.food != null) {
      _prefill(widget.food!);
    } else if (widget.initialName != null && widget.initialName!.trim().isNotEmpty) {
      _nameController.text = widget.initialName!.trim();
    }
  }

  void _prefill(FoodResponse food) {
    _nameController.text = food.name;
    _referenceQuantityController.text = _formatNumber(food.referenceQuantity);
    _referenceWeightController.text = _formatNumber(food.referenceWeight);
    _caloriesController.text = _formatNumber(food.calories);
    _proteinController.text = _formatNumber(food.protein);
    _carbsController.text = _formatNumber(food.carbs);
    _fatController.text = _formatNumber(food.fat);
    _fiberController.text = _formatNumber(food.fiber);
    _category = food.category;
    _servingUnit = food.servingUnit;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _referenceQuantityController.dispose();
    _referenceWeightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  Future<void> _save() async {
    _dismissKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<FoodProvider>();
    final referenceQuantity = _parseNumber(_referenceQuantityController.text)!;
    final referenceWeight = _parseNumber(_referenceWeightController.text)!;
    final calories = _parseNumber(_caloriesController.text)!;
    final protein = _parseNumber(_proteinController.text)!;
    final carbs = _parseNumber(_carbsController.text)!;
    final fat = _parseNumber(_fatController.text)!;
    final fiber = _parseNumber(_fiberController.text)!;

    if (_isEditMode) {
      final ok = await provider.updateFood(
        widget.food!.id,
        UpdateFoodRequest(
          name: _nameController.text.trim(),
          category: _category,
          servingUnit: _servingUnit,
          referenceQuantity: referenceQuantity,
          referenceWeight: referenceWeight,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          fiber: fiber,
        ),
      );
      if (!mounted) return;
      if (!ok) {
        SnackBarUtils.showError(context, provider.errorMessage ?? 'Save failed');
        return;
      }
      setState(() => _successMessage = 'Food updated successfully');
      return;
    }

    final created = await provider.createFood(
      CreateFoodRequest(
        name: _nameController.text.trim(),
        category: _category,
        servingUnit: _servingUnit,
        referenceQuantity: referenceQuantity,
        referenceWeight: referenceWeight,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
      ),
    );
    if (!mounted) return;
    if (created == null) {
      SnackBarUtils.showError(context, provider.errorMessage ?? 'Save failed');
      return;
    }
    setState(() => _successMessage = 'Food created successfully');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Food' : 'Add Food')),
      body: FormScreenScaffold(
        formKey: _formKey,
        scrollController: _scrollController,
        onDismissKeyboard: _dismissKeyboard,
        successMessage: _successMessage,
        onSuccessComplete: () => Navigator.of(context).pop(),
        children: [
          SectionTitle(
            title: _isEditMode ? 'Update food' : 'Create food',
            subtitle: 'Nutrition values are stored per reference serving.',
          ),
          const SizedBox(height: AppSpacing.lg),
          FormSectionCard(
            title: 'Food Details',
            child: Column(
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Food Name',
                  hint: 'e.g. Grandma Dal',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Food name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppDropdown<FoodCategory>(
                  label: 'Category',
                  value: _category,
                  items: [
                    for (final item in FoodCategory.values)
                      DropdownMenuItem<FoodCategory>(
                        value: item,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppDropdown<ServingUnit>(
                  label: 'Serving Unit',
                  value: _servingUnit,
                  items: [
                    for (final item in ServingUnit.values)
                      DropdownMenuItem<ServingUnit>(
                        value: item,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _servingUnit = value;
                        if (!_isEditMode) {
                          final defaults = _defaultServingValues(value);
                          _referenceQuantityController.text = _formatNumber(defaults.$1);
                          _referenceWeightController.text = _formatNumber(defaults.$2);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          FormSectionCard(
            title: 'Reference Serving',
            child: Column(
              children: [
                AppTextField(
                  controller: _referenceQuantityController,
                  label: 'Reference Quantity',
                  hint: '1',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _nonNegativeValidator,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppTextField(
                  controller: _referenceWeightController,
                  label: 'Reference Weight (g)',
                  hint: '100',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _nonNegativeValidator,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppTextField(
                  controller: _caloriesController,
                  label: 'Calories',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _nonNegativeValidator,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppTextField(
                  controller: _proteinController,
                  label: 'Protein (g)',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _nonNegativeValidator,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppTextField(
                  controller: _carbsController,
                  label: 'Carbs (g)',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _nonNegativeValidator,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppTextField(
                  controller: _fatController,
                  label: 'Fat (g)',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _nonNegativeValidator,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppTextField(
                  controller: _fiberController,
                  label: 'Fiber (g)',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _nonNegativeValidator,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _isEditMode ? 'Save Changes' : 'Save Food',
            loadingLabel: 'Saving...',
            expand: true,
            isLoading: provider.isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  String? _nonNegativeValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a value >= 0';
    }
    return null;
  }

  (double, double) _defaultServingValues(ServingUnit unit) {
    return switch (unit) {
      ServingUnit.gram => (100, 100),
      ServingUnit.ml => (250, 250),
      ServingUnit.piece => (1, 50),
      ServingUnit.scoop => (1, 30),
      ServingUnit.tablespoon => (1, 13.5),
      ServingUnit.teaspoon => (1, 5),
      ServingUnit.cup => (1, 240),
    };
  }
}
