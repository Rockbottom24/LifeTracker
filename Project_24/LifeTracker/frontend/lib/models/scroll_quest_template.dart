import 'package:flutter/material.dart';

import 'habit_frequency.dart';

class ScrollQuestTemplate {
  const ScrollQuestTemplate({
    required this.id,
    required this.title,
    required this.authorOrCategory,
    required this.description,
    required this.timeframeLabel,
    required this.xpReward,
    required this.categoryCode,
    required this.frequency,
    required this.icon,
    required this.badgeColor,
  });

  final String id;
  final String title;
  final String authorOrCategory;
  final String description;
  final String timeframeLabel; // e.g. "Daily • 20 mins", "Weekly Trial"
  final int xpReward;
  final String categoryCode;
  final HabitFrequency frequency;
  final IconData icon;
  final Color badgeColor;
}
