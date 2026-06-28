import 'package:flutter/material.dart';

import 'color_utils.dart';

class LearningUiUtils {
  static IconData iconFromName(String? iconName) {
    return switch (iconName) {
      'book' => Icons.menu_book_outlined,
      'code' => Icons.code_outlined,
      'video' => Icons.play_circle_outlined,
      'course' => Icons.school_outlined,
      'article' => Icons.article_outlined,
      'podcast' => Icons.podcasts_outlined,
      'language' => Icons.translate_outlined,
      'science' => Icons.science_outlined,
      _ => Icons.auto_stories_outlined,
    };
  }

  static Color colorFromHex(String? hex, ColorScheme scheme) {
    return ColorUtils.fromHex(hex, scheme, fallback: scheme.tertiary);
  }

  static Color priorityColor(LearningPriorityLabel priority, ColorScheme scheme) {
    return switch (priority) {
      LearningPriorityLabel.low => scheme.secondaryContainer,
      LearningPriorityLabel.medium => scheme.primaryContainer,
      LearningPriorityLabel.high => scheme.errorContainer,
    };
  }
}

enum LearningPriorityLabel { low, medium, high }
