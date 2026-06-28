import 'package:flutter/material.dart';

import '../screens/expense_details_screen.dart';
import '../screens/food_details_screen.dart';
import '../screens/habit_details_screen.dart';
import '../screens/learning_details_screen.dart';
import '../screens/meal_details_screen.dart';

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
}
