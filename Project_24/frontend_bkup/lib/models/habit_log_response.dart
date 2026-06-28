class HabitLogResponse {
  HabitLogResponse({
    this.habitId,
    this.habitUuid,
    this.habitName,
    this.habitCategoryId,
    this.displayOrder,
    this.habitActive = false,
    this.habitLogId,
    this.habitLogUuid,
    this.logDate,
    this.loggedAt,
    this.completionStatus,
    this.completed = false,
    this.value,
    this.notes,
  });

  final int? habitId;
  final String? habitUuid;
  final String? habitName;
  final int? habitCategoryId;
  final int? displayOrder;
  final bool habitActive;
  final int? habitLogId;
  final String? habitLogUuid;
  final DateTime? logDate;
  final DateTime? loggedAt;
  final String? completionStatus;
  final bool completed;
  final double? value;
  final String? notes;

  factory HabitLogResponse.fromJson(Map<String, dynamic> json) {
    return HabitLogResponse(
      habitId: _toInt(json['habitId']),
      habitUuid: json['habitUuid']?.toString(),
      habitName: json['habitName'] as String?,
      habitCategoryId: _toInt(json['habitCategoryId']),
      displayOrder: _toInt(json['displayOrder']),
      habitActive: json['habitActive'] as bool? ?? false,
      habitLogId: _toInt(json['habitLogId']),
      habitLogUuid: json['habitLogUuid']?.toString(),
      logDate: _parseDate(json['logDate']),
      loggedAt: _parseDate(json['loggedAt']),
      completionStatus: json['completionStatus'] as String?,
      completed: json['completed'] as bool? ?? false,
      value: _toDouble(json['value']),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'habitUuid': habitUuid,
        'habitName': habitName,
        'habitCategoryId': habitCategoryId,
        'displayOrder': displayOrder,
        'habitActive': habitActive,
        'habitLogId': habitLogId,
        'habitLogUuid': habitLogUuid,
        'logDate': logDate?.toIso8601String(),
        'loggedAt': loggedAt?.toIso8601String(),
        'completionStatus': completionStatus,
        'completed': completed,
        'value': value,
        'notes': notes,
      };

  static int? _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static double? _toDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse(value.toString());
  }
}
