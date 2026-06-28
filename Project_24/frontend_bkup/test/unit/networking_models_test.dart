import 'package:flutter_test/flutter_test.dart';
import 'package:lifetracker/models/dashboard_response.dart';
import 'package:lifetracker/models/habit_log_response.dart';
import 'package:lifetracker/models/habit_response.dart';

void main() {
  group('networking models', () {
    test('parses dashboard response payload', () {
      final payload = {
        'currentDate': '2026-06-27',
        'greeting': 'Good morning',
        'userName': 'Ava',
        'summary': {
          'totalHabits': 3,
          'completedHabits': 2,
          'pendingHabits': 1,
          'completionPercentage': 66.7,
          'currentStreak': 4,
          'longestStreak': 7,
        },
        'todayHabits': [
          {
            'habitId': 1,
            'habitName': 'Read 20 minutes',
            'icon': 'book',
            'color': '#4CAF50',
            'completed': true,
            'targetValue': 20,
            'currentValue': 20,
          }
        ],
      };

      final result = DashboardResponse.fromJson(payload);

      expect(result.greeting, 'Good morning');
      expect(result.summary?.completedHabits, 2);
      expect(result.todayHabits, isNotEmpty);
      expect(result.todayHabits?.first.completed, isTrue);
    });

    test('parses habit response payload', () {
      final payload = {
        'id': 10,
        'uuid': '123e4567-e89b-12d3-a456-426614174000',
        'userId': 1,
        'habitCategoryId': 2,
        'name': 'Meditate',
        'description': 'Daily calm',
        'startDate': '2026-06-01',
        'endDate': '2026-12-31',
        'displayOrder': 1,
        'isActive': true,
        'createdAt': '2026-06-01T08:30:00',
        'updatedAt': '2026-06-27T09:00:00',
      };

      final result = HabitResponse.fromJson(payload);

      expect(result.name, 'Meditate');
      expect(result.isActive, isTrue);
      expect(result.createdAt, isNotNull);
    });

    test('parses habit log response payload', () {
      final payload = {
        'habitId': 10,
        'habitUuid': '123e4567-e89b-12d3-a456-426614174000',
        'habitName': 'Meditate',
        'habitCategoryId': 2,
        'displayOrder': 1,
        'habitActive': true,
        'habitLogId': 99,
        'habitLogUuid': '123e4567-e89b-12d3-a456-426614174001',
        'logDate': '2026-06-27',
        'loggedAt': '2026-06-27T07:45:00',
        'completionStatus': 'completed',
        'completed': true,
        'value': 1,
        'notes': 'Done',
      };

      final result = HabitLogResponse.fromJson(payload);

      expect(result.habitName, 'Meditate');
      expect(result.completed, isTrue);
      expect(result.notes, 'Done');
    });
  });
}
