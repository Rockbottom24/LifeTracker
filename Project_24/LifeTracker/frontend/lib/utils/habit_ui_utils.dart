import 'package:flutter/material.dart';

import 'color_utils.dart';

class HabitUiUtils {
  static IconData iconFromName(String? iconName) {
    return switch (iconName) {
      'fitness' => Icons.fitness_center_outlined,
      'book' => Icons.menu_book_outlined,
      'water' => Icons.water_drop_outlined,
      'sleep' => Icons.bedtime_outlined,
      'meditation' => Icons.self_improvement_outlined,
      'run' => Icons.directions_run_outlined,
      'food' => Icons.restaurant_outlined,
      'music' => Icons.music_note_outlined,
      _ => Icons.check_circle_outline,
    };
  }

  static Color colorFromHex(String? hex, ColorScheme scheme) {
    return ColorUtils.fromHex(hex, scheme, fallback: scheme.primary);
  }
}
