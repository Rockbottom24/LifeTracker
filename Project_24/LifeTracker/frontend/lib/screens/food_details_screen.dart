import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_response.dart';
import '../navigation/add_food_page_route.dart';
import '../providers/food_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/food_ui_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/detail_header_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_form_container.dart';

class FoodDetailsScreen extends StatefulWidget {
  const FoodDetailsScreen({super.key, required this.foodId});

  final int foodId;

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<FoodProvider>();
      if (provider.findFoodById(widget.foodId) == null) {
        await provider.loadFoods();
      }
    });
  }

  Future<void> _openEdit(FoodResponse food) async {
    await Navigator.of(context).push(
      AddFoodPageRoute(
        settings: RouteSettings(name: '/edit-food/${food.id}'),
        food: food,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(FoodResponse food) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete food',
      message: 'Are you sure you want to delete "${food.name}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<FoodProvider>();
    final ok = await provider.deleteFood(food.id);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      return;
    }

    SnackBarUtils.showError(context, provider.errorMessage ?? 'Failed to delete food');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FoodProvider>();
    final food = provider.findFoodById(widget.foodId);

    if (food == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Food Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final accent = FoodUiUtils.colorForCategory(food.category, theme.colorScheme);

    return Scaffold(
      appBar: AppBar(title: const Text('Food Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.xl,
            AppSpacing.screenHorizontal,
            AppSpacing.listBottomInset,
          ),
          children: [
            ResponsiveFormContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DetailHeaderCard(
                    icon: FoodUiUtils.iconForCategory(food.category),
                    iconColor: accent,
                    title: food.name,
                    subtitle: food.system ? 'System Food' : 'My Food',
                    chips: [
                      DetailStatChip(
                        label: food.category.label,
                        color: theme.colorScheme.primaryContainer,
                      ),
                      DetailStatChip(
                        label: food.referenceServingLabel,
                        color: theme.colorScheme.secondaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppCard(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      children: [
                        DetailInfoRow(
                          icon: Icons.category_outlined,
                          label: 'Category',
                          value: food.category.label,
                        ),
                        DetailInfoRow(
                          icon: Icons.scale_outlined,
                          label: 'Reference Serving',
                          value: food.referenceServingLabel,
                        ),
                        DetailInfoRow(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Calories',
                          value: FoodUiUtils.formatMacro(food.calories, 'kcal'),
                        ),
                        DetailInfoRow(
                          icon: Icons.fitness_center_outlined,
                          label: 'Protein',
                          value: FoodUiUtils.formatMacro(food.protein, 'g'),
                        ),
                        DetailInfoRow(
                          icon: Icons.grain,
                          label: 'Carbs',
                          value: FoodUiUtils.formatMacro(food.carbs, 'g'),
                        ),
                        DetailInfoRow(
                          icon: Icons.water_drop_outlined,
                          label: 'Fat',
                          value: FoodUiUtils.formatMacro(food.fat, 'g'),
                        ),
                        DetailInfoRow(
                          icon: Icons.eco_outlined,
                          label: 'Fiber',
                          value: FoodUiUtils.formatMacro(food.fiber, 'g'),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  if (!food.system)
                    DetailActionsSection(
                      children: [
                        PrimaryButton(
                          label: 'Edit Food',
                          icon: Icons.edit_outlined,
                          expand: true,
                          onPressed: () => _openEdit(food),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SecondaryActionButton(
                          label: 'Delete Food',
                          icon: Icons.delete_outline_rounded,
                          isDestructive: true,
                          onPressed: () => _delete(food),
                        ),
                      ],
                    )
                  else ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'System foods are read-only.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
