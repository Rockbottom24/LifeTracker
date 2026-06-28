import 'package:flutter/material.dart';

import '../services/notification_service.dart';

enum ReminderEntityType { habit, learning }

class ReminderNotificationHelper {
  const ReminderNotificationHelper._();

  static Future<void> scheduleIfEnabled({
    required ReminderEntityType entityType,
    required int entityId,
    required String title,
    required int hour,
    required int minute,
    required bool notificationsEnabled,
  }) async {
    await cancel(entityType: entityType, entityId: entityId);

    if (!notificationsEnabled) return;

    final service = NotificationService();
    switch (entityType) {
      case ReminderEntityType.habit:
        throw UnsupportedError(
          'Use HabitNotificationHelper.scheduleIfEnabled for habit reminders.',
        );
      case ReminderEntityType.learning:
        await service.scheduleLearningReminder(
          sessionId: entityId,
          title: title,
          hour: hour,
          minute: minute,
        );
    }
  }

  static Future<void> cancel({
    required ReminderEntityType entityType,
    required int entityId,
  }) async {
    final service = NotificationService();
    switch (entityType) {
      case ReminderEntityType.habit:
        await service.cancelHabitReminder(entityId);
      case ReminderEntityType.learning:
        await service.cancelLearningReminder(entityId);
    }
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
