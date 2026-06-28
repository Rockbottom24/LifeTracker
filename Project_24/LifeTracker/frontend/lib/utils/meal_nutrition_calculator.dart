import '../models/food_response.dart';
import '../models/serving_unit.dart';

class MealNutritionSummary {
  const MealNutritionSummary({
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

  static const zero = MealNutritionSummary(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
  );

  MealNutritionSummary operator +(MealNutritionSummary other) {
    return MealNutritionSummary(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
    );
  }
}

class MealNutritionCalculator {
  const MealNutritionCalculator._();

  static double toGramEquivalent(double quantity, ServingUnit unit) {
    return switch (unit) {
      ServingUnit.gram => quantity,
      ServingUnit.ml => quantity,
      ServingUnit.piece => quantity * 50,
      ServingUnit.scoop => quantity * 30,
      ServingUnit.tablespoon => quantity * 13.5,
      ServingUnit.teaspoon => quantity * 5,
      ServingUnit.cup => quantity * 240,
    };
  }

  static double calculate(
    double perServing,
    double quantity,
    ServingUnit unit,
    double referenceWeight,
  ) {
    if (perServing <= 0 || quantity <= 0 || referenceWeight <= 0) {
      return 0;
    }
    final grams = toGramEquivalent(quantity, unit);
    return perServing * (grams / referenceWeight);
  }

  static MealNutritionSummary fromFood(FoodResponse food, double quantity, ServingUnit unit) {
    return MealNutritionSummary(
      calories: calculate(food.calories, quantity, unit, food.referenceWeight),
      protein: calculate(food.protein, quantity, unit, food.referenceWeight),
      carbs: calculate(food.carbs, quantity, unit, food.referenceWeight),
      fat: calculate(food.fat, quantity, unit, food.referenceWeight),
      fiber: calculate(food.fiber, quantity, unit, food.referenceWeight),
    );
  }
}
