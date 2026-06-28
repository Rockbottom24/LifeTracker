import '../models/macro_progress_item.dart';
import '../models/meal_response.dart';
import '../models/nutrition_goals_response.dart';

class NutritionDashboardMapper {
  const NutritionDashboardMapper._();

  static List<MacroProgressItem> buildProgress(
    List<MealResponse> meals,
    NutritionGoalsResponse goals,
  ) {
    final consumed = _sumMeals(meals);
    return [
      _buildItem('CALORIES', 'Calories', consumed.calories, goals.calorieGoal, 'kcal'),
      _buildItem('PROTEIN', 'Protein', consumed.protein, goals.proteinGoal, 'g'),
      _buildItem('CARBS', 'Carbohydrates', consumed.carbs, goals.carbsGoal, 'g'),
      _buildItem('FAT', 'Fat', consumed.fat, goals.fatGoal, 'g'),
      _buildItem('FIBER', 'Fiber', consumed.fiber, goals.fiberGoal, 'g'),
    ];
  }

  static _ConsumedTotals _sumMeals(List<MealResponse> meals) {
    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    for (final meal in meals) {
      calories += meal.totalCalories;
      protein += meal.totalProtein;
      carbs += meal.totalCarbs;
      fat += meal.totalFat;
      fiber += meal.totalFiber;
    }
    return _ConsumedTotals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
    );
  }

  static MacroProgressItem _buildItem(
    String key,
    String label,
    double consumed,
    double goal,
    String unit,
  ) {
    final safeGoal = goal <= 0 ? 1 : goal;
    final remaining = (safeGoal - consumed).clamp(0.0, double.infinity).toDouble();
    final progressPercent = (consumed / safeGoal) * 100;
    return MacroProgressItem(
      key: key,
      label: label,
      consumed: consumed,
      goal: goal,
      remaining: remaining,
      progressPercent: progressPercent,
    );
  }
}

class _ConsumedTotals {
  const _ConsumedTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
}
