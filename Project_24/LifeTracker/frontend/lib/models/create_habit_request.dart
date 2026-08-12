import 'dart:convert';

class CreateHabitRequest {
  final int habitCategoryId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String frequency;
  final DateTime reminderTime;
  final bool notificationsEnabled;
  final String iconName;
  final String colorHex;
  final int points;
  /// Comma-separated weekday numbers (1=Mon..7=Sun). Used for CUSTOM frequency.
  final List<int>? scheduleDays;
  /// Day-of-month anchor for MONTHLY habits.
  final DateTime? reminderDate;

  const CreateHabitRequest({
    required this.habitCategoryId,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.frequency,
    required this.reminderTime,
    required this.notificationsEnabled,
    required this.iconName,
    required this.colorHex,
    this.points = 0,
    this.scheduleDays,
    this.reminderDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'habitCategoryId': habitCategoryId,
      'name': name,
      'description': description,
      'startDate': _date(startDate),
      'endDate': endDate == null ? null : _date(endDate!),
      'frequency': frequency,
      'reminderTime': _time(reminderTime),
      'notificationsEnabled': notificationsEnabled,
      'iconName': iconName,
      'colorHex': colorHex,
      'points': points,
      'scheduleDays': scheduleDays?.join(','),
      'reminderDate': reminderDate == null ? null : _date(reminderDate!),
    };
  }

  String toRawJson() => jsonEncode(toJson());

  String _date(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  String _time(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }
}
