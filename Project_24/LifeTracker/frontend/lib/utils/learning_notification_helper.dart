import '../utils/reminder_notification_helper.dart';

class LearningNotificationHelper {
  const LearningNotificationHelper._();

  static Future<void> scheduleIfEnabled({
    required int sessionId,
    required String title,
    required int hour,
    required int minute,
    required bool notificationsEnabled,
  }) {
    return ReminderNotificationHelper.scheduleIfEnabled(
      entityType: ReminderEntityType.learning,
      entityId: sessionId,
      title: title,
      hour: hour,
      minute: minute,
      notificationsEnabled: notificationsEnabled,
    );
  }

  static Future<void> cancelForSession(int sessionId) {
    return ReminderNotificationHelper.cancel(
      entityType: ReminderEntityType.learning,
      entityId: sessionId,
    );
  }
}
