class ProfileResponse {
  const ProfileResponse({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.houseKey,
    required this.houseDisplayName,
    required this.houseMotto,
    required this.summary,
    required this.recentDays,
  });

  final int userId;
  final String email;
  final String firstName;
  final String houseKey;
  final String houseDisplayName;
  final String houseMotto;
  final ProfilePerformanceSummary summary;
  final List<DailyPerformanceSummary> recentDays;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      userId: _toInt(json['userId']) ?? 0,
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      houseKey: json['houseKey']?.toString() ?? 'stark',
      houseDisplayName: json['houseDisplayName']?.toString() ?? 'Stark',
      houseMotto: json['houseMotto']?.toString() ?? '',
      summary: ProfilePerformanceSummary.fromJson(
        Map<String, dynamic>.from((json['summary'] as Map?) ?? const {}),
      ),
      recentDays: (json['recentDays'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => DailyPerformanceSummary.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class ProfilePerformanceSummary {
  const ProfilePerformanceSummary({
    required this.sevenDayHonor,
    required this.sevenDayCompletionPercentage,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int sevenDayHonor;
  final double sevenDayCompletionPercentage;
  final int currentStreak;
  final int longestStreak;

  factory ProfilePerformanceSummary.fromJson(Map<String, dynamic> json) {
    return ProfilePerformanceSummary(
      sevenDayHonor: ProfileResponse._toInt(json['sevenDayHonor']) ?? 0,
      sevenDayCompletionPercentage: _toDouble(json['sevenDayCompletionPercentage']),
      currentStreak: ProfileResponse._toInt(json['currentStreak']) ?? 0,
      longestStreak: ProfileResponse._toInt(json['longestStreak']) ?? 0,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DailyPerformanceSummary {
  const DailyPerformanceSummary({
    required this.date,
    required this.earnedPoints,
    required this.possiblePoints,
    required this.completionPercentage,
    required this.completedHabits,
    required this.plannedHabits,
  });

  final DateTime date;
  final int earnedPoints;
  final int possiblePoints;
  final double completionPercentage;
  final int completedHabits;
  final int plannedHabits;

  factory DailyPerformanceSummary.fromJson(Map<String, dynamic> json) {
    return DailyPerformanceSummary(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      earnedPoints: ProfileResponse._toInt(json['earnedPoints']) ?? 0,
      possiblePoints: ProfileResponse._toInt(json['possiblePoints']) ?? 0,
      completionPercentage: ProfilePerformanceSummary._toDouble(json['completionPercentage']),
      completedHabits: ProfileResponse._toInt(json['completedHabits']) ?? 0,
      plannedHabits: ProfileResponse._toInt(json['plannedHabits']) ?? 0,
    );
  }
}
