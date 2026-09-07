import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/nutrition_tables.dart';

part 'nutrition_dao.g.dart';

@DriftAccessor(tables: [FoodItemsTable, MealLogsTable, MealLogItemsTable, NutritionGoalsTable])
class NutritionDao extends DatabaseAccessor<AppDatabase>
    with _$NutritionDaoMixin {
  NutritionDao(super.db);

  // ── Food Items ──────────────────────────────────────────────────────────────

  Future<List<FoodItemsTableData>> searchFoods(String query) =>
      (select(foodItemsTable)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.isActive.equals(true) &
                (t.name.like('%$query%') | t.brand.like('%$query%')))
            ..orderBy([(t) => OrderingTerm.asc(t.name)])
            ..limit(50))
          .get();

  Future<FoodItemsTableData?> getFoodByBarcode(String barcode) =>
      (select(foodItemsTable)
            ..where((t) =>
                t.barcode.equals(barcode) &
                t.deletedAt.isNull() &
                t.isActive.equals(true)))
          .getSingleOrNull();

  Future<FoodItemsTableData?> getFoodById(int id) =>
      (select(foodItemsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertFood(FoodItemsTableCompanion food) =>
      into(foodItemsTable).insert(food);

  Future<bool> updateFood(FoodItemsTableCompanion food) =>
      update(foodItemsTable).replace(food);

  Future<void> softDeleteFood(int id) =>
      (update(foodItemsTable)..where((t) => t.id.equals(id))).write(
          FoodItemsTableCompanion(
        deletedAt: Value(DateTime.now()),
        isActive: const Value(false),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  // ── Meal Logs ───────────────────────────────────────────────────────────────

  Future<List<MealLogsTableData>> getMealLogsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(mealLogsTable)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.loggedAt.isBiggerOrEqualValue(startOfDay) &
              t.loggedAt.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
        .get();
  }

  Stream<List<MealLogsTableData>> watchMealLogsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(mealLogsTable)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.loggedAt.isBiggerOrEqualValue(startOfDay) &
              t.loggedAt.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
        .watch();
  }

  Future<int> insertMealLog(MealLogsTableCompanion meal) =>
      into(mealLogsTable).insert(meal);

  Future<void> softDeleteMealLog(int id) =>
      (update(mealLogsTable)..where((t) => t.id.equals(id))).write(
          MealLogsTableCompanion(
        deletedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  // ── Meal Log Items ──────────────────────────────────────────────────────────

  Future<List<MealLogItemsTableData>> getItemsForMeal(int mealLogId) =>
      (select(mealLogItemsTable)
            ..where((t) =>
                t.mealLogId.equals(mealLogId) & t.deletedAt.isNull()))
          .get();

  Stream<List<MealLogItemsTableData>> watchItemsForMeal(int mealLogId) =>
      (select(mealLogItemsTable)
            ..where((t) =>
                t.mealLogId.equals(mealLogId) & t.deletedAt.isNull()))
          .watch();

  Future<int> insertMealLogItem(MealLogItemsTableCompanion item) =>
      into(mealLogItemsTable).insert(item);

  Future<void> softDeleteMealLogItem(int id) =>
      (update(mealLogItemsTable)..where((t) => t.id.equals(id))).write(
          MealLogItemsTableCompanion(
        deletedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ));

  // ── Nutrition Totals for a Date ─────────────────────────────────────────────

  Future<Map<String, double>> getDailyTotals(DateTime date) async {
    final meals = await getMealLogsForDate(date);
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    for (final meal in meals) {
      final items = await getItemsForMeal(meal.id);
      for (final item in items) {
        calories += item.calories;
        protein += item.protein;
        carbs += item.carbs;
        fat += item.fat;
      }
    }
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  // ── Nutrition Goals ─────────────────────────────────────────────────────────

  Future<NutritionGoalsTableData?> getGoals() =>
      (select(nutritionGoalsTable)..limit(1)).getSingleOrNull();

  Future<void> saveGoals(NutritionGoalsTableCompanion goals) =>
      into(nutritionGoalsTable).insertOnConflictUpdate(goals);

  // ── Sync ────────────────────────────────────────────────────────────────────

  Future<List<MealLogsTableData>> getUnsyncedMeals() =>
      (select(mealLogsTable)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markMealsSynced(List<int> ids) =>
      (update(mealLogsTable)..where((t) => t.id.isIn(ids)))
          .write(const MealLogsTableCompanion(isSynced: Value(true)));
}
