import 'package:flutter_test/flutter_test.dart';
import 'package:lifetracker/models/food_category.dart';
import 'package:lifetracker/models/food_response.dart';
import 'package:lifetracker/models/serving_unit.dart';
import 'package:lifetracker/utils/meal_nutrition_calculator.dart';

void main() {
  FoodResponse chicken({
    double calories = 165,
    double protein = 31,
    double carbs = 0,
    double fat = 3.6,
    double fiber = 0,
  }) {
    return FoodResponse(
      id: 1,
      uuid: 'chicken',
      name: 'Chicken Breast',
      category: FoodCategory.meat,
      servingUnit: ServingUnit.gram,
      referenceQuantity: 100,
      referenceWeight: 100,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      system: true,
    );
  }

  FoodResponse banana() {
    return FoodResponse(
      id: 2,
      uuid: 'banana',
      name: 'Banana',
      category: FoodCategory.fruits,
      servingUnit: ServingUnit.piece,
      referenceQuantity: 1,
      referenceWeight: 118,
      calories: 105,
      protein: 1.3,
      carbs: 27,
      fat: 0.4,
      fiber: 3.1,
      system: true,
    );
  }

  FoodResponse almonds() {
    return FoodResponse(
      id: 4,
      uuid: 'almonds',
      name: 'Almonds',
      category: FoodCategory.other,
      servingUnit: ServingUnit.gram,
      referenceQuantity: 100,
      referenceWeight: 100,
      calories: 579,
      protein: 21,
      carbs: 22,
      fat: 50,
      fiber: 12,
      system: true,
      gramsPerPiece: 1.2,
      supportedUnits: const [ServingUnit.gram, ServingUnit.kilogram, ServingUnit.piece],
    );
  }

  FoodResponse peanutButter() {
    return FoodResponse(
      id: 5,
      uuid: 'pb',
      name: 'Peanut Butter',
      category: FoodCategory.other,
      servingUnit: ServingUnit.gram,
      referenceQuantity: 100,
      referenceWeight: 100,
      calories: 588,
      protein: 25,
      carbs: 20,
      fat: 50,
      fiber: 6,
      system: true,
      householdUnit: ServingUnit.tablespoon,
      householdQuantity: 2,
      householdGrams: 32,
      supportedUnits: const [
        ServingUnit.gram,
        ServingUnit.tablespoon,
        ServingUnit.teaspoon,
        ServingUnit.serving,
      ],
    );
  }

  test('100 g food consumed as 100 g', () {
    final result = MealNutritionCalculator.fromFood(chicken(), 100, ServingUnit.gram);
    expect(result.isSuccess, isTrue);
    expect(result.summary!.calories, 165);
    expect(result.summary!.protein, 31);
  });

  test('100 g food consumed as 50 g', () {
    final result = MealNutritionCalculator.fromFood(chicken(), 50, ServingUnit.gram);
    expect(result.summary!.calories, 82.5);
    expect(result.summary!.protein, 15.5);
  });

  test('kilogram conversion', () {
    final result = MealNutritionCalculator.fromFood(chicken(), 0.5, ServingUnit.kilogram);
    expect(result.summary!.calories, 825);
    expect(result.summary!.protein, 155);
  });

  test('piece food with known grams per piece', () {
    final result = MealNutritionCalculator.fromFood(banana(), 1, ServingUnit.piece);
    expect(result.summary!.calories, 105);
    expect(result.summary!.carbs, 27);
  });

  test('multiple pieces', () {
    final result = MealNutritionCalculator.fromFood(banana(), 3, ServingUnit.piece);
    expect(result.summary!.calories, 315);
    expect(result.summary!.fiber, 9.3);
  });

  test('ten almonds using piece quantity via gramsPerPiece', () {
    final result = MealNutritionCalculator.fromFood(almonds(), 10, ServingUnit.piece);
    expect(result.isSuccess, isTrue);
    // 12 g / 100 g = 0.12
    expect(result.summary!.calories, 69.48);
    expect(result.summary!.protein, 2.52);
  });

  test('peanut butter one tablespoon via household metadata', () {
    final result = MealNutritionCalculator.fromFood(peanutButter(), 1, ServingUnit.tablespoon);
    expect(result.isSuccess, isTrue);
    // 16g / 100 = 0.16
    expect(result.summary!.calories, 94.08);
    expect(result.summary!.protein, 4.0);
  });

  test('unsupported tablespoon returns error not zero macros', () {
    final result = MealNutritionCalculator.fromFood(chicken(), 1, ServingUnit.tablespoon);
    expect(result.hasError, isTrue);
    expect(result.summary, isNull);
    expect(
      result.error!.toLowerCase(),
      anyOf(contains('tablespoon'), contains('serving information')),
    );
  });

  test('all macros share the same factor', () {
    final factor = MealNutritionCalculator.resolveScaleFactor(
      quantity: 150,
      unit: ServingUnit.gram,
      food: chicken(),
    );
    expect(factor, 1.5);
    final result = MealNutritionCalculator.fromFood(chicken(), 150, ServingUnit.gram);
    expect(result.summary!.calories, 247.5);
    expect(result.summary!.protein, 46.5);
    expect(result.summary!.fat, 5.4);
  });

  test('liter to milliliter conversion', () {
    final milk = FoodResponse(
      id: 3,
      uuid: 'milk',
      name: 'Milk',
      category: FoodCategory.dairy,
      servingUnit: ServingUnit.ml,
      referenceQuantity: 250,
      referenceWeight: 250,
      calories: 149,
      protein: 7.7,
      carbs: 12,
      fat: 8,
      fiber: 0,
      system: true,
    );
    final result = MealNutritionCalculator.fromFood(milk, 1, ServingUnit.liter);
    expect(result.summary!.calories, 596);
    expect(result.summary!.protein, 30.8);
  });

  test('invalid piece configuration is rejected', () {
    expect(
      () => MealNutritionCalculator.resolveScaleFactor(
        quantity: 1,
        unit: ServingUnit.piece,
        food: FoodResponse(
          id: 0,
          uuid: '',
          name: '',
          category: FoodCategory.other,
          servingUnit: ServingUnit.piece,
          referenceQuantity: 1,
          referenceWeight: 0,
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          fiber: 0,
          system: false,
        ),
      ),
      throwsA(isA<NutritionCalculationException>()),
    );
  });

  test('volume on mass food without density is rejected', () {
    expect(
      () => MealNutritionCalculator.resolveScaleFactor(
        quantity: 100,
        unit: ServingUnit.ml,
        food: chicken(),
      ),
      throwsA(isA<NutritionCalculationException>()),
    );
  });
}
