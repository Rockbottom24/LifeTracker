import '../models/barcode_lookup_response.dart';
import '../models/create_food_request.dart';
import '../models/food_category.dart';
import '../models/food_response.dart';
import '../models/scanned_food.dart';
import '../models/serving_unit.dart';
import '../models/update_food_request.dart';
import 'api_client.dart';

class FoodService {
  FoodService({required this._apiClient});

  final ApiClient _apiClient;

  Future<List<FoodResponse>> getFoods() async {
    return _apiClient.get<List<FoodResponse>>(
      '/foods',
      parser: _parseFoodList,
    );
  }

  Future<List<FoodResponse>> searchFoods(String query) async {
    return _apiClient.get<List<FoodResponse>>(
      '/foods/search',
      queryParameters: {'query': query},
      parser: _parseFoodList,
    );
  }

  Future<FoodResponse> getFood(int id) async {
    return _apiClient.get<FoodResponse>(
      '/foods/$id',
      parser: _parseFood,
    );
  }

  Future<FoodResponse> createFood(CreateFoodRequest request) async {
    return _apiClient.post<FoodResponse>(
      '/foods',
      data: request.toJson(),
      parser: _parseFood,
    );
  }

  Future<FoodResponse> createFoodFromScannedFood(ScannedFood scannedFood) async {
    return createFood(
      CreateFoodRequest(
        name: scannedFood.name,
        category: FoodCategory.other,
        servingUnit: ServingUnit.gram,
        referenceQuantity: 1,
        referenceWeight: 100,
        calories: scannedFood.calories,
        protein: scannedFood.protein,
        carbs: scannedFood.carbs,
        fat: scannedFood.fat,
        fiber: scannedFood.fiber,
        barcode: scannedFood.barcode,
        brand: scannedFood.brand,
        imageUrl: scannedFood.imageUrl,
        source: scannedFood.source.isNotEmpty ? scannedFood.source : 'OPEN_FOOD_FACTS',
      ),
    );
  }

  Future<FoodResponse> updateFood(int id, UpdateFoodRequest request) async {
    return _apiClient.put<FoodResponse>(
      '/foods/$id',
      data: request.toJson(),
      parser: _parseFood,
    );
  }

  Future<void> deleteFood(int id) async {
    await _apiClient.delete<void>(
      '/foods/$id',
      parser: (_) {},
    );
  }

  Future<ScannedFood> lookupBarcode(String barcode) async {
    final response = await _apiClient.get<BarcodeLookupResponse>(
      '/foods/barcode/$barcode',
      parser: _parseBarcodeLookupResponse,
    );

    if (!response.found || response.food == null) {
      throw ApiException('Product not found', statusCode: 404);
    }

    return response.food!;
  }

  List<FoodResponse> _parseFoodList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => FoodResponse.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  FoodResponse _parseFood(dynamic data) {
    return FoodResponse.fromJson(Map<String, dynamic>.from(data as Map));
  }

  BarcodeLookupResponse _parseBarcodeLookupResponse(dynamic data) {
    return BarcodeLookupResponse.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }
}
