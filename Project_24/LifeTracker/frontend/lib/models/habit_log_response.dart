class HabitLogResponse {
  const HabitLogResponse({
    this.habitId,
    this.completed = false,
    this.habitPoints = 0,
    this.pointsAwarded = 0,
  });

  final int? habitId;
  final bool completed;
  final int habitPoints;
  final int pointsAwarded;

  factory HabitLogResponse.fromJson(Map<String, dynamic> json) {
    return HabitLogResponse(
      habitId: _toInt(json['habitId']),
      completed: json['completed'] as bool? ?? true,
      habitPoints: _toInt(json['habitPoints']) ?? 0,
      pointsAwarded: _toInt(json['pointsAwarded']) ?? 0,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
