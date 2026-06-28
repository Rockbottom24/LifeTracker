import 'package:flutter/material.dart';

import '../models/meal_type.dart';

class MealUiUtils {
  const MealUiUtils._();

  static IconData iconForType(MealType type) {
    return switch (type) {
      MealType.breakfast => Icons.free_breakfast_rounded,
      MealType.lunch => Icons.lunch_dining_rounded,
      MealType.snack => Icons.cookie_rounded,
      MealType.dinner => Icons.dinner_dining_rounded,
    };
  }

  static Color colorForType(MealType type, ColorScheme scheme) {
    return switch (type) {
      MealType.breakfast => scheme.tertiary,
      MealType.lunch => scheme.primary,
      MealType.snack => scheme.secondary,
      MealType.dinner => scheme.primaryContainer,
    };
  }

  static String formatMacro(double value, {int decimals = 1}) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(decimals);
  }

  static String formatQuantity(double quantity, String unitLabel) {
    final value = formatMacro(quantity);
    return '$value $unitLabel';
  }

  static String formatServing(double quantity, String unitLabel) {
    return formatQuantity(quantity, unitLabel);
  }
}
