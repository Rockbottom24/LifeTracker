import 'package:flutter/foundation.dart';

import '../models/habit_frequency.dart';
import '../models/habit_response.dart';
import '../models/learning_session_response.dart';
import '../services/notification_service.dart';
import 'habit_notification_helper.dart';
import 'learning_notification_helper.dart';

/// Rebuilds local notification schedules for the authenticated user only.
class UserReminderScheduler {
  const UserReminderScheduler._();

  static Future<void> rescheduleForUser({
    required int userId,
    required List<HabitResponse> habits,
    required List<LearningSessionResponse> sessions,
  }) async {
    if (kIsWeb) return;
    final service = NotificationService();
    await service.initialize();

    // Clear any previous device schedules, then schedule only this user's reminders.
    await service.cancelAllNotifications();

    for (final habit in habits) {
      if (!habit.notificationsEnabled || habit.reminderTime == null || !habit.isActive) {
        continue;
      }
      await HabitNotificationHelper.scheduleIfEnabled(
        userId: userId,
        habitId: habit.id,
        name: habit.name,
        description: habit.description,
        hour: habit.reminderTime!.hour,
        minute: habit.reminderTime!.minute,
        notificationsEnabled: true,
        frequency: HabitFrequency.fromApiValue(habit.frequency),
        anchorDate: habit.startDate,
      );
    }

    for (final session in sessions) {
      if (!session.notificationsEnabled || session.reminderTime == null) {
        continue;
      }
      await LearningNotificationHelper.scheduleIfEnabled(
        userId: userId,
        sessionId: session.id,
        title: session.title,
        hour: session.reminderTime!.hour,
        minute: session.reminderTime!.minute,
        notificationsEnabled: true,
      );
    }
  }
}
