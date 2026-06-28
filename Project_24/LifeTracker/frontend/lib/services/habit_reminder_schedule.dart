import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/habit_frequency.dart';

/// Computes the first fire time and repeat rule for habit reminder notifications.
class HabitReminderSchedule {
  const HabitReminderSchedule._();

  static const habitNotificationTitle = '⏰ Habit Reminder';

  static String notificationBody({
    required String name,
    String? description,
  }) {
    final trimmedDescription = description?.trim();
    if (trimmedDescription == null || trimmedDescription.isEmpty) {
      return name;
    }
    return '$name\n$trimmedDescription';
  }

  static DateTimeComponents? repeatComponents(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return DateTimeComponents.time;
      case HabitFrequency.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case HabitFrequency.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
    }
  }

  static tz.TZDateTime firstFireTime({
    required HabitFrequency frequency,
    required int hour,
    required int minute,
    DateTime? anchorDate,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    switch (frequency) {
      case HabitFrequency.daily:
        return _nextDaily(now, hour, minute);
      case HabitFrequency.weekly:
        final weekday = anchorDate?.weekday ?? now.weekday;
        return _nextWeekly(now, weekday, hour, minute);
      case HabitFrequency.monthly:
        final dayOfMonth = anchorDate?.day ?? now.day;
        return _nextMonthly(now, dayOfMonth, hour, minute);
    }
  }

  static tz.TZDateTime _nextDaily(tz.TZDateTime now, int hour, int minute) {
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static tz.TZDateTime _nextWeekly(tz.TZDateTime now, int weekday, int hour, int minute) {
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  static tz.TZDateTime _nextMonthly(tz.TZDateTime now, int dayOfMonth, int hour, int minute) {
    final clampedDay = _clampDayOfMonth(now.year, now.month, dayOfMonth);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, clampedDay, hour, minute);
    if (scheduled.isBefore(now)) {
      var month = now.month + 1;
      var year = now.year;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      final nextDay = _clampDayOfMonth(year, month, dayOfMonth);
      scheduled = tz.TZDateTime(tz.local, year, month, nextDay, hour, minute);
    }
    return scheduled;
  }

  static int _clampDayOfMonth(int year, int month, int dayOfMonth) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return dayOfMonth.clamp(1, lastDay);
  }
}
