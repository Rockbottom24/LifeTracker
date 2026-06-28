class DashboardResponse {
  DashboardResponse({
    this.currentDate,
    this.greeting,
    this.userName,
    this.summary,
    this.todayHabits,
  });

  final DateTime? currentDate;
  final String? greeting;
  final String? userName;
  final DashboardSummary? summary;
  final List<TodayHabit>? todayHabits;

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      currentDate: _parseDate(json['currentDate']),
      greeting: json['greeting'] as String?,
      userName: json['userName'] as String?,
      summary: json['summary'] == null
          ? null
          : DashboardSummary.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            ),
      todayHabits: (json['todayHabits'] as List<dynamic>?)
          ?.map((item) => TodayHabit.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'currentDate': currentDate?.toIso8601String(),
        'greeting': greeting,
        'userName': userName,
        'summary': summary?.toJson(),
        'todayHabits': todayHabits?.map((habit) => habit.toJson()).toList(),
      };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse(value.toString());
  }
}

class DashboardSummary {
  DashboardSummary({
    this.totalHabits = 0,
    this.completedHabits = 0,
    this.pendingHabits = 0,
    this.completionPercentage = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  final int totalHabits;
  final int completedHabits;
  final int pendingHabits;
  final double completionPercentage;
  final int currentStreak;
  final int longestStreak;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalHabits: _toInt(json['totalHabits']),
      completedHabits: _toInt(json['completedHabits']),
      pendingHabits: _toInt(json['pendingHabits']),
      completionPercentage: _toDouble(json['completionPercentage']),
      currentStreak: _toInt(json['currentStreak']),
      longestStreak: _toInt(json['longestStreak']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalHabits': totalHabits,
        'completedHabits': completedHabits,
        'pendingHabits': pendingHabits,
        'completionPercentage': completionPercentage,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };

  static int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _toDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}

class TodayHabit {
  TodayHabit({
    this.habitId,
    this.habitName,
    this.icon,
    this.color,
    this.completed = false,
    this.targetValue,
    this.currentValue,
  });

  final int? habitId;
  final String? habitName;
  final String? icon;
  final String? color;
  final bool completed;
  final double? targetValue;
  final double? currentValue;

  factory TodayHabit.fromJson(Map<String, dynamic> json) {
    return TodayHabit(
      habitId: DashboardSummary._toInt(json['habitId']),
      habitName: json['habitName'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      completed: json['completed'] as bool? ?? false,
      targetValue: DashboardSummary._toDouble(json['targetValue']),
      currentValue: DashboardSummary._toDouble(json['currentValue']),
    );
  }

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'habitName': habitName,
        'icon': icon,
        'color': color,
        'completed': completed,
        'targetValue': targetValue,
        'currentValue': currentValue,
      };
}
