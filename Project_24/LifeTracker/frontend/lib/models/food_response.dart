import 'food_category.dart';
import 'serving_unit.dart';

class FoodResponse {
  const FoodResponse({
    required this.id,
    required this.uuid,
    required this.name,
    required this.category,
    required this.servingUnit,
    required this.referenceQuantity,
    required this.referenceWeight,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.system,
    this.barcode = '',
    this.brand = '',
    this.imageUrl = '',
    this.source = '',
  });

  final int id;
  final String uuid;
  final String name;
  final FoodCategory category;
  final ServingUnit servingUnit;
  final double referenceQuantity;
  final double referenceWeight;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final bool system;
  final String barcode;
  final String brand;
  final String imageUrl;
  final String source;

  factory FoodResponse.fromJson(Map<String, dynamic> json) {
    return FoodResponse(
      id: _toInt(json['id']) ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      category: FoodCategory.fromApiValue(json['category']?.toString()),
      servingUnit: ServingUnit.fromApiValue(json['servingUnit']?.toString()),
      referenceQuantity: _toDouble(json, 'referenceQuantity', fallbackKey: 'reference_quantity', fallbackValue: 100),
      referenceWeight: _toDouble(json, 'referenceWeight', fallbackKey: 'reference_weight', fallbackValue: 100),
      calories: _toDouble(json, 'calories', fallbackKey: 'caloriesPer100g'),
      protein: _toDouble(json, 'protein', fallbackKey: 'proteinPer100g'),
      carbs: _toDouble(json, 'carbs', fallbackKey: 'carbsPer100g'),
      fat: _toDouble(json, 'fat', fallbackKey: 'fatPer100g'),
      fiber: _toDouble(json, 'fiber', fallbackKey: 'fiberPer100g'),
      system: json['system'] as bool? ?? false,
      barcode: json['barcode']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }

  String get referenceServingLabel {
    final quantity = _formatAmount(referenceQuantity);
    return '$quantity ${servingUnit.label.toLowerCase()}';
  }

  String get referenceNutritionLabel {
    return 'per $referenceServingLabel';
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double _toDouble(
    Map<String, dynamic> json,
    String key, {
    String? fallbackKey,
    double fallbackValue = 0,
  }) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value != null) {
      return double.tryParse(value.toString()) ?? fallbackValue;
    }
    if (fallbackKey != null) {
      final fallback = json[fallbackKey];
      if (fallback is num) return fallback.toDouble();
      if (fallback != null) {
        return double.tryParse(fallback.toString()) ?? fallbackValue;
      }
    }
    return fallbackValue;
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}
