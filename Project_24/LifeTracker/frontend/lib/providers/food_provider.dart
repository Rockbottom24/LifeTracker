import 'package:flutter/foundation.dart';

import '../models/create_food_request.dart';
import '../models/food_response.dart';
import '../models/scanned_food.dart';
import '../models/update_food_request.dart';
import '../services/api_client.dart';
import '../services/food_service.dart';

class FoodProvider extends ChangeNotifier {
  FoodProvider(this._service);

  final FoodService _service;

  bool isLoading = false;
  bool isRefreshing = false;
  bool isSaving = false;
  bool isSearching = false;
  String? errorMessage;
  List<FoodResponse> foods = [];
  String searchQuery = '';

  ScannedFood? scannedFood;
  bool isLookingUpBarcode = false;

  List<FoodResponse> get systemFoods =>
      foods.where((food) => food.system).toList();

  List<FoodResponse> get customFoods =>
      foods.where((food) => !food.system).toList();

  bool get isSearchActive => searchQuery.trim().isNotEmpty;

  FoodResponse? findFoodById(int id) {
    for (final food in foods) {
      if (food.id == id) return food;
    }
    return null;
  }

  Future<void> loadFoods() async {
    final hadCachedData = foods.isNotEmpty;
    isLoading = !hadCachedData;
    isRefreshing = hadCachedData;
    if (!hadCachedData) {
      errorMessage = null;
    }
    notifyListeners();

    try {
      foods = await _service.getFoods();
      searchQuery = '';
      errorMessage = null;
    } on ApiException catch (e) {
      if (foods.isEmpty) {
        errorMessage = e.message;
      }
    } catch (e) {
      if (foods.isEmpty) {
        errorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> searchFoods(String query) async {
    searchQuery = query;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await loadFoods();
      return;
    }

    isSearching = true;
    errorMessage = null;
    notifyListeners();

    try {
      foods = await _service.searchFoods(trimmed);
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<FoodResponse?> createFood(CreateFoodRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final food = await _service.createFood(request);
      await loadFoods();
      return food;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<FoodResponse?> getFoodById(int id) async {
    final cached = findFoodById(id);
    if (cached != null) {
      return cached;
    }

    try {
      final food = await _service.getFood(id);
      foods = [...foods, food];
      notifyListeners();
      return food;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateFood(int id, UpdateFoodRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.updateFood(id, request);
      foods = foods.map((food) => food.id == id ? updated : food).toList();
      notifyListeners();
      await loadFoods();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteFood(int id) async {
    try {
      await _service.deleteFood(id);
      foods = foods.where((food) => food.id != id).toList();
      notifyListeners();
      await loadFoods();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<ScannedFood?> lookupBarcode(String barcode) async {
    isLookingUpBarcode = true;
    scannedFood = null;
    errorMessage = null;
    notifyListeners();

    try {
      scannedFood = await _service.lookupBarcode(barcode);
      return scannedFood;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return null;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLookingUpBarcode = false;
      notifyListeners();
    }
  }

  Future<FoodResponse?> saveScannedFood(ScannedFood scannedFood) async {
    if (scannedFood.foodId != null) {
      errorMessage = 'This barcode is already saved in your Food Library.';
      notifyListeners();
      return null;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final created = await _service.createFoodFromScannedFood(scannedFood);
      await loadFoods();
      return created;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        errorMessage = 'This barcode already exists in your Food Library.';
      } else {
        errorMessage = e.message;
      }
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<FoodResponse?> resolveScannedFoodForMeal(ScannedFood scannedFood) async {
    if (scannedFood.foodId != null) {
      return getFoodById(scannedFood.foodId!);
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final created = await _service.createFoodFromScannedFood(scannedFood);
      await loadFoods();
      return created;
    } on ApiException catch (e) {
      if (e.statusCode != 409) {
        errorMessage = e.message;
        notifyListeners();
        return null;
      }

      final local = await _service.lookupBarcode(scannedFood.barcode);
      if (local.foodId != null) {
        return getFoodById(local.foodId!);
      }

      errorMessage = 'Unable to resolve this barcode from the Food Library.';
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
