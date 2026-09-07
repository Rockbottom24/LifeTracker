import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/habit_tables.dart';
import 'tables/user_profile_table.dart';
import 'tables/expense_tables.dart';
import 'tables/learning_tables.dart';
import 'tables/nutrition_tables.dart';
import 'tables/workout_tables.dart';
import 'dao/habit_dao.dart';
import 'dao/expense_dao.dart';
import 'dao/learning_dao.dart';
import 'dao/nutrition_dao.dart';
import 'dao/workout_dao.dart';
import 'dao/profile_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  // User
  UserProfileTable,
  // Habits
  HabitCategoriesTable,
  HabitsTable,
  HabitLogsTable,
  // Expenses
  ExpenseCategoriesTable,
  ExpensesTable,
  // Learning
  LearningSessionsTable,
  // Nutrition
  FoodItemsTable,
  MealLogsTable,
  MealLogItemsTable,
  NutritionGoalsTable,
  // Workouts
  WorkoutTemplatesTable,
  WorkoutTemplateExercisesTable,
  WorkoutScheduleTable,
], daos: [
  HabitDao,
  ExpenseDao,
  LearningDao,
  NutritionDao,
  WorkoutDao,
  ProfileDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedHabitCategories();
          await _seedDefaultNutritionGoals();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations will go here
        },
      );

  // ── Seed data ──────────────────────────────────────────────────────────────

  Future<void> _seedHabitCategories() async {
    final now = DateTime.now();
    final categories = [
      HabitCategoriesTableCompanion.insert(
        uuid: 'cat-health-uuid',
        code: 'HEALTH_AND_FITNESS',
        name: 'Health & Fitness',
        description: const Value('Physical health, exercise, and fitness habits'),
        displayOrder: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
      HabitCategoriesTableCompanion.insert(
        uuid: 'cat-mind-uuid',
        code: 'MINDFULNESS',
        name: 'Mindfulness',
        description: const Value('Meditation, journaling, and mindfulness habits'),
        displayOrder: const Value(2),
        createdAt: now,
        updatedAt: now,
      ),
      HabitCategoriesTableCompanion.insert(
        uuid: 'cat-learn-uuid',
        code: 'LEARNING_AND_GROWTH',
        name: 'Learning & Growth',
        description: const Value('Reading, studying, and skill development habits'),
        displayOrder: const Value(3),
        createdAt: now,
        updatedAt: now,
      ),
      HabitCategoriesTableCompanion.insert(
        uuid: 'cat-social-uuid',
        code: 'SOCIAL',
        name: 'Social',
        description: const Value('Relationships, networking, and social habits'),
        displayOrder: const Value(4),
        createdAt: now,
        updatedAt: now,
      ),
      HabitCategoriesTableCompanion.insert(
        uuid: 'cat-finance-uuid',
        code: 'FINANCE',
        name: 'Finance',
        description: const Value('Savings, budgeting, and financial habits'),
        displayOrder: const Value(5),
        createdAt: now,
        updatedAt: now,
      ),
      HabitCategoriesTableCompanion.insert(
        uuid: 'cat-creative-uuid',
        code: 'CREATIVITY',
        name: 'Creativity',
        description: const Value('Art, music, writing, and creative habits'),
        displayOrder: const Value(6),
        createdAt: now,
        updatedAt: now,
      ),
      HabitCategoriesTableCompanion.insert(
        uuid: 'cat-other-uuid',
        code: 'OTHER',
        name: 'Other',
        description: const Value('Any habit that does not fit into a specific category'),
        displayOrder: const Value(7),
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await batch((b) => b.insertAll(habitCategoriesTable, categories));

  }

  Future<void> _seedDefaultNutritionGoals() async {
    await into(nutritionGoalsTable).insert(
      NutritionGoalsTableCompanion.insert(
        calorieGoal: const Value(2000.0),
        proteinGoal: const Value(150.0),
        carbGoal: const Value(250.0),
        fatGoal: const Value(65.0),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

/// Opens the SQLite connection pointing to the app's documents directory.
QueryExecutor _openConnection() {
  return driftDatabase(name: 'lifetracker_local');
}
