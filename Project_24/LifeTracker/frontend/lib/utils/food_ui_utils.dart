import 'package:flutter/material.dart';

import '../models/food_category.dart';

class FoodUiUtils {
  const FoodUiUtils._();

  static String formatMacro(double value, String unit) {
    if (value == value.roundToDouble()) {
      return '${value.round()} $unit';
    }
    return '${value.toStringAsFixed(1)} $unit';
  }

  static IconData iconForCategory(FoodCategory category) => switch (category) {
        FoodCategory.grains => Icons.grain_rounded,
        FoodCategory.vegetables => Icons.grass_rounded,
        FoodCategory.fruits => Icons.apple_rounded,
        FoodCategory.meat => Icons.set_meal_rounded,
        FoodCategory.seafood => Icons.set_meal_outlined,
        FoodCategory.eggs => Icons.egg_alt_outlined,
        FoodCategory.dairy => Icons.icecream_outlined,
        FoodCategory.legumes => Icons.spa_outlined,
        FoodCategory.nuts => Icons.circle_outlined,
        FoodCategory.seeds => Icons.grain_outlined,
        FoodCategory.oils => Icons.opacity_outlined,
        FoodCategory.beverages => Icons.local_cafe_outlined,
        FoodCategory.supplements => Icons.medication_outlined,
        FoodCategory.snacks => Icons.cookie_outlined,
        FoodCategory.other => Icons.restaurant_outlined,
      };

  static Color colorForCategory(FoodCategory category, ColorScheme scheme) => switch (category) {
        FoodCategory.grains => const Color(0xFFD97706),
        FoodCategory.vegetables => const Color(0xFF16A34A),
        FoodCategory.fruits => const Color(0xFFEA580C),
        FoodCategory.meat => const Color(0xFFB91C1C),
        FoodCategory.seafood => const Color(0xFF0284C7),
        FoodCategory.eggs => const Color(0xFFF59E0B),
        FoodCategory.dairy => const Color(0xFF6366F1),
        FoodCategory.legumes => const Color(0xFF059669),
        FoodCategory.nuts => const Color(0xFF92400E),
        FoodCategory.seeds => const Color(0xFF65A30D),
        FoodCategory.oils => const Color(0xFFCA8A04),
        FoodCategory.beverages => const Color(0xFF0891B2),
        FoodCategory.supplements => const Color(0xFF7C3AED),
        FoodCategory.snacks => const Color(0xFFDB2777),
        FoodCategory.other => scheme.primary,
      };

  static String formatServing(double quantity, String unitLabel) {
    if (quantity == quantity.roundToDouble()) {
      return '${quantity.round()} $unitLabel';
    }
    return '${quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')} $unitLabel';
  }
}
