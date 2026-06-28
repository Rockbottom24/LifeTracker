import 'package:flutter_test/flutter_test.dart';
import 'package:lifetracker/models/habit_response.dart';

void main() {
  test('HabitResponse round-trips through json', () {
    final habit = HabitResponse(
      id: 1,
      uuid: 'abc',
      name: 'Drink Water',
      description: 'Stay hydrated',
      frequency: 'DAILY',
      startDate: DateTime(2026, 6, 27),
      reminderTime: DateTime(1970, 1, 1, 8, 30),
      notificationsEnabled: true,
      iconName: 'water_drop',
      colorHex: '#2196F3',
      habitCategoryId: 2,
    );

    final restored = HabitResponse.fromJson(habit.toJson());

    expect(restored.id, habit.id);
    expect(restored.name, habit.name);
    expect(restored.description, habit.description);
    expect(restored.notificationsEnabled, true);
    expect(restored.reminderTime?.hour, 8);
    expect(restored.reminderTime?.minute, 30);
  });
}
