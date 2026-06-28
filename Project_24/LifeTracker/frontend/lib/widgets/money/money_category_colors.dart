import 'package:flutter/material.dart';

class MoneyCategoryColors {
  const MoneyCategoryColors._();

  static Color forCategory(String category, ColorScheme scheme) {
    return switch (category) {
      'Food' => const Color(0xFFFF7043),
      'Fitness' => const Color(0xFF26A69A),
      'Entertainment' => const Color(0xFFAB47BC),
      'Shopping' => const Color(0xFF5C6BC0),
      'Medical' => const Color(0xFFEF5350),
      'Travel' => const Color(0xFF29B6F6),
      'Parents' => const Color(0xFF8D6E63),
      'Groceries' => const Color(0xFF66BB6A),
      _ => scheme.outline,
    };
  }
}
