import 'package:flutter/material.dart';

import '../screens/daily_performance_detail_screen.dart';
import '../screens/expense_details_screen.dart';
import '../screens/food_details_screen.dart';
import '../screens/habit_details_screen.dart';
import '../screens/learning_details_screen.dart';
import '../screens/meal_details_screen.dart';
import '../screens/profile_screen.dart';

class AppNavigator {
  const AppNavigator._();

  static Future<void> openHabitDetails(BuildContext context, int habitId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitDetailsScreen(habitId: habitId),
      ),
    );
  }

  static Future<void> openLearningDetails(BuildContext context, int sessionId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningDetailsScreen(sessionId: sessionId),
      ),
    );
  }

  static Future<void> openExpenseDetails(BuildContext context, int expenseId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailsScreen(expenseId: expenseId),
      ),
    );
  }

  static Future<void> openFoodDetails(BuildContext context, int foodId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/food-details/$foodId'),
        builder: (_) => FoodDetailsScreen(foodId: foodId),
      ),
    );
  }

  static Future<void> openMealDetails(BuildContext context, int mealId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/meal-details/$mealId'),
        builder: (_) => MealDetailsScreen(mealId: mealId),
      ),
    );
  }

  static Future<void> openProfile(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/profile'),
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  static Future<void> openDailyPerformance(BuildContext context, DateTime date) {
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/profile/performance/$dateKey'),
        builder: (_) => DailyPerformanceDetailScreen(date: date),
      ),
    );
  }
}
