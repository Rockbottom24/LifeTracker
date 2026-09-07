import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _mealsStoreKey = 'offline_user_meals_store_v1';

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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<MealResponse> get selectedDateMeals {
    return meals.where((meal) => _isSameDay(meal.mealDate, selectedDate)).toList();
  }

  MealNutritionSummary get todaySummary {
    var summary = MealNutritionSummary.zero;
    for (final meal in selectedDateMeals) {
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
    return selectedDateMeals.where((meal) => meal.mealType == type).toList();
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

    isLoading = false;
    isDashboardLoading = false;
    isRefreshing = false;
    errorMessage = null;
    dashboardErrorMessage = null;

    await _loadMealsFromDisk();
    _syncDashboardLocally();

    _loadDashboardInBackground(selectedDate);
  }

  void _loadDashboardInBackground(DateTime date) async {
    try {
      final dashboard = await _nutritionService.getDashboard(date: date);
      if (dashboard.meals.isNotEmpty) {
        final localMap = {for (var m in meals) m.id: m};
        for (var sm in dashboard.meals) {
          localMap[sm.id] = sm;
        }
        meals = localMap.values.toList();
      }
      goals = dashboard.goals;
      _syncDashboardLocally();
    } catch (_) {
      // Ignore background errors — cached local meals remain completely safe
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
      goals = NutritionGoalsResponse(
        calorieGoal: request.calorieGoal,
        proteinGoal: request.proteinGoal,
        carbsGoal: request.carbsGoal,
        fatGoal: request.fatGoal,
        fiberGoal: request.fiberGoal ?? goals.fiberGoal,
      );
      _syncDashboardLocally();

      // Fire server call unawaited in background (fire-and-forget)
      _nutritionService.updateGoals(request).catchError((_) => goals);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<MealResponse?> createMeal(CreateMealRequest request, {List<FoodResponse>? foods}) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final localId = DateTime.now().millisecondsSinceEpoch;
      final mealItems = <MealItemResponse>[];
      double totalCal = 0, totalP = 0, totalC = 0, totalF = 0, totalFib = 0;

      for (var i = 0; i < request.items.length; i++) {
        final itemReq = request.items[i];
        double cal = 0, p = 0, c = 0, f = 0, fib = 0;
        String fName = 'Food #${itemReq.foodItemId}';

        FoodResponse? match;
        if (foods != null) {
          for (final fItem in foods) {
            if (fItem.id == itemReq.foodItemId) {
              match = fItem;
              break;
            }
          }
        }

        if (match != null) {
          fName = match.name;
          final calc = MealNutritionCalculator.fromFood(match, itemReq.quantity, itemReq.unit);
          if (calc.isSuccess && calc.summary != null) {
            cal = calc.summary!.calories;
            p = calc.summary!.protein;
            c = calc.summary!.carbs;
            f = calc.summary!.fat;
            fib = calc.summary!.fiber;
          }
        }

        mealItems.add(MealItemResponse(
          id: localId + i,
          foodItemId: itemReq.foodItemId,
          foodName: fName,
          quantity: itemReq.quantity,
          unit: itemReq.unit,
          calories: cal,
          protein: p,
          carbs: c,
          fat: f,
          fiber: fib,
          displayOrder: i,
        ));

        totalCal += cal;
        totalP += p;
        totalC += c;
        totalF += f;
        totalFib += fib;
      }

      final meal = MealResponse(
        id: localId,
        uuid: 'local-$localId',
        mealType: request.mealType,
        mealDate: request.mealDate,
        notes: request.notes,
        items: mealItems,
        totalCalories: totalCal,
        totalProtein: totalP,
        totalCarbs: totalC,
        totalFat: totalF,
        totalFiber: totalFib,
      );

      meals = [...meals, meal];
      _syncDashboardLocally();

      // Fire server call unawaited in background
      _mealService.createMeal(request).catchError((_) => meal);
      return meal;
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
      foods: [food],
    );

    return created;
  }

  Future<bool> updateMeal(int id, UpdateMealRequest request, {List<FoodResponse>? foods}) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final existingIndex = meals.indexWhere((m) => m.id == id);
      if (existingIndex != -1) {
        final mealItems = <MealItemResponse>[];
        double totalCal = 0, totalP = 0, totalC = 0, totalF = 0, totalFib = 0;

        for (var i = 0; i < request.items.length; i++) {
          final itemReq = request.items[i];
          double cal = 0, p = 0, c = 0, f = 0, fib = 0;
          String fName = 'Food #${itemReq.foodItemId}';

          FoodResponse? match;
          if (foods != null) {
            for (final fItem in foods) {
              if (fItem.id == itemReq.foodItemId) {
                match = fItem;
                break;
              }
            }
          }

          if (match != null) {
            fName = match.name;
            final calc = MealNutritionCalculator.fromFood(match, itemReq.quantity, itemReq.unit);
            if (calc.isSuccess && calc.summary != null) {
              cal = calc.summary!.calories;
              p = calc.summary!.protein;
              c = calc.summary!.carbs;
              f = calc.summary!.fat;
              fib = calc.summary!.fiber;
            }
          }

          mealItems.add(MealItemResponse(
            id: id + i,
            foodItemId: itemReq.foodItemId,
            foodName: fName,
            quantity: itemReq.quantity,
            unit: itemReq.unit,
            calories: cal,
            protein: p,
            carbs: c,
            fat: f,
            fiber: fib,
            displayOrder: i,
          ));

          totalCal += cal;
          totalP += p;
          totalC += c;
          totalF += f;
          totalFib += fib;
        }

        final updatedMeal = MealResponse(
          id: id,
          uuid: meals[existingIndex].uuid,
          mealType: request.mealType,
          mealDate: request.mealDate,
          notes: request.notes,
          items: mealItems,
          totalCalories: totalCal,
          totalProtein: totalP,
          totalCarbs: totalC,
          totalFat: totalF,
          totalFiber: totalFib,
        );

        meals[existingIndex] = updatedMeal;
        _syncDashboardLocally();
      }

      // Fire server call unawaited in background
      _mealService.updateMeal(id, request).catchError((_) => meals[existingIndex]);
      return true;
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
    meals = meals.where((meal) => meal.id != id).toList();
    _syncDashboardLocally();
    _mealService.deleteMeal(id).catchError((_) {});
    return true;
  }

  Future<bool> duplicateYesterday(MealType mealType) async {
    isSaving = true;
    notifyListeners();
    try {
      final yesterday = selectedDate.subtract(const Duration(days: 1));
      final yesterdayMeals = meals.where((m) =>
          m.mealType == mealType && DateUtils.isSameDay(m.mealDate, yesterday)).toList();

      for (final oldMeal in yesterdayMeals) {
        final newId = DateTime.now().millisecondsSinceEpoch;
        final duplicated = MealResponse(
          id: newId,
          uuid: 'local-$newId',
          mealType: oldMeal.mealType,
          mealDate: selectedDate,
          notes: oldMeal.notes,
          items: oldMeal.items,
          totalCalories: oldMeal.totalCalories,
          totalProtein: oldMeal.totalProtein,
          totalCarbs: oldMeal.totalCarbs,
          totalFat: oldMeal.totalFat,
          totalFiber: oldMeal.totalFiber,
        );
        meals = [...meals, duplicated];
      }
      _syncDashboardLocally();

      _mealService.duplicateYesterday(mealType, date: selectedDate).catchError((_) => []);
      return true;
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
      meals = meals.where((meal) => meal.mealType != mealType).toList();
      _syncDashboardLocally();

      _mealService.clearMealsForType(mealType, date: selectedDate).catchError((_) {});
      return true;
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
    progress = NutritionDashboardMapper.buildProgress(selectedDateMeals, goals);
    insights = NutritionInsightsBuilder.build(goals, progress, selectedDateMeals);
    _saveMealsToDisk();
    notifyListeners();
  }

  Future<void> _saveMealsToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = meals.map((m) => m.toJson()).toList();
      await prefs.setString(_mealsStoreKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to save meals to disk: $e');
    }
  }

  Future<void> _loadMealsFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_mealsStoreKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        final loaded = decoded
            .whereType<Map>()
            .map((item) => MealResponse.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (loaded.isNotEmpty) {
          meals = loaded;
        }
      }
    } catch (e) {
      debugPrint('Failed to load meals from disk: $e');
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
