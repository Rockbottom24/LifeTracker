import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/create_food_request.dart';
import '../models/food_category.dart';
import '../models/food_response.dart';
import '../models/scanned_food.dart';
import '../models/serving_unit.dart';
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
    isLoading = false;
    isRefreshing = false;
    errorMessage = null;
    // Always seed local foods immediately so library is never empty
    foods = _builtInFoods();
    notifyListeners();
    _loadFoodsInBackground();
  }

  void _loadFoodsInBackground() async {
    try {
      final serverFoods = await _service.getFoods();
      // Merge: keep custom user foods + replace system foods with server data
      final customFoods = foods.where((f) => !f.system).toList();
      foods = [...serverFoods, ...customFoods];
      searchQuery = '';
      errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Server unavailable — built-in foods already showing
    }
  }

  /// 80+ common everyday foods seeded locally so the library works offline.
  static List<FoodResponse> _builtInFoods() {
    int id = -1; // Use negative IDs to avoid clashing with server IDs
    FoodResponse f(
      String name,
      String category,
      double cal,
      double protein,
      double carbs,
      double fat, {
      double fiber = 0,
      String unit = 'GRAM',
      double refQty = 100,
      double refWeight = 100,
    }) {
      return FoodResponse(
        id: id--,
        uuid: 'local-$name',
        name: name,
        category: FoodCategory.fromApiValue(category),
        servingUnit: ServingUnit.fromApiValue(unit),
        referenceQuantity: refQty,
        referenceWeight: refWeight,
        calories: cal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        system: true,
      );
    }

    return [
      // ── Meat & Poultry (Raw & Cooked) ──────────────────────────────────
      f('Chicken Breast (raw)', 'MEAT', 120, 22.5, 0, 2.6),
      f('Chicken Breast (cooked/grilled)', 'MEAT', 165, 31, 0, 3.6),
      f('Chicken Breast (boiled)', 'MEAT', 150, 29, 0, 3.0),
      f('Chicken Thigh (raw, skinless)', 'MEAT', 120, 20, 0, 4.5),
      f('Chicken Thigh (cooked/roasted)', 'MEAT', 209, 26, 0, 10.9),
      f('Chicken Drumstick (raw)', 'MEAT', 120, 19, 0, 4.8),
      f('Chicken Drumstick (cooked/grilled)', 'MEAT', 175, 24, 0, 8.5),
      f('Chicken Wings (raw)', 'MEAT', 191, 17.5, 0, 13),
      f('Chicken Wings (cooked/baked)', 'MEAT', 290, 27, 0, 19.5),
      f('Chicken Mince / Keema (raw)', 'MEAT', 143, 17.4, 0, 8.1),
      f('Chicken Mince / Keema (cooked)', 'MEAT', 220, 24, 0, 13.5),
      f('Mutton / Lamb (raw)', 'MEAT', 200, 20, 0, 13),
      f('Mutton / Lamb (cooked)', 'MEAT', 258, 25.6, 0, 16.5),
      f('Beef (lean, raw)', 'MEAT', 170, 21, 0, 9.5),
      f('Beef (lean, cooked)', 'MEAT', 250, 26, 0, 15),
      f('Pork (lean, raw)', 'MEAT', 145, 21, 0, 6.5),
      f('Pork (lean, cooked)', 'MEAT', 242, 27, 0, 14),

      // ── Eggs ─────────────────────────────────────────────────────────────
      f('Whole Egg (raw)', 'EGGS', 72, 6.3, 0.4, 4.8, unit: 'PIECE', refQty: 1, refWeight: 50),
      f('Whole Egg (boiled)', 'EGGS', 78, 6.3, 0.6, 5.3, unit: 'PIECE', refQty: 1, refWeight: 50),
      f('Whole Egg (fried/poached)', 'EGGS', 90, 6.3, 0.4, 7.0, unit: 'PIECE', refQty: 1, refWeight: 50),
      f('Egg White (raw)', 'EGGS', 17, 3.6, 0.2, 0.1, unit: 'PIECE', refQty: 1, refWeight: 33),
      f('Egg White (boiled)', 'EGGS', 17, 3.6, 0.2, 0.1, unit: 'PIECE', refQty: 1, refWeight: 33),
      f('Egg Yolk (raw/boiled)', 'EGGS', 55, 2.7, 0.6, 4.5, unit: 'PIECE', refQty: 1, refWeight: 17),
      f('Egg Omelette (2 eggs with oil)', 'EGGS', 210, 14, 1.2, 16, unit: 'PIECE', refQty: 1, refWeight: 110),

      // ── Seafood (Raw & Cooked) ──────────────────────────────────────────
      f('Salmon (raw)', 'SEAFOOD', 142, 20, 0, 6.3),
      f('Salmon (cooked/grilled)', 'SEAFOOD', 208, 22, 0, 13),
      f('Prawns / Shrimp (raw)', 'SEAFOOD', 85, 20, 0.2, 0.5),
      f('Prawns / Shrimp (cooked)', 'SEAFOOD', 99, 24, 0.2, 0.3),
      f('Tuna (raw/fresh)', 'SEAFOOD', 130, 28, 0, 1),
      f('Tuna (canned in water)', 'SEAFOOD', 116, 25.5, 0, 0.8),
      f('Rohu / Katla Fish (raw)', 'SEAFOOD', 97, 17, 0, 3.1),
      f('Rohu / Katla Fish (cooked/curry)', 'SEAFOOD', 165, 19, 2, 9),

      // ── Grains & Cereals (Raw & Cooked) ────────────────────────────────
      f('White Rice (raw/uncooked)', 'GRAINS', 365, 7.1, 80, 0.7, fiber: 1.3),
      f('White Rice (cooked/steamed)', 'GRAINS', 130, 2.7, 28.2, 0.3, fiber: 0.4),
      f('Brown Rice (raw/uncooked)', 'GRAINS', 362, 7.5, 76, 2.7, fiber: 3.4),
      f('Brown Rice (cooked)', 'GRAINS', 123, 2.7, 25.6, 0.9, fiber: 1.8),
      f('Basmati Rice (raw)', 'GRAINS', 350, 8.5, 78, 0.5, fiber: 1.0),
      f('Basmati Rice (cooked)', 'GRAINS', 121, 3.5, 25, 0.4, fiber: 0.4),
      f('Oats (raw/dry)', 'GRAINS', 389, 17, 66, 7, fiber: 10.6),
      f('Oats (cooked with water)', 'GRAINS', 71, 2.5, 12, 1.4, fiber: 1.7),
      f('Oats (cooked with milk)', 'GRAINS', 110, 5.2, 16.5, 3.1, fiber: 1.7),
      f('Pasta / Spaghetti (raw/dry)', 'GRAINS', 371, 13, 74, 1.5, fiber: 3.2),
      f('Pasta / Spaghetti (cooked)', 'GRAINS', 158, 5.8, 31, 0.9, fiber: 1.8),
      f('Quinoa (raw/dry)', 'GRAINS', 368, 14, 64, 6, fiber: 7.0),
      f('Quinoa (cooked)', 'GRAINS', 120, 4.4, 21.3, 1.9, fiber: 2.8),
      f('Whole Wheat Flour / Atta (raw)', 'GRAINS', 340, 13.2, 72, 2.5, fiber: 10.7),
      f('Chapati / Roti (whole wheat)', 'GRAINS', 104, 3.1, 18, 2.1, fiber: 2.5, unit: 'PIECE', refQty: 1, refWeight: 40),
      f('Naan (plain/butter)', 'GRAINS', 260, 7.5, 45, 5.5, unit: 'PIECE', refQty: 1, refWeight: 90),
      f('Whole Wheat Bread', 'GRAINS', 75, 3.5, 12, 0.9, fiber: 2.0, unit: 'PIECE', refQty: 1, refWeight: 30),
      f('White Bread', 'GRAINS', 79, 2.7, 15, 1.0, fiber: 0.8, unit: 'PIECE', refQty: 1, refWeight: 30),
      f('Idli (steamed rice cake)', 'GRAINS', 58, 2, 12, 0.4, unit: 'PIECE', refQty: 1, refWeight: 40),
      f('Dosa (plain)', 'GRAINS', 168, 3.8, 29, 3.7, fiber: 1.2, unit: 'PIECE', refQty: 1, refWeight: 75),
      f('Masala Dosa', 'GRAINS', 250, 5.5, 42, 7.5, unit: 'PIECE', refQty: 1, refWeight: 130),
      f('Poha (raw/flattened rice)', 'GRAINS', 346, 6.6, 77, 1.2, fiber: 2),
      f('Poha (cooked)', 'GRAINS', 110, 2.5, 23, 0.4, fiber: 0.4),
      f('Upma (cooked semolina)', 'GRAINS', 180, 4, 30, 5, fiber: 2),
      f('Corn Flakes', 'GRAINS', 357, 8, 84, 0.4, fiber: 1.2),
      f('Muesli (dry)', 'GRAINS', 372, 9.5, 68, 6.2, fiber: 8.5),

      // ── Legumes & Pulses (Raw & Cooked) ─────────────────────────────────
      f('Yellow Lentils / Toor Dal (raw)', 'LEGUMES', 343, 22, 63, 1.5, fiber: 15),
      f('Yellow Lentils / Toor Dal (cooked)', 'LEGUMES', 116, 9, 20, 0.4, fiber: 7.9),
      f('Moong Dal (raw)', 'LEGUMES', 347, 24, 63, 1.2, fiber: 16),
      f('Moong Dal (cooked)', 'LEGUMES', 105, 7, 19, 0.4, fiber: 6),
      f('Chickpeas / Chana (raw/dry)', 'LEGUMES', 364, 19, 61, 6, fiber: 17),
      f('Chickpeas / Chana (cooked)', 'LEGUMES', 164, 8.9, 27, 2.6, fiber: 7.6),
      f('Rajma / Kidney Beans (raw/dry)', 'LEGUMES', 333, 24, 60, 0.8, fiber: 25),
      f('Rajma / Kidney Beans (cooked)', 'LEGUMES', 127, 8.7, 22.8, 0.5, fiber: 6.4),
      f('Black Beans (raw/dry)', 'LEGUMES', 341, 21.6, 62.4, 1.4, fiber: 16),
      f('Black Beans (cooked)', 'LEGUMES', 132, 8.9, 24, 0.5, fiber: 8.7),
      f('Soya Chunks (raw/dry)', 'LEGUMES', 345, 52, 33, 0.5, fiber: 13),
      f('Soya Chunks (boiled/cooked)', 'LEGUMES', 130, 18, 10, 0.5, fiber: 4.5),
      f('Soybean (raw)', 'LEGUMES', 446, 36.5, 30, 20, fiber: 9.3),
      f('Soybean (cooked)', 'LEGUMES', 173, 16.6, 9.9, 9, fiber: 6),
      f('Tofu (firm raw)', 'LEGUMES', 76, 8, 1.9, 4.8),
      f('Tofu (sauteed/pan-fried)', 'LEGUMES', 145, 12, 3, 9.5),

      // ── Dairy & Alternatives ─────────────────────────────────────────────
      f('Paneer (raw)', 'DAIRY', 265, 18, 3.5, 20),
      f('Paneer (grilled/pan-seared)', 'DAIRY', 290, 20, 3.8, 22),
      f('Low Fat Paneer', 'DAIRY', 180, 24, 4, 7),
      f('Whole Milk (3.5% fat)', 'DAIRY', 61, 3.2, 4.8, 3.3, unit: 'ML', refQty: 100, refWeight: 100),
      f('Skimmed Milk / Toned Milk', 'DAIRY', 35, 3.4, 5, 0.1, unit: 'ML', refQty: 100, refWeight: 100),
      f('Soy Milk (unsweetened)', 'DAIRY', 33, 3.3, 1.8, 1.6, unit: 'ML', refQty: 100, refWeight: 100),
      f('Almond Milk (unsweetened)', 'DAIRY', 15, 0.5, 0.3, 1.2, unit: 'ML', refQty: 100, refWeight: 100),
      f('Curd / Dahi (full fat)', 'DAIRY', 61, 3.5, 4.7, 3.3),
      f('Greek Yogurt (plain 0% fat)', 'DAIRY', 59, 10, 3.6, 0.4),
      f('Hung Curd', 'DAIRY', 115, 9.5, 5, 6.5),
      f('Cheddar Cheese', 'DAIRY', 403, 25, 1.3, 33),
      f('Mozzarella Cheese', 'DAIRY', 280, 28, 3.1, 17),
      f('Butter', 'DAIRY', 717, 0.9, 0.1, 81),
      f('Ghee (clarified butter)', 'OILS', 900, 0, 0, 99.8),
      f('Whey Protein Isolate (1 scoop)', 'SUPPLEMENTS', 110, 27, 1, 0.5, unit: 'SCOOP', refQty: 1, refWeight: 30),
      f('Whey Protein Concentrate (1 scoop)', 'SUPPLEMENTS', 125, 24, 3, 2, unit: 'SCOOP', refQty: 1, refWeight: 30),

      // ── Vegetables (Raw & Cooked) ────────────────────────────────────────
      f('Spinach (raw)', 'VEGETABLES', 23, 2.9, 3.6, 0.4, fiber: 2.2),
      f('Spinach (cooked/steamed)', 'VEGETABLES', 41, 5.3, 7, 0.5, fiber: 4.3),
      f('Broccoli (raw)', 'VEGETABLES', 34, 2.8, 6.6, 0.4, fiber: 2.6),
      f('Broccoli (cooked/steamed)', 'VEGETABLES', 35, 2.4, 7.2, 0.4, fiber: 3.3),
      f('Potato (raw)', 'VEGETABLES', 77, 2, 17, 0.1, fiber: 2.2),
      f('Potato (boiled)', 'VEGETABLES', 86, 1.9, 20, 0.1, fiber: 1.8),
      f('Potato (fried/french fries)', 'VEGETABLES', 312, 3.4, 41, 15, fiber: 3.8),
      f('Sweet Potato (raw)', 'VEGETABLES', 86, 1.6, 20, 0.1, fiber: 3),
      f('Sweet Potato (baked/boiled)', 'VEGETABLES', 90, 2, 20.7, 0.1, fiber: 3.3),
      f('Carrot (raw)', 'VEGETABLES', 41, 0.9, 10, 0.2, fiber: 2.8),
      f('Carrot (cooked)', 'VEGETABLES', 35, 0.8, 8.2, 0.2, fiber: 2.5),
      f('Tomato (raw)', 'VEGETABLES', 18, 0.9, 3.9, 0.2, fiber: 1.2),
      f('Onion (raw)', 'VEGETABLES', 40, 1.1, 9.3, 0.1, fiber: 1.7),
      f('Cauliflower (raw)', 'VEGETABLES', 25, 1.9, 5, 0.3, fiber: 2),
      f('Cauliflower (cooked)', 'VEGETABLES', 23, 1.8, 4.4, 0.5, fiber: 2.3),
      f('Green Peas (raw/fresh)', 'VEGETABLES', 81, 5.4, 14.5, 0.4, fiber: 5.1),
      f('Green Peas (boiled)', 'VEGETABLES', 84, 5.4, 15.6, 0.2, fiber: 5.5),
      f('Capsicum / Bell Pepper (raw)', 'VEGETABLES', 31, 1, 6, 0.3, fiber: 2.1),
      f('Cucumber (raw)', 'VEGETABLES', 16, 0.7, 3.6, 0.1, fiber: 0.5),
      f('Cabbage (raw)', 'VEGETABLES', 25, 1.3, 5.8, 0.1, fiber: 2.5),
      f('Mushroom (raw/button)', 'VEGETABLES', 22, 3.1, 3.3, 0.3, fiber: 1),
      f('Mushroom (sauteed)', 'VEGETABLES', 45, 3.5, 4.5, 2.2, fiber: 1.5),
      f('Eggplant / Brinjal (raw)', 'VEGETABLES', 25, 1, 5.7, 0.2, fiber: 3),
      f('Bottle Gourd / Lauki (raw)', 'VEGETABLES', 14, 0.6, 2.5, 0.1, fiber: 0.5),
      f('Bitter Gourd / Karela (raw)', 'VEGETABLES', 17, 1, 3.7, 0.2, fiber: 2.8),

      // ── Fruits ────────────────────────────────────────────────────────────
      f('Banana', 'FRUITS', 105, 1.3, 27, 0.3, fiber: 3.1, unit: 'PIECE', refQty: 1, refWeight: 120),
      f('Apple', 'FRUITS', 95, 0.5, 25, 0.3, fiber: 4.4, unit: 'PIECE', refQty: 1, refWeight: 182),
      f('Orange', 'FRUITS', 62, 1.2, 15, 0.2, fiber: 3.1, unit: 'PIECE', refQty: 1, refWeight: 130),
      f('Mango', 'FRUITS', 60, 0.8, 15, 0.4, fiber: 1.6),
      f('Papaya', 'FRUITS', 43, 0.5, 11, 0.3, fiber: 1.7),
      f('Watermelon', 'FRUITS', 30, 0.6, 7.6, 0.2, fiber: 0.4),
      f('Guava', 'FRUITS', 68, 2.6, 14, 1, fiber: 5.4, unit: 'PIECE', refQty: 1, refWeight: 100),
      f('Pomegranate', 'FRUITS', 83, 1.7, 19, 1.2, fiber: 4),
      f('Avocado', 'FRUITS', 160, 2, 8.5, 14.7, fiber: 6.7),
      f('Grapes', 'FRUITS', 69, 0.7, 18, 0.2, fiber: 0.9),
      f('Blueberries', 'FRUITS', 57, 0.7, 14.5, 0.3, fiber: 2.4),
      f('Strawberries', 'FRUITS', 32, 0.7, 7.7, 0.3, fiber: 2),
      f('Dates (dried)', 'FRUITS', 28, 0.2, 7.5, 0.0, fiber: 0.7, unit: 'PIECE', refQty: 1, refWeight: 10),

      // ── Nuts & Seeds ──────────────────────────────────────────────────────
      f('Almonds (raw)', 'NUTS', 579, 21, 22, 50, fiber: 12.5),
      f('Almonds (roasted)', 'NUTS', 598, 21, 21, 52, fiber: 11),
      f('Walnuts (raw)', 'NUTS', 654, 15, 14, 65, fiber: 6.7),
      f('Cashews (raw)', 'NUTS', 553, 18, 30, 44, fiber: 3.3),
      f('Cashews (roasted/salted)', 'NUTS', 574, 16.8, 30, 46, fiber: 3),
      f('Peanuts (raw)', 'NUTS', 567, 26, 16, 49, fiber: 8.5),
      f('Peanuts (roasted)', 'NUTS', 585, 24, 21, 50, fiber: 8),
      f('Peanut Butter (natural)', 'NUTS', 588, 25, 20, 50, fiber: 6),
      f('Pistachios (raw)', 'NUTS', 560, 20, 27, 45, fiber: 10.6),
      f('Chia Seeds', 'SEEDS', 486, 17, 42, 31, fiber: 34),
      f('Flax Seeds', 'SEEDS', 534, 18, 29, 42, fiber: 27),
      f('Pumpkin Seeds', 'SEEDS', 559, 30, 10.7, 49, fiber: 6),
      f('Sunflower Seeds', 'SEEDS', 584, 21, 20, 51, fiber: 8.6),

      // ── Oils & Fats ───────────────────────────────────────────────────────
      f('Olive Oil (extra virgin)', 'OILS', 119, 0, 0, 13.5, unit: 'TABLESPOON', refQty: 1, refWeight: 14),
      f('Coconut Oil', 'OILS', 120, 0, 0, 13.6, unit: 'TABLESPOON', refQty: 1, refWeight: 14),
      f('Mustard Oil', 'OILS', 119, 0, 0, 13.5, unit: 'TABLESPOON', refQty: 1, refWeight: 14),
      f('Sunflower Oil', 'OILS', 120, 0, 0, 13.6, unit: 'TABLESPOON', refQty: 1, refWeight: 14),

      // ── Beverages ─────────────────────────────────────────────────────────
      f('Tea (black, no sugar)', 'BEVERAGES', 1, 0.1, 0.3, 0, unit: 'ML', refQty: 240, refWeight: 240),
      f('Tea with Milk & Sugar', 'BEVERAGES', 45, 1.2, 6.5, 1.5, unit: 'ML', refQty: 150, refWeight: 150),
      f('Coffee (black, no sugar)', 'BEVERAGES', 2, 0.3, 0, 0, unit: 'ML', refQty: 240, refWeight: 240),
      f('Coffee with Milk & Sugar', 'BEVERAGES', 55, 1.5, 8, 1.8, unit: 'ML', refQty: 150, refWeight: 150),
      f('Orange Juice (100% pure)', 'BEVERAGES', 45, 0.7, 10.4, 0.2, unit: 'ML'),
      f('Coconut Water (fresh)', 'BEVERAGES', 19, 0.7, 3.7, 0.2, unit: 'ML'),
      f('Protein Shake (whey in water)', 'BEVERAGES', 120, 24, 3, 2, unit: 'ML', refQty: 300, refWeight: 300),

      // ── Snacks & Prepared Meals ───────────────────────────────────────────
      f('Dark Chocolate (70%+ cocoa)', 'SNACKS', 598, 7.8, 46, 43, fiber: 10.9),
      f('Popcorn (air-popped)', 'SNACKS', 375, 11, 74, 4.3, fiber: 14.5),
      f('Samosa (potato filling)', 'SNACKS', 308, 6, 35, 16, unit: 'PIECE', refQty: 1, refWeight: 70),
      f('Chicken Biryani', 'MEAT', 180, 11, 20, 6.5, refQty: 100, refWeight: 100),
      f('Veg Biryani / Pulao', 'GRAINS', 145, 3.2, 24, 4, refQty: 100, refWeight: 100),
      f('Khichdi (dal & rice)', 'GRAINS', 115, 3.8, 19, 2.5, refQty: 100, refWeight: 100),
      f('Aloo Paratha', 'GRAINS', 260, 5.5, 38, 10, unit: 'PIECE', refQty: 1, refWeight: 100),

      // ── South Indian Biryanis & Restaurant Meals ──────────────────────────
      f('Hyderabadi Chicken Dum Biryani (restaurant)', 'MEAT', 195, 12.0, 22.0, 7.2, fiber: 1.2, refQty: 100, refWeight: 100),
      f('Hyderabadi Mutton Dum Biryani (restaurant)', 'MEAT', 225, 13.5, 21.0, 9.8, fiber: 1.0, refQty: 100, refWeight: 100),
      f('Bangalore Donne Chicken Biryani', 'MEAT', 175, 11.5, 21.0, 5.8, fiber: 1.5, refQty: 100, refWeight: 100),
      f('Ambur Chicken Biryani (Seeraga Samba)', 'MEAT', 185, 11.0, 23.0, 6.2, fiber: 1.1, refQty: 100, refWeight: 100),
      f('Thalassery / Malabar Chicken Biryani', 'MEAT', 190, 10.8, 22.5, 6.8, fiber: 1.3, refQty: 100, refWeight: 100),
      f('Chettinad Chicken Biryani', 'MEAT', 192, 12.0, 21.0, 7.0, fiber: 1.4, refQty: 100, refWeight: 100),
      f('Chicken 65 Biryani', 'MEAT', 215, 14.0, 22.0, 8.5, fiber: 1.2, refQty: 100, refWeight: 100),
      f('Egg Biryani (restaurant style)', 'EGGS', 160, 7.5, 22.0, 5.0, fiber: 1.0, refQty: 100, refWeight: 100),
      f('Paneer Dum Biryani', 'DAIRY', 175, 7.0, 23.0, 6.5, fiber: 1.5, refQty: 100, refWeight: 100),
      f('Veg Dum Biryani', 'VEGETABLES', 145, 3.8, 24.0, 4.2, fiber: 2.0, refQty: 100, refWeight: 100),

      // ── Naans & Flatbreads (Restaurant style) ─────────────────────────────
      f('Butter Naan', 'GRAINS', 290, 8.0, 46.0, 8.5, fiber: 2.0, unit: 'PIECE', refQty: 1, refWeight: 90),
      f('Garlic Butter Naan', 'GRAINS', 310, 8.2, 47.0, 10.0, fiber: 2.1, unit: 'PIECE', refQty: 1, refWeight: 95),
      f('Plain Naan', 'GRAINS', 240, 7.5, 45.0, 3.5, fiber: 2.0, unit: 'PIECE', refQty: 1, refWeight: 85),
      f('Cheese Garlic Naan', 'GRAINS', 360, 11.0, 46.0, 14.0, fiber: 2.0, unit: 'PIECE', refQty: 1, refWeight: 100),
      f('Paneer Kulcha / Stuffed Kulcha', 'GRAINS', 330, 10.0, 48.0, 11.0, fiber: 2.5, unit: 'PIECE', refQty: 1, refWeight: 110),
      f('Tandoori Roti (Plain)', 'GRAINS', 130, 4.2, 26.0, 0.8, fiber: 2.5, unit: 'PIECE', refQty: 1, refWeight: 50),
      f('Butter Tandoori Roti', 'GRAINS', 165, 4.2, 26.0, 4.8, fiber: 2.5, unit: 'PIECE', refQty: 1, refWeight: 55),
      f('Kerala Parotta / Malabar Parotta', 'GRAINS', 290, 5.5, 40.0, 12.0, fiber: 1.5, unit: 'PIECE', refQty: 1, refWeight: 80),
      f('Rumali Roti', 'GRAINS', 175, 4.8, 34.0, 2.2, fiber: 1.8, unit: 'PIECE', refQty: 1, refWeight: 60),

      // ── Chicken Gravies & Curries (Restaurant style) ──────────────────────
      f('Butter Chicken / Murgh Makhani', 'MEAT', 210, 14.0, 6.5, 14.5, refQty: 100, refWeight: 100),
      f('Chicken Tikka Masala', 'MEAT', 195, 15.0, 7.0, 12.0, refQty: 100, refWeight: 100),
      f('Andhra Spicy Chicken Curry / Kodi Kura', 'MEAT', 175, 16.0, 4.0, 10.5, refQty: 100, refWeight: 100),
      f('Chettinad Chicken Curry', 'MEAT', 185, 15.5, 4.5, 11.5, refQty: 100, refWeight: 100),
      f('Kadai Chicken / Kadhai Chicken', 'MEAT', 180, 16.0, 5.0, 11.0, refQty: 100, refWeight: 100),
      f('Chicken Korma / Shahi Chicken Korma', 'MEAT', 220, 13.5, 8.0, 15.5, refQty: 100, refWeight: 100),
      f('Telangana / Rayalaseema Spicy Chicken', 'MEAT', 190, 16.5, 4.0, 12.0, refQty: 100, refWeight: 100),
      f('Chicken Sukka / Kori Sukka', 'MEAT', 225, 18.0, 5.0, 14.5, refQty: 100, refWeight: 100),
      f('South Indian Pepper Chicken Gravy', 'MEAT', 170, 16.0, 4.0, 9.8, refQty: 100, refWeight: 100),
      // ── Famous Hyderabadi Biryanis (Restaurant Specialty) ─────────────────
      f('Hyderabadi Mughlai Chicken Biryani', 'MEAT', 215, 13.0, 22.5, 9.0, fiber: 1.2, refQty: 100, refWeight: 100),
      f('Hyderabadi Prawn Biryani / Prawns Dum Biryani', 'SEAFOOD', 170, 14.5, 21.0, 4.5, fiber: 1.0, refQty: 100, refWeight: 100),
      f('Hyderabadi Special Mutton Biryani (Double Gosht)', 'MEAT', 240, 15.0, 20.0, 11.5, fiber: 0.9, refQty: 100, refWeight: 100),
      f('Hyderabadi Zafrani Chicken Biryani', 'MEAT', 200, 12.5, 22.0, 7.5, fiber: 1.1, refQty: 100, refWeight: 100),
      f('Hyderabadi Fish Biryani (Apollo Fish Style)', 'SEAFOOD', 185, 13.5, 20.5, 6.2, fiber: 1.0, refQty: 100, refWeight: 100),
      f('Hyderabadi Keema Biryani (Mince Mutton)', 'MEAT', 220, 14.0, 21.5, 9.2, fiber: 1.0, refQty: 100, refWeight: 100),
      f('Hyderabadi Ulavacharu Chicken Biryani', 'MEAT', 205, 13.2, 23.0, 7.8, fiber: 2.1, refQty: 100, refWeight: 100),
      f('Hyderabadi Avakaya Chicken Biryani', 'MEAT', 198, 12.0, 22.0, 7.5, fiber: 1.3, refQty: 100, refWeight: 100),

      // ── Famous Hyderabadi Starters (Restaurant Specialty) ─────────────────
      f('Hyderabadi Chicken Majestic Starter', 'MEAT', 220, 21.0, 6.5, 12.0, fiber: 0.8, refQty: 100, refWeight: 100),
      f('Hyderabadi Chicken 65 Starter (Fried Dry)', 'MEAT', 235, 22.0, 5.0, 14.0, fiber: 0.5, refQty: 100, refWeight: 100),
      f('Hyderabadi Apollo Fish Fry Starter', 'SEAFOOD', 210, 19.5, 4.5, 12.5, fiber: 0.5, refQty: 100, refWeight: 100),
      f('Hyderabadi Chicken 555 Starter', 'MEAT', 230, 21.5, 5.5, 13.5, fiber: 0.6, refQty: 100, refWeight: 100),
      f('Hyderabadi Loose Prawns Starter (Crispy Garlic)', 'SEAFOOD', 245, 18.0, 12.0, 14.0, fiber: 0.5, refQty: 100, refWeight: 100),
      f('Hyderabadi Pepper Chicken Dry Starter', 'MEAT', 195, 23.0, 3.5, 9.5, fiber: 0.8, refQty: 100, refWeight: 100),
      f('Hyderabadi Tangdi Kabab (2 pcs drumsticks)', 'MEAT', 260, 26.0, 3.0, 15.0, unit: 'PIECE', refQty: 2, refWeight: 150),
      f('Hyderabadi Chicken Reshmi / Malai Kabab', 'MEAT', 240, 23.0, 4.0, 14.5, refQty: 100, refWeight: 100),
      f('Hyderabadi Mutton Boti Kabab Starter', 'MEAT', 255, 24.0, 2.5, 16.0, refQty: 100, refWeight: 100),
      f('Hyderabadi Paneer 65 Starter', 'DAIRY', 260, 14.0, 11.0, 18.0, fiber: 1.2, refQty: 100, refWeight: 100),
      f('Hyderabadi Crispy Corn Fry Starter', 'VEGETABLES', 210, 4.5, 28.0, 9.5, fiber: 3.2, refQty: 100, refWeight: 100),
      f('Hyderabadi Veg Manchurian Dry Starter', 'VEGETABLES', 185, 3.8, 22.0, 9.0, fiber: 2.5, refQty: 100, refWeight: 100),
    ];
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
    } on ApiException catch (_) {
      // Fall back to local search
      final allFoods = _builtInFoods();
      final lower = trimmed.toLowerCase();
      foods = allFoods.where((f) => f.name.toLowerCase().contains(lower)).toList();
    } catch (_) {
      // Fall back to local search
      final allFoods = _builtInFoods();
      final lower = trimmed.toLowerCase();
      foods = allFoods.where((f) => f.name.toLowerCase().contains(lower)).toList();
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
      final localId = -(DateTime.now().millisecondsSinceEpoch % 1000000);
      final newFood = FoodResponse(
        id: localId,
        uuid: 'local-$localId',
        name: request.name,
        category: request.category,
        servingUnit: request.servingUnit,
        referenceQuantity: request.referenceQuantity,
        referenceWeight: request.referenceWeight,
        calories: request.calories,
        protein: request.protein,
        carbs: request.carbs,
        fat: request.fat,
        fiber: request.fiber ?? 0,
        system: false,
        barcode: request.barcode ?? '',
        brand: request.brand ?? '',
      );

      foods = [newFood, ...foods];
      notifyListeners();

      _service.createFood(request).catchError((_) => newFood);
      return newFood;
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
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateFood(int id, UpdateFoodRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      foods = foods.map((food) {
        if (food.id == id) {
          return FoodResponse(
            id: food.id,
            uuid: food.uuid,
            name: request.name,
            category: request.category,
            servingUnit: request.servingUnit,
            referenceQuantity: request.referenceQuantity,
            referenceWeight: request.referenceWeight,
            calories: request.calories,
            protein: request.protein,
            carbs: request.carbs,
            fat: request.fat,
            fiber: request.fiber ?? food.fiber,
            system: food.system,
            barcode: request.barcode ?? food.barcode,
            brand: request.brand ?? food.brand,
          );
        }
        return food;
      }).toList();
      notifyListeners();

      _service.updateFood(id, request).catchError((_) => foods.first);
      return true;
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
    foods = foods.where((food) => food.id != id).toList();
    notifyListeners();
    _service.deleteFood(id).catchError((_) {});
    return true;
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
      // 1. Check local foods list first (built-in or custom foods with matching barcode)
      for (final f in foods) {
        if (f.barcode.isNotEmpty && f.barcode == barcode) {
          final localScanned = ScannedFood(
            foodId: f.id,
            local: true,
            barcode: f.barcode,
            name: f.name,
            brand: f.brand ?? '',
            imageUrl: f.imageUrl ?? '',
            source: 'LOCAL',
            calories: f.calories,
            protein: f.protein,
            carbs: f.carbs,
            fat: f.fat,
            fiber: f.fiber,
            servingUnit: f.servingUnit,
            referenceQuantity: f.referenceQuantity,
            referenceWeight: f.referenceWeight,
          );
          scannedFood = localScanned;
          return localScanned;
        }
      }

      // 2. Try fetching from free public OpenFoodFacts API directly
      try {
        final dio = Dio();
        final response = await dio.get<Map<String, dynamic>>(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
          options: Options(
            responseType: ResponseType.json,
            sendTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );

        if (response.statusCode == 200 && response.data != null && response.data!['status'] == 1) {
          final product = response.data!['product'] as Map<String, dynamic>?;
          if (product != null) {
            final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
            final name = product['product_name']?.toString() ?? product['product_name_en']?.toString() ?? 'Scanned Product';
            final brand = product['brands']?.toString() ?? '';
            final img = product['image_url']?.toString() ?? '';

            double parseNutriment(String key1, String key2) {
              final val = nutriments[key1] ?? nutriments[key2] ?? 0;
              if (val is num) return val.toDouble();
              return double.tryParse(val.toString()) ?? 0;
            }

            final cal = parseNutriment('energy-kcal_100g', 'energy-kcal');
            final protein = parseNutriment('proteins_100g', 'proteins');
            final carbs = parseNutriment('carbohydrates_100g', 'carbohydrates');
            final fat = parseNutriment('fat_100g', 'fat');
            final fiber = parseNutriment('fiber_100g', 'fiber');

            final offScanned = ScannedFood(
              local: false,
              barcode: barcode,
              name: name,
              brand: brand,
              imageUrl: img,
              source: 'OPEN_FOOD_FACTS',
              calories: cal,
              protein: protein,
              carbs: carbs,
              fat: fat,
              fiber: fiber,
              servingUnit: ServingUnit.gram,
              referenceQuantity: 100,
              referenceWeight: 100,
            );
            scannedFood = offScanned;
            return offScanned;
          }
        }
      } catch (_) {
        // OpenFoodFacts offline / network error — fallback below
      }

      // 3. Fallback: Return a draft ScannedFood with pre-filled barcode so user can enter custom food info
      final fallbackScanned = ScannedFood(
        local: false,
        barcode: barcode,
        name: 'Scanned Item ($barcode)',
        brand: 'Custom',
        imageUrl: '',
        source: 'MANUAL',
        calories: 100,
        protein: 5,
        carbs: 15,
        fat: 2,
        fiber: 0,
        servingUnit: ServingUnit.gram,
        referenceQuantity: 100,
        referenceWeight: 100,
      );
      scannedFood = fallbackScanned;
      return fallbackScanned;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLookingUpBarcode = false;
      notifyListeners();
    }
  }

  Future<FoodResponse?> saveScannedFood(ScannedFood scannedFood) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final localId = -(DateTime.now().millisecondsSinceEpoch % 1000000);
      final newFood = FoodResponse(
        id: localId,
        uuid: 'local-$localId',
        name: scannedFood.name,
        category: FoodCategory.other,
        servingUnit: scannedFood.servingUnit ?? ServingUnit.gram,
        referenceQuantity: scannedFood.referenceQuantity ?? 100,
        referenceWeight: scannedFood.referenceWeight ?? 100,
        calories: scannedFood.calories,
        protein: scannedFood.protein,
        carbs: scannedFood.carbs,
        fat: scannedFood.fat,
        fiber: scannedFood.fiber,
        system: false,
        barcode: scannedFood.barcode,
        brand: scannedFood.brand,
        imageUrl: scannedFood.imageUrl,
        source: scannedFood.source,
      );

      foods = [newFood, ...foods];
      notifyListeners();

      _service.createFoodFromScannedFood(scannedFood).catchError((_) => newFood);
      return newFood;
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
      final existing = findFoodById(scannedFood.foodId!);
      if (existing != null) return existing;
    }
    return saveScannedFood(scannedFood);
  }
}
