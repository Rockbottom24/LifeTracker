// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_dao.dart';

// ignore_for_file: type=lint
mixin _$NutritionDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoodItemsTableTable get foodItemsTable => attachedDatabase.foodItemsTable;
  $MealLogsTableTable get mealLogsTable => attachedDatabase.mealLogsTable;
  $MealLogItemsTableTable get mealLogItemsTable =>
      attachedDatabase.mealLogItemsTable;
  $NutritionGoalsTableTable get nutritionGoalsTable =>
      attachedDatabase.nutritionGoalsTable;
  NutritionDaoManager get managers => NutritionDaoManager(this);
}

class NutritionDaoManager {
  final _$NutritionDaoMixin _db;
  NutritionDaoManager(this._db);
  $$FoodItemsTableTableTableManager get foodItemsTable =>
      $$FoodItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.foodItemsTable,
      );
  $$MealLogsTableTableTableManager get mealLogsTable =>
      $$MealLogsTableTableTableManager(_db.attachedDatabase, _db.mealLogsTable);
  $$MealLogItemsTableTableTableManager get mealLogItemsTable =>
      $$MealLogItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.mealLogItemsTable,
      );
  $$NutritionGoalsTableTableTableManager get nutritionGoalsTable =>
      $$NutritionGoalsTableTableTableManager(
        _db.attachedDatabase,
        _db.nutritionGoalsTable,
      );
}
