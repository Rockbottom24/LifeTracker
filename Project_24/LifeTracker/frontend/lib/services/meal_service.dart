import '../models/create_meal_request.dart';
import '../models/food_response.dart';
import '../models/meal_response.dart';
import '../models/meal_type.dart';
import '../models/serving_unit.dart';
import '../models/update_meal_request.dart';
import 'api_client.dart';

class MealService {
  MealService({required this._apiClient});

  final ApiClient _apiClient;

  Future<List<MealResponse>> getTodayMeals() async {
    return _apiClient.get<List<MealResponse>>(
      '/meals/today',
      parser: _parseMealList,
    );
  }

  Future<List<MealResponse>> getMealsForDate(DateTime date) async {
    final formatted = _formatDate(date);
    return _apiClient.get<List<MealResponse>>(
      '/meals/date/$formatted',
      parser: _parseMealList,
    );
  }

  Future<MealResponse> getMeal(int id) async {
    return _apiClient.get<MealResponse>(
      '/meals/$id',
      parser: _parseMeal,
    );
  }

  Future<MealResponse> createMeal(CreateMealRequest request) async {
    return _apiClient.post<MealResponse>(
      '/meals',
      data: request.toJson(),
      parser: _parseMeal,
    );
  }

  Future<MealResponse> createMealFromFood({
    required FoodResponse food,
    required double quantity,
    required ServingUnit unit,
    required MealType mealType,
    DateTime? mealDate,
    String? notes,
  }) {
    return createMeal(
      CreateMealRequest(
        mealType: mealType,
        mealDate: mealDate ?? DateTime.now(),
        notes: notes,
        items: [
          MealItemRequest(
            foodItemId: food.id,
            quantity: quantity,
            unit: unit,
          ),
        ],
      ),
    );
  }

  Future<MealResponse> updateMeal(int id, UpdateMealRequest request) async {
    return _apiClient.put<MealResponse>(
      '/meals/$id',
      data: request.toJson(),
      parser: _parseMeal,
    );
  }

  Future<void> deleteMeal(int id) async {
    await _apiClient.delete<void>(
      '/meals/$id',
      parser: (_) {},
    );
  }

  Future<List<MealResponse>> duplicateYesterday(MealType mealType, {DateTime? date}) async {
    final query = <String, dynamic>{
      'mealType': mealType.apiValue,
      if (date != null) 'date': _formatDate(date),
    };
    return _apiClient.post<List<MealResponse>>(
      '/meals/duplicate-yesterday',
      queryParameters: query,
      parser: _parseMealList,
    );
  }

  Future<void> clearMealsForType(MealType mealType, {DateTime? date}) async {
    final query = <String, dynamic>{
      'mealType': mealType.apiValue,
      if (date != null) 'date': _formatDate(date),
    };
    await _apiClient.delete<void>(
      '/meals/clear',
      queryParameters: query,
      parser: (_) {},
    );
  }

  List<MealResponse> _parseMealList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => MealResponse.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  MealResponse _parseMeal(dynamic data) {
    return MealResponse.fromJson(Map<String, dynamic>.from(data as Map));
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
