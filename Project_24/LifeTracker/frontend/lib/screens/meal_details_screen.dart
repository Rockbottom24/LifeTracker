import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_response.dart';
import '../navigation/add_meal_page_route.dart';
import '../providers/meal_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/meal_ui_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/app_chip.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/detail_header_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_form_container.dart';

class MealDetailsScreen extends StatefulWidget {
  const MealDetailsScreen({super.key, required this.mealId});

  final int mealId;

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MealProvider>();
      if (provider.findMealById(widget.mealId) == null) {
        await provider.refreshMeals();
      }
    });
  }

  Future<void> _openEdit(MealResponse meal) async {
    await Navigator.of(context).push(
      AddMealPageRoute(
        settings: RouteSettings(name: '/edit-meal/${meal.id}'),
        meal: meal,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(MealResponse meal) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete meal',
      message: 'Are you sure you want to delete this meal log?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<MealProvider>();
    final ok = await provider.deleteMeal(meal.id);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      return;
    }

    SnackBarUtils.showError(context, provider.errorMessage ?? 'Failed to delete meal');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final meal = provider.findMealById(widget.mealId);

    if (meal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meal Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final accent = MealUiUtils.colorForType(meal.mealType, theme.colorScheme);
    final dateLabel =
        '${meal.mealDate.year}-${meal.mealDate.month.toString().padLeft(2, '0')}-${meal.mealDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Details')),
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
                    icon: MealUiUtils.iconForType(meal.mealType),
                    iconColor: accent,
                    title: meal.mealType.label,
                    subtitle: dateLabel,
                    chips: [
                      DetailStatChip(
                        label: '${MealUiUtils.formatMacro(meal.totalCalories)} kcal',
                        color: theme.colorScheme.primaryContainer,
                      ),
                      DetailStatChip(
                        label: 'P ${MealUiUtils.formatMacro(meal.totalProtein)}g',
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
                          icon: Icons.calendar_today_outlined,
                          label: 'Meal Date',
                          value: dateLabel,
                        ),
                        DetailInfoRow(
                          icon: Icons.notes_outlined,
                          label: 'Notes',
                          value: meal.notes?.trim().isNotEmpty == true ? meal.notes! : 'None',
                        ),
                        DetailInfoRow(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Total Calories',
                          value: '${MealUiUtils.formatMacro(meal.totalCalories)} kcal',
                        ),
                        DetailInfoRow(
                          icon: Icons.fitness_center_outlined,
                          label: 'Total Protein',
                          value: '${MealUiUtils.formatMacro(meal.totalProtein)} g',
                        ),
                        DetailInfoRow(
                          icon: Icons.grain,
                          label: 'Total Carbs',
                          value: '${MealUiUtils.formatMacro(meal.totalCarbs)} g',
                        ),
                        DetailInfoRow(
                          icon: Icons.water_drop_outlined,
                          label: 'Total Fat',
                          value: '${MealUiUtils.formatMacro(meal.totalFat)} g',
                        ),
                        DetailInfoRow(
                          icon: Icons.eco_outlined,
                          label: 'Total Fiber',
                          value: '${MealUiUtils.formatMacro(meal.totalFiber)} g',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Text(
                    'Foods',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...meal.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
                      child: AppCard(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.foodName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              MealUiUtils.formatQuantity(item.quantity, item.unit.label),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                AppChip(
                                  label: '${MealUiUtils.formatMacro(item.calories)} kcal',
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  compact: true,
                                ),
                                AppChip(
                                  label: 'P ${MealUiUtils.formatMacro(item.protein)}g',
                                  backgroundColor: theme.colorScheme.secondaryContainer,
                                  compact: true,
                                ),
                                AppChip(
                                  label: 'C ${MealUiUtils.formatMacro(item.carbs)}g',
                                  backgroundColor: theme.colorScheme.tertiaryContainer,
                                  compact: true,
                                ),
                                AppChip(
                                  label: 'F ${MealUiUtils.formatMacro(item.fat)}g',
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  compact: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DetailActionsSection(
                    children: [
                      PrimaryButton(
                        label: 'Edit Meal',
                        icon: Icons.edit_outlined,
                        expand: true,
                        onPressed: () => _openEdit(meal),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SecondaryActionButton(
                        label: 'Delete Meal',
                        icon: Icons.delete_outline_rounded,
                        isDestructive: true,
                        onPressed: () => _delete(meal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
