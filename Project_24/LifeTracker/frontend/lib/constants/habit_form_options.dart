import 'package:flutter/material.dart';

import '../utils/color_utils.dart';
import '../utils/habit_ui_utils.dart';

class HabitFormOptions {
  static const iconNames = [
    'fitness',
    'book',
    'water',
    'sleep',
    'meditation',
    'run',
    'food',
    'music',
  ];

  static const colorHexValues = [
    '#2563EB',
    '#7C3AED',
    '#DB2777',
    '#EA580C',
    '#16A34A',
    '#0891B2',
    '#CA8A04',
    '#64748B',
  ];

  static IconData iconData(String name) => HabitUiUtils.iconFromName(name);

  static Color parseColor(String hex) => ColorUtils.parseHex(hex);
}
