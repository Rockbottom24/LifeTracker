import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/create_meal_request.dart';
import '../models/food_response.dart';
import '../models/meal_response.dart';
import '../models/meal_type.dart';
import '../models/serving_unit.dart';
import '../models/update_meal_request.dart';
import '../providers/food_provider.dart';
import '../providers/meal_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/meal_nutrition_calculator.dart';
import '../utils/meal_ui_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';
import '../widgets/form_section_card.dart';
import '../widgets/forms/form_screen_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';

class _DraftMealItem {
  _DraftMealItem({
    required this.food,
    required this.quantity,
    required this.unit,
  });

  final FoodResponse food;
  final double quantity;
  final ServingUnit unit;

  MealNutritionSummary get summary => MealNutritionCalculator.fromFood(food, quantity, unit);
}

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({
    super.key,
    this.meal,
    this.initialMealType,
  });

  final MealResponse? meal;
  final MealType? initialMealType;

  bool get isEditMode => meal != null;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');

  MealType _mealType = MealType.breakfast;
  DateTime _mealDate = DateTime.now();
  String? _successMessage;
  FoodResponse? _selectedFood;
  ServingUnit _selectedUnit = ServingUnit.gram;
  final List<_DraftMealItem> _draftItems = [];
  Timer? _searchDebounce;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    if (widget.initialMealType != null) {
      _mealType = widget.initialMealType!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final foodProvider = context.read<FoodProvider>();
      if (foodProvider.foods.isEmpty) {
        await foodProvider.loadFoods();
      }
      if (widget.meal != null && mounted) {
        _prefill(widget.meal!);
        setState(() {});
      }
    });
  }

  void _prefill(MealResponse meal) {
    _mealType = meal.mealType;
    _mealDate = meal.mealDate;
    _notesController.text = meal.notes ?? '';
    _draftItems.clear();

    final foodProvider = context.read<FoodProvider>();
    for (final item in meal.items) {
      final food = foodProvider.findFoodById(item.foodItemId);
      if (food != null) {
        _draftItems.add(
          _DraftMealItem(
            food: food,
            quantity: item.quantity,
            unit: item.unit,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      context.read<FoodProvider>().searchFoods(value);
    });
  }

  void _selectFood(FoodResponse food) {
    setState(() {
      _selectedFood = food;
      _selectedUnit = food.servingUnit;
      _searchController.text = food.name;
      _quantityController.text = food.referenceQuantity.toString();
    });
    _dismissKeyboard();
  }

  void _addDraftItem() {
    if (_selectedFood == null) {
      SnackBarUtils.showError(context, 'Select a food first');
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      SnackBarUtils.showError(context, 'Enter a valid quantity');
      return;
    }

    setState(() {
      _draftItems.add(
        _DraftMealItem(
          food: _selectedFood!,
          quantity: quantity,
          unit: _selectedUnit,
        ),
      );
      _selectedFood = null;
      _searchController.clear();
      _quantityController.text = '1';
      _selectedUnit = ServingUnit.gram;
    });
    context.read<FoodProvider>().loadFoods();
  }

  void _removeDraftItem(int index) {
    setState(() => _draftItems.removeAt(index));
  }

  MealNutritionSummary get _draftTotal {
    var total = MealNutritionSummary.zero;
    for (final item in _draftItems) {
      total += item.summary;
    }
    return total;
  }

  Future<void> _save() async {
    _dismissKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_draftItems.isEmpty) {
      SnackBarUtils.showError(context, 'Add at least one food');
      return;
    }

    final provider = context.read<MealProvider>();
    final items = _draftItems
        .map(
          (item) => MealItemRequest(
            foodItemId: item.food.id,
            quantity: item.quantity,
            unit: item.unit,
          ),
        )
        .toList();

    if (_isEditMode) {
      final ok = await provider.updateMeal(
        widget.meal!.id,
        UpdateMealRequest(
          mealType: _mealType,
          mealDate: _mealDate,
          notes: _notesController.text.trim(),
          items: items,
        ),
      );
      if (!mounted) return;
      if (!ok) {
        SnackBarUtils.showError(context, provider.errorMessage ?? 'Save failed');
        return;
      }
      setState(() => _successMessage = 'Meal updated successfully');
      return;
    }

    final created = await provider.createMeal(
      CreateMealRequest(
        mealType: _mealType,
        mealDate: _mealDate,
        notes: _notesController.text.trim(),
        items: items,
      ),
    );
    if (!mounted) return;
    if (created == null) {
      SnackBarUtils.showError(context, provider.errorMessage ?? 'Save failed');
      return;
    }
    setState(() => _successMessage = 'Meal logged successfully');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _mealDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _mealDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();
    final foodProvider = context.watch<FoodProvider>();
    final theme = Theme.of(context);
    final searchResults = foodProvider.foods.take(8).toList();
    final showSearchResults = _searchController.text.trim().isNotEmpty &&
        _selectedFood == null &&
        !foodProvider.isSearching;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Meal' : 'Add Meal')),
      body: FormScreenScaffold(
        formKey: _formKey,
        scrollController: _scrollController,
        onDismissKeyboard: _dismissKeyboard,
        successMessage: _successMessage,
        onSuccessComplete: () => Navigator.of(context).pop(),
        children: [
          SectionTitle(
            title: _isEditMode ? 'Update meal' : 'Log a meal',
            subtitle: 'Search foods from your library and let the app calculate nutrition.',
          ),
          const SizedBox(height: AppSpacing.lg),
          FormSectionCard(
            title: 'Meal Details',
            child: Column(
              children: [
                AppDropdown<MealType>(
                  label: 'Meal Type',
                  value: _mealType,
                  items: [
                    for (final type in MealType.values)
                      DropdownMenuItem<MealType>(
                        value: type,
                        child: Text(type.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _mealType = value);
                  },
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Meal Date',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      '${_mealDate.year}-${_mealDate.month.toString().padLeft(2, '0')}-${_mealDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppTextField(
                  controller: _notesController,
                  label: 'Notes',
                  hint: 'Optional notes',
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          FormSectionCard(
            title: 'Add Foods',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchBar(
                  controller: _searchController,
                  hintText: 'Search food library...',
                  leading: const Icon(Icons.search_rounded),
                  trailing: _searchController.text.isNotEmpty
                      ? [
                          IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _selectedFood = null);
                              context.read<FoodProvider>().loadFoods();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ]
                      : null,
                  onChanged: (value) {
                    setState(() {});
                    _onSearchChanged(value);
                  },
                ),
                if (foodProvider.isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (showSearchResults && searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'No matching food found.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else if (showSearchResults)
                  ...searchResults.map(
                    (food) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(food.name),
                      subtitle: Text('${food.category.label} · ${MealUiUtils.formatMacro(food.calories)} kcal / ${food.referenceServingLabel}'),
                      onTap: () => _selectFood(food),
                    ),
                  ),
                if (_selectedFood != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Selected: ${_selectedFood!.name}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _quantityController,
                    label: 'Quantity',
                    hint: _selectedFood?.referenceQuantity.toString() ?? '1',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppDropdown<ServingUnit>(
                    label: 'Unit',
                    value: _selectedUnit,
                    items: [
                      for (final unit in ServingUnit.values)
                        DropdownMenuItem<ServingUnit>(
                          value: unit,
                          child: Text(unit.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedUnit = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_selectedFood != null)
                    _MacroChipRow(summary: MealNutritionCalculator.fromFood(
                      _selectedFood!,
                      double.tryParse(_quantityController.text.trim()) ?? 0,
                      _selectedUnit,
                    )),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Add Food to Meal',
                    icon: Icons.add_rounded,
                    expand: true,
                    onPressed: _addDraftItem,
                  ),
                ],
              ],
            ),
          ),
          if (_draftItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            FormSectionCard(
              title: 'Selected Foods (${_draftItems.length})',
              child: Column(
                children: [
                  for (var i = 0; i < _draftItems.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sectionGap),
                    _DraftItemCard(
                      item: _draftItems[i],
                      onRemove: () => _removeDraftItem(i),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _MacroChipRow(summary: _draftTotal, title: 'Meal total preview'),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _isEditMode ? 'Save Changes' : 'Save Meal',
            loadingLabel: 'Saving...',
            expand: true,
            isLoading: mealProvider.isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _DraftItemCard extends StatelessWidget {
  const _DraftItemCard({
    required this.item,
    required this.onRemove,
  });

  final _DraftMealItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.food.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove',
              ),
            ],
          ),
          Text(
            MealUiUtils.formatQuantity(item.quantity, item.unit.label),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MacroChipRow(summary: item.summary),
        ],
      ),
    );
  }
}

class _MacroChipRow extends StatelessWidget {
  const _MacroChipRow({
    required this.summary,
    this.title,
  });

  final MealNutritionSummary summary;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppChip(
              label: '${MealUiUtils.formatMacro(summary.calories)} kcal',
              backgroundColor: theme.colorScheme.primaryContainer,
              compact: true,
            ),
            AppChip(
              label: 'P ${MealUiUtils.formatMacro(summary.protein)}g',
              backgroundColor: theme.colorScheme.secondaryContainer,
              compact: true,
            ),
            AppChip(
              label: 'C ${MealUiUtils.formatMacro(summary.carbs)}g',
              backgroundColor: theme.colorScheme.tertiaryContainer,
              compact: true,
            ),
            AppChip(
              label: 'F ${MealUiUtils.formatMacro(summary.fat)}g',
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              compact: true,
            ),
            AppChip(
              label: 'Fi ${MealUiUtils.formatMacro(summary.fiber)}g',
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }
}
