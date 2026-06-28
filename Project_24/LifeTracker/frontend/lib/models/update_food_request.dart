import 'food_category.dart';
import 'serving_unit.dart';

class UpdateFoodRequest {
  const UpdateFoodRequest({
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
    this.barcode,
    this.brand,
    this.imageUrl,
    this.source,
  });

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
  final String? barcode;
  final String? brand;
  final String? imageUrl;
  final String? source;

  Map<String, dynamic> toJson() {
    final payload = {
      'name': name,
      'category': category.apiValue,
      'servingUnit': servingUnit.apiValue,
      'referenceQuantity': referenceQuantity,
      'referenceWeight': referenceWeight,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
    if (barcode != null && barcode!.trim().isNotEmpty) {
      payload['barcode'] = barcode!.trim();
    }
    if (brand != null && brand!.trim().isNotEmpty) {
      payload['brand'] = brand!.trim();
    }
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      payload['imageUrl'] = imageUrl!.trim();
    }
    if (source != null && source!.trim().isNotEmpty) {
      payload['source'] = source!.trim();
    }
    return payload;
  }
}
