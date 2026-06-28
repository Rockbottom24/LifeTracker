import 'meal_type.dart';
import 'serving_unit.dart';

class MealItemResponse {
  const MealItemResponse({
    required this.id,
    required this.foodItemId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.displayOrder,
  });

  final int id;
  final int foodItemId;
  final String foodName;
  final double quantity;
  final ServingUnit unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int displayOrder;

  factory MealItemResponse.fromJson(Map<String, dynamic> json) {
    return MealItemResponse(
      id: _toInt(json['id']) ?? 0,
      foodItemId: _toInt(json['foodItemId']) ?? 0,
      foodName: json['foodName'] as String? ?? '',
      quantity: _toDouble(json['quantity']),
      unit: ServingUnit.fromApiValue(json['unit']?.toString()),
      calories: _toDouble(json['calories']),
      protein: _toDouble(json['protein']),
      carbs: _toDouble(json['carbs']),
      fat: _toDouble(json['fat']),
      fiber: _toDouble(json['fiber']),
      displayOrder: _toInt(json['displayOrder']) ?? 0,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class MealResponse {
  const MealResponse({
    required this.id,
    required this.uuid,
    required this.mealType,
    required this.mealDate,
    this.notes,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
  });

  final int id;
  final String uuid;
  final MealType mealType;
  final DateTime mealDate;
  final String? notes;
  final List<MealItemResponse> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;

  factory MealResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return MealResponse(
      id: _toInt(json['id']) ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      mealType: MealType.fromApiValue(json['mealType']?.toString()),
      mealDate: DateTime.parse(json['mealDate'].toString()),
      notes: json['notes'] as String?,
      items: itemsJson is List
          ? itemsJson
              .whereType<Map>()
              .map((item) => MealItemResponse.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      totalCalories: _toDouble(json['totalCalories']),
      totalProtein: _toDouble(json['totalProtein']),
      totalCarbs: _toDouble(json['totalCarbs']),
      totalFat: _toDouble(json['totalFat']),
      totalFiber: _toDouble(json['totalFiber']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
