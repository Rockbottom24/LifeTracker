class HabitResponse {
  const HabitResponse({
    required this.id,
    required this.uuid,
    required this.name,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.reminderTime,
    this.notificationsEnabled = false,
    this.iconName,
    this.colorHex,
    this.isActive = true,
    this.habitCategoryId,
  });

  final int id;
  final String uuid;
  final String name;
  final String? description;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? reminderTime;
  final bool notificationsEnabled;
  final String? iconName;
  final String? colorHex;
  final bool isActive;
  final int? habitCategoryId;

  factory HabitResponse.fromJson(Map<String, dynamic> json) {
    return HabitResponse(
      id: _toInt(json['id']) ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      frequency: json['frequency']?.toString() ?? 'DAILY',
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']),
      reminderTime: _parseTime(json['reminderTime']),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      habitCategoryId: _toInt(json['habitCategoryId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'description': description,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'reminderTime': reminderTime == null
          ? null
          : '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}:00',
      'notificationsEnabled': notificationsEnabled,
      'iconName': iconName,
      'colorHex': colorHex,
      'isActive': isActive,
      'habitCategoryId': habitCategoryId,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    final parts = text.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(1970, 1, 1, hour, minute);
    }
    return null;
  }

  String get frequencyLabel {
    return switch (frequency.toUpperCase()) {
      'DAILY' => 'Daily',
      'WEEKLY' => 'Weekly',
      'MONTHLY' => 'Monthly',
      _ => frequency,
    };
  }

  String? get formattedReminderTime {
    if (reminderTime == null) return null;
    final hour = reminderTime!.hour;
    final minute = reminderTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }
}
