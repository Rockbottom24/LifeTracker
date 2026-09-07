import 'package:drift/drift.dart';

/// Food item reference database (system + user-created)
class FoodItemsTable extends Table {
  @override
  String get tableName => 'food_items';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  TextColumn get name => text().withLength(max: 255)();
  TextColumn get brand => text().nullable()();
  TextColumn get barcode => text().nullable()();
  // Nutrition per 100g
  RealColumn get caloriesPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get proteinPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get carbsPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get fatPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get fiberPer100g => real().nullable()();
  RealColumn get sugarPer100g => real().nullable()();
  RealColumn get sodiumPer100g => real().nullable()();
  // Default serving
  RealColumn get servingSizeG => real().withDefault(const Constant(100.0))();
  TextColumn get servingUnit => text().withDefault(const Constant('g'))();
  // system = bundled food DB, user = custom food created by user
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Meal logs — a meal event (e.g. "Breakfast on 2024-01-15")
class MealLogsTable extends Table {
  @override
  String get tableName => 'meal_logs';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  TextColumn get mealType => text()(); // BREAKFAST | LUNCH | DINNER | SNACK
  TextColumn get name => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Individual food items within a meal log
class MealLogItemsTable extends Table {
  @override
  String get tableName => 'meal_log_items';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  IntColumn get mealLogId => integer()();
  IntColumn get foodItemId => integer()();
  RealColumn get quantity => real()(); // amount consumed
  TextColumn get unit => text().withDefault(const Constant('g'))();
  // Snapshot of nutrition at time of logging (food item may change)
  RealColumn get calories => real()();
  RealColumn get protein => real()();
  RealColumn get carbs => real()();
  RealColumn get fat => real()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Daily nutrition goals
class NutritionGoalsTable extends Table {
  @override
  String get tableName => 'nutrition_goals';

  IntColumn get id => integer().autoIncrement()();
  RealColumn get calorieGoal => real().withDefault(const Constant(2000.0))();
  RealColumn get proteinGoal => real().withDefault(const Constant(150.0))();
  RealColumn get carbGoal => real().withDefault(const Constant(250.0))();
  RealColumn get fatGoal => real().withDefault(const Constant(65.0))();
  DateTimeColumn get updatedAt => dateTime()();
}
