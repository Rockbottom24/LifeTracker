import '../models/food_category.dart';
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

/// Result of a nutrition conversion. Failed conversions expose [error]
/// instead of silently returning zeros.
class MealNutritionResult {
  const MealNutritionResult._({this.summary, this.error});

  factory MealNutritionResult.success(MealNutritionSummary summary) {
    return MealNutritionResult._(summary: summary);
  }

  factory MealNutritionResult.failure(String error) {
    return MealNutritionResult._(error: error);
  }

  final MealNutritionSummary? summary;
  final String? error;

  bool get isSuccess => summary != null && error == null;
  bool get hasError => error != null;
}

class NutritionCalculationException implements Exception {
  NutritionCalculationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Frontend mirror of backend [MealNutritionCalculator] + [FoodConversionContext].
class MealNutritionCalculator {
  const MealNutritionCalculator._();

  static const int _outputScale = 2;
  static const double _tbspToTsp = 3;

  static double resolveScaleFactor({
    required double quantity,
    required ServingUnit unit,
    required FoodResponse food,
  }) {
    validateFoodConfiguration(food);

    if (quantity <= 0) {
      throw NutritionCalculationException('Quantity must be greater than zero');
    }

    final referenceUnit = food.servingUnit;
    final referenceQuantity = food.referenceQuantity;
    final referenceWeight = food.referenceWeight;

    if (unit == referenceUnit) {
      return quantity / referenceQuantity;
    }

    if (_isMassUnit(unit)) {
      return _toGrams(quantity, unit) / referenceWeight;
    }

    if (_isVolumeUnit(unit) && _isVolumeUnit(referenceUnit)) {
      return _toMilliliters(quantity, unit) / _toMilliliters(referenceQuantity, referenceUnit);
    }

    // Piece/count via grams-per-piece against mass nutrition basis.
    if (unit == ServingUnit.piece && food.hasPieceConversion) {
      final gramsPerPiece = food.resolvedGramsPerPiece!;
      final consumedGrams = quantity * gramsPerPiece;
      return consumedGrams / referenceWeight;
    }

    // Household label conversions (e.g. 2 tbsp = 32 g).
    final householdGrams = _resolveHouseholdGrams(quantity, unit, food);
    if (householdGrams != null) {
      return householdGrams / referenceWeight;
    }

    // tbsp <-> tsp when food reference itself is tbsp/tsp.
    if (_isTbspTspPair(unit, referenceUnit)) {
      final asReferenceUnit = _convertTbspTsp(quantity, unit, referenceUnit);
      return asReferenceUnit / referenceQuantity;
    }

    if (_isVolumeUnit(unit) && _isMassUnit(referenceUnit)) {
      throw NutritionCalculationException(
        'Cannot convert volume unit ${unit.apiValue} to mass-based nutrition without density metadata',
      );
    }

    if (unit == ServingUnit.piece) {
      throw NutritionCalculationException(
        'This food does not have enough serving information to calculate pieces. '
        'Use grams or define grams per piece.',
      );
    }

    if (unit == ServingUnit.tablespoon ||
        unit == ServingUnit.teaspoon ||
        unit == ServingUnit.serving) {
      throw NutritionCalculationException(
        'This food does not have enough serving information to calculate '
        '${unit.label.toLowerCase()}. Use grams or define a serving conversion.',
      );
    }

    throw NutritionCalculationException(
      'Incompatible quantity unit ${unit.apiValue} for food serving unit ${referenceUnit.apiValue}',
    );
  }

  /// Backward-compatible overload without household/piece metadata on the food.
  static double resolveScaleFactorLegacy({
    required double quantity,
    required ServingUnit unit,
    required ServingUnit referenceUnit,
    required double referenceQuantity,
    required double referenceWeight,
  }) {
    return resolveScaleFactor(
      quantity: quantity,
      unit: unit,
      food: FoodResponse(
        id: 0,
        uuid: '',
        name: '',
        category: FoodCategory.other,
        servingUnit: referenceUnit,
        referenceQuantity: referenceQuantity,
        referenceWeight: referenceWeight,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        system: false,
      ),
    );
  }

