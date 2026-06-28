import 'package:flutter/foundation.dart';

import '../models/create_meal_request.dart';
import '../models/food_response.dart';
import '../models/macro_progress_item.dart';
import '../models/meal_response.dart';
import '../models/meal_type.dart';
import '../models/serving_unit.dart';
import '../models/nutrition_goals_response.dart';
import '../models/update_meal_request.dart';
import '../models/update_nutrition_goals_request.dart';
import '../services/api_client.dart';
import '../services/meal_service.dart';
import '../services/nutrition_service.dart';
import '../utils/meal_nutrition_calculator.dart';
import '../utils/nutrition_dashboard_mapper.dart';
import '../utils/nutrition_insights_builder.dart';

class MealProvider extends ChangeNotifier {
  MealProvider(this._mealService, this._nutritionService);

  final MealService _mealService;
  final NutritionService _nutritionService;

  bool isLoading = false;
  bool isRefreshing = false;
  bool isDashboardLoading = false;
  bool isSaving = false;
  String? errorMessage;
  String? dashboardErrorMessage;
  List<MealResponse> meals = [];
  DateTime selectedDate = DateTime.now();
  NutritionGoalsResponse goals = NutritionGoalsResponse.defaults;
  List<MacroProgressItem> progress = [];
  List<String> insights = [];

  MealNutritionSummary get todaySummary {
    var summary = MealNutritionSummary.zero;
    for (final meal in meals) {
      summary += MealNutritionSummary(
        calories: meal.totalCalories,
        protein: meal.totalProtein,
        carbs: meal.totalCarbs,
        fat: meal.totalFat,
        fiber: meal.totalFiber,
      );
    }
    return summary;
  }

  List<MealResponse> mealsForType(MealType type) {
    return meals.where((meal) => meal.mealType == type).toList();
  }

  MealResponse? findMealById(int id) {
    for (final meal in meals) {
      if (meal.id == id) return meal;
    }
    return null;
  }

  MacroProgressItem? progressFor(String key) {
    for (final item in progress) {
      if (item.key == key) return item;
    }
    return null;
  }

  Future<void> refreshNutritionData() async {
    selectedDate = DateTime.now();
    await loadDashboard();
  }

  Future<void> loadDashboard({DateTime? date}) async {
    final targetDate = date ?? selectedDate;
    selectedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);

    final hadCachedData = meals.isNotEmpty || progress.isNotEmpty;
    isLoading = !hadCachedData;
    isDashboardLoading = !hadCachedData;
    isRefreshing = hadCachedData;
    if (!hadCachedData) {
      errorMessage = null;
      dashboardErrorMessage = null;
    }
    notifyListeners();

    try {
      final dashboard = await _nutritionService.getDashboard(date: selectedDate);
      meals = dashboard.meals;
      goals = dashboard.goals;
      progress = dashboard.progress;
      insights = dashboard.insights;
      errorMessage = null;
      dashboardErrorMessage = null;
    } on ApiException catch (e) {
      if (meals.isEmpty) {
        errorMessage = e.message;
        dashboardErrorMessage = e.message;
      }
    } catch (e) {
      if (meals.isEmpty) {
        errorMessage = e.toString();
        dashboardErrorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      isDashboardLoading = false;
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayMeals() async {
    await loadDashboard(date: DateTime.now());
  }

  Future<void> refreshMeals() async {
    await loadDashboard(date: selectedDate);
  }

  Future<bool> updateGoals(UpdateNutritionGoalsRequest request) async {
    isSaving = true;
    notifyListeners();
    try {
      goals = await _nutritionService.updateGoals(request);
      _syncDashboardLocally();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<MealResponse?> createMeal(CreateMealRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final meal = await _mealService.createMeal(request);
      meals = [...meals, meal];
      _syncDashboardLocally();
      return meal;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<MealResponse?> logFoodToTodayMeal({
    required FoodResponse food,
    required double quantity,
    required ServingUnit unit,
    MealType mealType = MealType.snack,
    String? notes,
    DateTime? mealDate,
  }) async {
    final created = await createMeal(
      CreateMealRequest(
        mealType: mealType,
        mealDate: mealDate ?? DateTime.now(),
        notes: notes,
        items: [
          MealItemRequest(
            foodItemId: food.id,
            quantity: quantity,
            unit: unit,
          ),
        ],
      ),
    );

    if (created != null) {
      await refreshNutritionData();
    }

    return created;
  }

  Future<bool> updateMeal(int id, UpdateMealRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _mealService.updateMeal(id, request);
      meals = meals.map((meal) => meal.id == id ? updated : meal).toList();
      _syncDashboardLocally();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMeal(int id) async {
    try {
      await _mealService.deleteMeal(id);
      meals = meals.where((meal) => meal.id != id).toList();
      _syncDashboardLocally();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> duplicateYesterday(MealType mealType) async {
    isSaving = true;
    notifyListeners();
    try {
      final duplicated = await _mealService.duplicateYesterday(mealType, date: selectedDate);
      meals = [...meals, ...duplicated];
      _syncDashboardLocally();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> clearMealsForType(MealType mealType) async {
    isSaving = true;
    notifyListeners();
    try {
      await _mealService.clearMealsForType(mealType, date: selectedDate);
      meals = meals.where((meal) => meal.mealType != mealType).toList();
      _syncDashboardLocally();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _syncDashboardLocally() {
    progress = NutritionDashboardMapper.buildProgress(meals, goals);
    insights = NutritionInsightsBuilder.build(goals, progress, meals);
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
