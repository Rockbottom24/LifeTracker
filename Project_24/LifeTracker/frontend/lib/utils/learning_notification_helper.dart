import '../utils/reminder_notification_helper.dart';

class LearningNotificationHelper {
  const LearningNotificationHelper._();

  static Future<void> scheduleIfEnabled({
    required int userId,
    required int sessionId,
    required String title,
    required int hour,
    required int minute,
    required bool notificationsEnabled,
  }) {
    return ReminderNotificationHelper.scheduleIfEnabled(
      userId: userId,
      entityType: ReminderEntityType.learning,
      entityId: sessionId,
      title: title,
      hour: hour,
      minute: minute,
      notificationsEnabled: notificationsEnabled,
    );
  }

  static Future<void> cancelForSession({required int userId, required int sessionId}) {
    return ReminderNotificationHelper.cancel(
      userId: userId,
      entityType: ReminderEntityType.learning,
      entityId: sessionId,
    );
  }
}
