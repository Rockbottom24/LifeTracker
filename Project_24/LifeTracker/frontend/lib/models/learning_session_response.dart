import 'learning_priority.dart';
import 'learning_status.dart';

class LearningSessionResponse {
  const LearningSessionResponse({
    required this.id,
    required this.uuid,
    required this.title,
    this.description,
    this.topic,
    this.resourceType,
    this.resourceUrl,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.status,
    required this.priority,
    this.scheduledDate,
    this.completedDate,
    this.reminderTime,
    this.notificationsEnabled = false,
    this.colorHex,
    this.iconName,
    this.displayOrder = 0,
  });

  final int id;
  final String uuid;
  final String title;
  final String? description;
  final String? topic;
  final String? resourceType;
  final String? resourceUrl;
  final int plannedMinutes;
  final int completedMinutes;
  final String status;
  final String priority;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final DateTime? reminderTime;
  final bool notificationsEnabled;
  final String? colorHex;
  final String? iconName;
  final int displayOrder;

  LearningStatus get statusEnum => LearningStatus.fromApiValue(status);
  LearningPriority get priorityEnum => LearningPriority.fromApiValue(priority);

  double get progressFraction {
    if (plannedMinutes <= 0) return 0;
    return (completedMinutes / plannedMinutes).clamp(0.0, 1.0);
  }

  int get progressPercent => (progressFraction * 100).round();

  String? get formattedReminderTime {
    if (reminderTime == null) return null;
    final hour = reminderTime!.hour;
    final minute = reminderTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $period';
  }

  factory LearningSessionResponse.fromJson(Map<String, dynamic> json) {
    return LearningSessionResponse(
      id: _toInt(json['id']) ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      topic: json['topic'] as String?,
      resourceType: json['resourceType'] as String?,
      resourceUrl: json['resourceUrl'] as String?,
      plannedMinutes: _toInt(json['plannedMinutes']) ?? 0,
      completedMinutes: _toInt(json['completedMinutes']) ?? 0,
      status: json['status']?.toString() ?? 'PLANNED',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      scheduledDate: _parseDate(json['scheduledDate']),
      completedDate: _parseDate(json['completedDate']),
      reminderTime: _parseTime(json['reminderTime']),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      colorHex: json['colorHex'] as String?,
      iconName: json['iconName'] as String?,
      displayOrder: _toInt(json['displayOrder']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'description': description,
      'topic': topic,
      'resourceType': resourceType,
      'resourceUrl': resourceUrl,
      'plannedMinutes': plannedMinutes,
      'completedMinutes': completedMinutes,
      'status': status,
      'priority': priority,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'reminderTime': reminderTime == null
          ? null
          : '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}:00',
      'notificationsEnabled': notificationsEnabled,
      'colorHex': colorHex,
      'iconName': iconName,
      'displayOrder': displayOrder,
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
    final parts = value.toString().split(':');
    if (parts.length >= 2) {
      return DateTime(1970, 1, 1, int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
    }
    return null;
  }
}
