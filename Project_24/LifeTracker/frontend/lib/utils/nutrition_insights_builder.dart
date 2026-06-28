import '../models/macro_progress_item.dart';
import '../models/meal_response.dart';
import '../models/nutrition_goals_response.dart';

class NutritionInsightsBuilder {
  const NutritionInsightsBuilder._();

  static List<String> build(
    NutritionGoalsResponse goals,
    List<MacroProgressItem> progress,
    List<MealResponse> meals,
  ) {
    final insights = <String>[];

    if (meals.isEmpty) {
      return ['Start logging meals to track your daily nutrition.'];
    }

    final calories = _find(progress, 'CALORIES');
    final protein = _find(progress, 'PROTEIN');
    final fiber = _find(progress, 'FIBER');

    if (protein != null && protein.consumed >= goals.proteinGoal) {
      insights.add('Protein goal achieved.');
    }

    if (fiber != null && goals.fiberGoal > 0 && fiber.consumed < goals.fiberGoal * 0.5) {
      insights.add('Fiber intake is low.');
    }

    if (calories != null && calories.remaining > 0) {
      insights.add('You still need ${calories.remaining.round()} kcal.');
    }

    if (calories != null && calories.consumed <= goals.calorieGoal && calories.consumed > 0) {
      insights.add('Great job staying below your calorie goal.');
    }

    if (calories != null && calories.consumed > goals.calorieGoal) {
      insights.add("You've exceeded your calorie goal today.");
    }

    final carbs = _find(progress, 'CARBS');
    if (carbs != null && carbs.consumed >= goals.carbsGoal) {
      insights.add('Carbohydrate goal reached.');
    }

    if (insights.isEmpty) {
      insights.add("Keep going — you're making steady progress today.");
    }

    return insights;
  }

  static MacroProgressItem? _find(List<MacroProgressItem> progress, String key) {
    for (final item in progress) {
      if (item.key == key) return item;
    }
    return null;
  }
}
