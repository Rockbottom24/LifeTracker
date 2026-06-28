import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetracker/models/habit_frequency.dart';
import 'package:lifetracker/services/habit_reminder_schedule.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  });

  test('notification body includes description on second line', () {
    expect(
      HabitReminderSchedule.notificationBody(
        name: 'Read Book',
        description: 'Read 20 pages today.',
      ),
      'Read Book\nRead 20 pages today.',
    );
  });

  test('notification body omits empty description', () {
    expect(
      HabitReminderSchedule.notificationBody(name: 'Drink Water', description: '  '),
      'Drink Water',
    );
  });

  test('daily repeat uses time component', () {
    expect(
      HabitReminderSchedule.repeatComponents(HabitFrequency.daily),
      DateTimeComponents.time,
    );
  });

  test('weekly repeat uses dayOfWeekAndTime component', () {
    expect(
      HabitReminderSchedule.repeatComponents(HabitFrequency.weekly),
      DateTimeComponents.dayOfWeekAndTime,
    );
  });
}
