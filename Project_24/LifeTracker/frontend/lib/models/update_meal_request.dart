import 'create_meal_request.dart';
import 'meal_type.dart';

class UpdateMealRequest {
  const UpdateMealRequest({
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
    return CreateMealRequest(
      mealType: mealType,
      mealDate: mealDate,
      notes: notes,
      items: items,
    ).toJson();
  }
}