  static void validateFoodConfiguration(FoodResponse food) {
    if (food.referenceQuantity <= 0) {
      throw NutritionCalculationException('Food reference quantity must be greater than zero');
    }
    if (food.referenceWeight <= 0) {
      throw NutritionCalculationException(
        'Food reference weight (grams per reference serving) must be greater than zero',
      );
    }
    if (food.gramsPerPiece != null && food.gramsPerPiece! <= 0) {
      throw NutritionCalculationException('Grams per piece must be greater than zero when provided');
    }
    final hasAnyHousehold = food.householdUnit != null ||
        food.householdQuantity != null ||
        food.householdGrams != null;
    if (hasAnyHousehold && !food.hasHouseholdConversion) {
      throw NutritionCalculationException(
        'Household serving conversion requires unit, positive quantity, and positive grams',
      );
    }
  }

  static MealNutritionResult fromFood(FoodResponse food, double quantity, ServingUnit unit) {
    if (quantity <= 0) {
      return MealNutritionResult.success(MealNutritionSummary.zero);
    }
    try {
      final factor = resolveScaleFactor(quantity: quantity, unit: unit, food: food);
      return MealNutritionResult.success(
        MealNutritionSummary(
          calories: _round(food.calories * factor),
          protein: _round(food.protein * factor),
          carbs: _round(food.carbs * factor),
          fat: _round(food.fat * factor),
          fiber: _round(food.fiber * factor),
        ),
      );
    } on NutritionCalculationException catch (e) {
      return MealNutritionResult.failure(e.message);
    } on ArgumentError catch (e) {
      return MealNutritionResult.failure(e.message ?? 'Unable to convert this serving unit.');
    }
  }

  static double? _resolveHouseholdGrams(double quantity, ServingUnit unit, FoodResponse food) {
    if (!food.hasHouseholdConversion) {
      if (unit == ServingUnit.serving && _isDiscreteUnit(food.servingUnit)) {
        return quantity * (food.referenceWeight / food.referenceQuantity);
      }
      return null;
    }

    final gramsPerHouseholdUnit = food.householdGrams! / food.householdQuantity!;

    if (unit == ServingUnit.serving) {
      return quantity * food.householdGrams!;
    }

    if (unit == food.householdUnit) {
      return quantity * gramsPerHouseholdUnit;
    }

    if (_isTbspTspPair(unit, food.householdUnit!)) {
      final asHouseholdUnit = _convertTbspTsp(quantity, unit, food.householdUnit!);
      return asHouseholdUnit * gramsPerHouseholdUnit;
    }

    return null;
  }

  static bool _isTbspTspPair(ServingUnit a, ServingUnit b) {
    return (a == ServingUnit.tablespoon && b == ServingUnit.teaspoon) ||
        (a == ServingUnit.teaspoon && b == ServingUnit.tablespoon);
  }

  static double _convertTbspTsp(double quantity, ServingUnit from, ServingUnit to) {
    if (from == to) return quantity;
    if (from == ServingUnit.tablespoon && to == ServingUnit.teaspoon) {
      return quantity * _tbspToTsp;
    }
    if (from == ServingUnit.teaspoon && to == ServingUnit.tablespoon) {
      return quantity / _tbspToTsp;
    }
    throw NutritionCalculationException('Cannot convert ${from.apiValue} to ${to.apiValue}');
  }

  static double _toGrams(double quantity, ServingUnit unit) {
    return switch (unit) {
      ServingUnit.gram => quantity,
      ServingUnit.kilogram => quantity * 1000,
      _ => throw NutritionCalculationException('Unit ${unit.apiValue} is not a mass unit'),
    };
  }

  static double _toMilliliters(double quantity, ServingUnit unit) {
    return switch (unit) {
      ServingUnit.ml => quantity,
      ServingUnit.liter => quantity * 1000,
      _ => throw NutritionCalculationException('Unit ${unit.apiValue} is not a volume unit'),
    };
  }

  static bool _isMassUnit(ServingUnit unit) =>
      unit == ServingUnit.gram || unit == ServingUnit.kilogram;

  static bool _isVolumeUnit(ServingUnit unit) =>
      unit == ServingUnit.ml || unit == ServingUnit.liter;

  static bool _isDiscreteUnit(ServingUnit unit) =>
      unit == ServingUnit.piece ||
      unit == ServingUnit.scoop ||
      unit == ServingUnit.tablespoon ||
      unit == ServingUnit.teaspoon ||
      unit == ServingUnit.cup ||
      unit == ServingUnit.serving;

  static double _round(double value) {
    return double.parse(value.toStringAsFixed(_outputScale));
  }
}
