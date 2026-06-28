class HabitLogResponse {
  const HabitLogResponse({
    this.habitId,
    this.completed = false,
  });

  final int? habitId;
  final bool completed;

  factory HabitLogResponse.fromJson(Map<String, dynamic> json) {
    return HabitLogResponse(
      habitId: _toInt(json['habitId']),
      completed: json['completed'] as bool? ?? true,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
