import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_type.dart';
import '../navigation/add_meal_page_route.dart';
import '../navigation/app_navigator.dart';
import '../providers/meal_provider.dart';
import '../screens/food_screen.dart';
import '../theme/app_spacing.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/loading_view.dart';
import '../widgets/nutrition/edit_nutrition_goals_sheet.dart';
import '../widgets/nutrition/meal_timeline_section.dart';
import '../widgets/nutrition/nutrition_dashboard_header.dart';
import '../widgets/nutrition/nutrition_insights_section.dart';
import '../widgets/nutrition/nutrition_macro_cards_section.dart';
import '../widgets/nutrition/nutrition_progress_rings_section.dart';
import '../widgets/responsive_form_container.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealProvider>().refreshNutritionData();
    });
  }

  Future<void> _openAdd({MealType? mealType}) async {
    await Navigator.of(context).push(
      AddMealPageRoute(
        settings: const RouteSettings(name: '/add-meal'),
        initialMealType: mealType,
      ),
    );
  }

  Future<void> _openFoodLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/nutrition/foods'),
        builder: (_) => const FoodScreen(),
      ),
    );
  }

  Future<void> _duplicateYesterday(MealType mealType) async {
    final provider = context.read<MealProvider>();
    final ok = await provider.duplicateYesterday(mealType);
    if (!mounted) return;
    if (!ok) {
      SnackBarUtils.showError(context, provider.errorMessage ?? 'Unable to duplicate meals');
    }
  }

  Future<void> _clearMeal(MealType mealType) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Clear ${mealType.label}',
      message: 'Remove all ${mealType.label.toLowerCase()} entries for today?',
      confirmLabel: 'Clear',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<MealProvider>();
    final ok = await provider.clearMealsForType(mealType);
    if (!mounted) return;
    if (!ok) {
      SnackBarUtils.showError(context, provider.errorMessage ?? 'Unable to clear meals');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Royal Kitchen'),
        actions: [
          IconButton(
            onPressed: () => EditNutritionGoalsSheet.show(context, provider.goals),
            icon: const Icon(Icons.track_changes_outlined),
            tooltip: 'Daily Goals',
          ),
          IconButton(
            onPressed: _openFoodLibrary,
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Food Library',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nutrition_meals_fab',
        onPressed: () => _openAdd(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Meal'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refreshNutritionData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                  AppSpacing.screenHorizontal,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: ResponsiveFormContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const NutritionDashboardHeader(),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Royal Kitchen',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                        if (provider.isDashboardLoading && provider.progress.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                            child: Center(child: LoadingView()),
                          )
                        else if (provider.dashboardErrorMessage != null && provider.progress.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: Text(
                              'Unable to load your nutrition dashboard. Pull to refresh and try again.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        else ...[
                          NutritionProgressRingsSection(progress: provider.progress),
                          const SizedBox(height: AppSpacing.sectionGap),
                          NutritionMacroCardsSection(progress: provider.progress),
                          const SizedBox(height: AppSpacing.sectionGap),
                          NutritionInsightsSection(insights: provider.insights),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                  AppSpacing.screenHorizontal,
                  AppSpacing.listBottomInset,
                ),
                sliver: SliverToBoxAdapter(
                  child: ResponsiveFormContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feasts of the Day',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Review today\'s meals, macros, and the royal record of your nourishment.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        for (var i = 0; i < MealType.values.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.xl),
                          MealTimelineSection(
                            mealType: MealType.values[i],
                            meals: provider.mealsForType(MealType.values[i]),
                            isSaving: provider.isSaving,
                            onAddFood: () => _openAdd(mealType: MealType.values[i]),
                            onDuplicateYesterday: () => _duplicateYesterday(MealType.values[i]),
                            onClearMeal: () => _clearMeal(MealType.values[i]),
                            onMealDetails: (meal) => AppNavigator.openMealDetails(context, meal.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
