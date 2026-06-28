import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_response.dart';
import '../models/food_category.dart';
import '../models/meal_type.dart';
import '../models/scanned_food.dart';
import '../models/serving_unit.dart';
import '../providers/food_provider.dart';
import '../providers/meal_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/meal_nutrition_calculator.dart';
import '../utils/meal_ui_utils.dart';
import '../utils/snackbar_utils.dart';

class ProductPreviewScreen extends StatefulWidget {
  final ScannedFood product;

  const ProductPreviewScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductPreviewScreen> createState() => _ProductPreviewScreenState();
}

class _ProductPreviewScreenState extends State<ProductPreviewScreen> {
  final _quantityController = TextEditingController(text: '100');

  ServingUnit _selectedUnit = ServingUnit.gram;
  MealType _selectedMealType = MealType.snack;
  FoodResponse? _resolvedFood;
  bool _isAddingMeal = false;
  bool _isSavingFood = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.foodId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadResolvedFood();
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadResolvedFood() async {
    final foodId = widget.product.foodId;
    if (foodId == null || !mounted) return;

    final food = await context.read<FoodProvider>().getFoodById(foodId);
    if (!mounted) return;

    _resolvedFood ??= food;
    if (food != null) {
      setState(() {});
    }
  }

  double get _quantity {
    return double.tryParse(_quantityController.text.trim()) ?? 0;
  }

  MealNutritionSummary get _previewSummary {
    return MealNutritionCalculator.fromFood(
      _scannedFoodAsFood,
      _quantity,
      _selectedUnit,
    );
  }

  FoodResponse get _scannedFoodAsFood {
    return FoodResponse(
      id: _resolvedFood?.id ?? widget.product.foodId ?? 0,
      uuid: _resolvedFood?.uuid ?? '',
      name: widget.product.name,
      category: _resolvedFood?.category ?? FoodCategory.other,
      servingUnit: _resolvedFood?.servingUnit ?? ServingUnit.gram,
      referenceQuantity: _resolvedFood?.referenceQuantity ?? 1,
      referenceWeight: _resolvedFood?.referenceWeight ?? 100,
      calories: widget.product.calories,
      protein: widget.product.protein,
      carbs: widget.product.carbs,
      fat: widget.product.fat,
      fiber: widget.product.fiber,
      system: _resolvedFood?.system ?? false,
      barcode: widget.product.barcode,
      brand: widget.product.brand,
      imageUrl: widget.product.imageUrl,
      source: widget.product.source,
    );
  }

  bool get _alreadyInLibrary => widget.product.foodId != null || _resolvedFood != null;

  bool get _isBusy =>
      _isAddingMeal ||
      _isSavingFood ||
      context.read<FoodProvider>().isSaving ||
      context.read<MealProvider>().isSaving;

  void _showInvalidQuantity() {
    SnackBarUtils.showError(context, 'Enter a valid quantity greater than zero.');
  }

  Future<void> _addToTodayMeal() async {
    if (_isAddingMeal) return;

    final quantity = _quantity;
    if (quantity <= 0) {
      _showInvalidQuantity();
      return;
    }

    setState(() => _isAddingMeal = true);

    try {
      final foodProvider = context.read<FoodProvider>();
      final mealProvider = context.read<MealProvider>();

      FoodResponse? food = _resolvedFood;
      food ??= await foodProvider.resolveScannedFoodForMeal(widget.product);

      if (!mounted) return;

      if (food == null) {
        SnackBarUtils.showError(
          context,
          foodProvider.errorMessage ?? 'Unable to prepare this food for your meal.',
        );
        return;
      }

      setState(() => _resolvedFood = food);

      final meal = await mealProvider.logFoodToTodayMeal(
        food: food,
        quantity: quantity,
        unit: _selectedUnit,
        mealType: _selectedMealType,
      );

      if (!mounted) return;

      if (meal == null) {
        SnackBarUtils.showError(
          context,
          mealProvider.errorMessage ?? 'Unable to add this food to today\'s meal.',
        );
        return;
      }

      SnackBarUtils.showMessage(
        context,
        'Added to ${_selectedMealType.label.toLowerCase()} and refreshed your dashboard.',
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isAddingMeal = false);
      }
    }
  }

  Future<void> _saveToFoods() async {
    if (_isSavingFood) return;

    if (_alreadyInLibrary) {
      SnackBarUtils.showMessage(
        context,
        'This barcode is already in your Food Library.',
      );
      return;
    }

    setState(() => _isSavingFood = true);

    try {
      final foodProvider = context.read<FoodProvider>();
      final food = await foodProvider.saveScannedFood(widget.product);

      if (!mounted) return;

      if (food == null) {
        SnackBarUtils.showError(
          context,
          foodProvider.errorMessage ?? 'Unable to save this product.',
        );
        return;
      }

      setState(() => _resolvedFood = food);
      SnackBarUtils.showMessage(context, 'Saved to My Foods.');
    } finally {
      if (mounted) {
        setState(() => _isSavingFood = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final summary = _previewSummary;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  product.imageUrl,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.fastfood, size: 120);
                  },
                ),
              )
            else
              const Center(child: Icon(Icons.fastfood, size: 120)),
            const SizedBox(height: 20),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              product.brand.isEmpty ? 'Unknown Brand' : product.brand,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: _alreadyInLibrary ? 'Already in My Foods' : 'Open Food Facts',
                  color: _alreadyInLibrary
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.primaryContainer,
                ),
                _StatusChip(
                  label: 'Barcode: ${product.barcode}',
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Serving and meal details',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MealType>(
                      initialValue: _selectedMealType,
                      decoration: const InputDecoration(labelText: 'Meal Type'),
                      items: [
                        for (final mealType in MealType.values)
                          DropdownMenuItem(
                            value: mealType,
                            child: Text(mealType.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMealType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: '100',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ServingUnit>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Serving Unit'),
                      items: [
                        for (final unit in ServingUnit.values)
                          DropdownMenuItem(
                            value: unit,
                            child: Text(unit.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedUnit = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Estimated Nutrition',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculated for ${MealUiUtils.formatServing(_quantity, _selectedUnit.label.toLowerCase())}.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NutritionRow(label: 'Calories', value: '${summary.calories.toStringAsFixed(1)} kcal'),
                    _NutritionRow(label: 'Protein', value: '${summary.protein.toStringAsFixed(1)} g'),
                    _NutritionRow(label: 'Carbs', value: '${summary.carbs.toStringAsFixed(1)} g'),
                    _NutritionRow(label: 'Fat', value: '${summary.fat.toStringAsFixed(1)} g'),
                    _NutritionRow(label: 'Fiber', value: '${summary.fiber.toStringAsFixed(1)} g'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isAddingMeal
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restaurant),
                label: Text(
                  _isAddingMeal ? 'Saving...' : 'Add To Today\'s Meal',
                ),
                onPressed: _isBusy ? null : _addToTodayMeal,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: _isSavingFood
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSavingFood ? 'Saving...' : 'Save To My Foods',
                ),
                onPressed: _isBusy ? null : _saveToFoods,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color,
      label: Text(label),
    );
  }
}
