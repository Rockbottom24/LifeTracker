import '../models/serving_unit.dart';
import '../models/food_category.dart';
import '../models/food_response.dart';
import '../utils/meal_nutrition_calculator.dart';

class ScannedFood {
  final int? foodId;
  final bool local;
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String source;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  final String servingSizeText;
  final ServingUnit? servingUnit;
  final double? referenceQuantity;
  final double? referenceWeight;
  final double? gramsPerPiece;
  final ServingUnit? householdUnit;
  final double? householdQuantity;
  final double? householdGrams;
  final List<ServingUnit> supportedUnits;

  const ScannedFood({
    this.foodId,
    this.local = false,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    this.source = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.servingSizeText = '',
    this.servingUnit,
    this.referenceQuantity,
    this.referenceWeight,
    this.gramsPerPiece,
    this.householdUnit,
    this.householdQuantity,
    this.householdGrams,
    this.supportedUnits = const [],
  });

  factory ScannedFood.fromJson(Map<String, dynamic> json) {
    return ScannedFood(
      foodId: _toInt(json['foodId']),
      local: json['local'] == true,
      barcode: json['barcode']?.toString() ?? '',
      name: json['productName']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      calories: _toDouble(json['calories']),
      protein: _toDouble(json['protein']),
      carbs: _toDouble(json['carbs']),
      fat: _toDouble(json['fat']),
      fiber: _toDouble(json['fiber']),
      servingSizeText: json['servingSizeText']?.toString() ?? '',
      servingUnit: ServingUnit.tryFromApiValue(json['servingUnit']?.toString()),
      referenceQuantity: _toNullableDouble(json['referenceQuantity']),
      referenceWeight: _toNullableDouble(json['referenceWeight']),
      gramsPerPiece: _toNullableDouble(json['gramsPerPiece']),
      householdUnit: ServingUnit.tryFromApiValue(json['householdUnit']?.toString()),
      householdQuantity: _toNullableDouble(json['householdQuantity']),
      householdGrams: _toNullableDouble(json['householdGrams']),
      supportedUnits: _parseSupportedUnits(json['supportedUnits']),
    );
  }

  FoodResponse toFoodResponse() {
    return FoodResponse(
      id: foodId ?? 0,
      uuid: '',
      name: name,
      category: FoodCategory.other,
      servingUnit: servingUnit ?? ServingUnit.gram,
      referenceQuantity: referenceQuantity ?? 100,
      referenceWeight: referenceWeight ?? 100,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      system: false,
      barcode: barcode,
      brand: brand,
      imageUrl: imageUrl,
      source: source,
      gramsPerPiece: gramsPerPiece,
      householdUnit: householdUnit,
      householdQuantity: householdQuantity,
      householdGrams: householdGrams,
    );
  }

  List<ServingUnit> get effectiveSupportedUnits {
    final list = supportedUnits.isNotEmpty ? supportedUnits : [servingUnit ?? ServingUnit.gram, ServingUnit.gram];
    final Set<ServingUnit> uniqueUnits = list.toSet();
    final food = toFoodResponse();
    return uniqueUnits.where((unit) {
      try {
        MealNutritionCalculator.resolveScaleFactor(quantity: 1.0, unit: unit, food: food);
        return true;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  static List<ServingUnit> _parseSupportedUnits(dynamic value) {
    if (value is! List) return const [];
    final units = <ServingUnit>[];
    for (final item in value) {
      final unit = ServingUnit.tryFromApiValue(item?.toString());
      if (unit != null) units.add(unit);
    }
    return units;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
