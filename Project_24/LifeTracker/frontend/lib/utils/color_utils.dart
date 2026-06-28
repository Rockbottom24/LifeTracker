import 'package:flutter/material.dart';

class ColorUtils {
  const ColorUtils._();

  static Color parseHex(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) {
      value = 'FF$value';
    }
    return Color(int.parse(value, radix: 16));
  }

  static Color fromHex(String? hex, ColorScheme scheme, {Color? fallback}) {
    if (hex == null || hex.isEmpty) {
      return fallback ?? scheme.primary;
    }

    var value = hex.replaceAll('#', '');
    if (value.length == 6) {
      value = 'FF$value';
    }

    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) {
      return fallback ?? scheme.primary;
    }

    return Color(parsed);
  }
}
