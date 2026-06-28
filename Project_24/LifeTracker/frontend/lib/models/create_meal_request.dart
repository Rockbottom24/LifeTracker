import 'meal_type.dart';
import 'serving_unit.dart';

class MealItemRequest {
  const MealItemRequest({
    required this.foodItemId,
    required this.quantity,
    required this.unit,
  });

  final int foodItemId;
  final double quantity;
  final ServingUnit unit;

  Map<String, dynamic> toJson() {
    return {
      'foodItemId': foodItemId,
      'quantity': quantity,
      'unit': unit.apiValue,
    };
  }
}

class CreateMealRequest {
  const CreateMealRequest({
    required this.mealType,
    required this.mealDate,
    this.notes,
    required this.items,
  });

  final MealType mealType;
  final DateTime mealDate;
  final String? notes;
  final List<MealItemRequest> items;

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType.apiValue,
      'mealDate': _formatDate(mealDate),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
