import 'package:flutter/material.dart';

import '../models/habit_frequency.dart';
import '../services/notification_service.dart';

class HabitNotificationHelper {
  const HabitNotificationHelper._();

  static Future<void> scheduleIfEnabled({
    required int habitId,
    required String name,
    String? description,
    required int hour,
    required int minute,
    required bool notificationsEnabled,
    required HabitFrequency frequency,
    DateTime? anchorDate,
  }) async {
    await cancelForHabit(habitId);

    if (!notificationsEnabled) return;

    await NotificationService().scheduleHabitReminder(
      habitId: habitId,
      name: name,
      description: description,
      hour: hour,
      minute: minute,
      frequency: frequency,
      anchorDate: anchorDate,
    );
  }

  static Future<void> cancelForHabit(int habitId) {
    return NotificationService().cancelHabitReminder(habitId);
  }

  static bool reminderChanged({
    required TimeOfDay previous,
    required TimeOfDay current,
    required bool previousNotificationsEnabled,
    required bool currentNotificationsEnabled,
  }) {
    return previous.hour != current.hour ||
        previous.minute != current.minute ||
        previousNotificationsEnabled != currentNotificationsEnabled;
  }
}
