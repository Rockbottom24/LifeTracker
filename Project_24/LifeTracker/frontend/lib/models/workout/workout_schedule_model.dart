import 'workout_template_model.dart';

class WorkoutScheduleModel {
  const WorkoutScheduleModel({
    required this.id,
    this.uuid,
    required this.scheduledDate,
    this.template,
    required this.customTitle,
    required this.status, // PLANNED, COMPLETED, MISSED, REST
    this.completedAt,
    this.notes,
  });

  final int id;
  final String? uuid;
  final DateTime scheduledDate;
  final WorkoutTemplateModel? template;
  final String customTitle;
  final String status;
  final DateTime? completedAt;
  final String? notes;

  bool get isCompleted => status == 'COMPLETED';
  bool get isMissed => status == 'MISSED';
  bool get isRest => status == 'REST' || template == null;
  bool get isPlanned => status == 'PLANNED';

  factory WorkoutScheduleModel.fromJson(Map<String, dynamic> json) {
    return WorkoutScheduleModel(
      id: _toInt(json['id']) ?? 0,
      uuid: json['uuid']?.toString(),
      scheduledDate: _parseDate(json['scheduledDate']) ?? DateTime.now(),
      template: json['template'] != null
          ? WorkoutTemplateModel.fromJson(Map<String, dynamic>.from(json['template'] as Map))
          : null,
      customTitle: json['customTitle'] as String? ?? 'Rest Day',
      status: json['status'] as String? ?? 'PLANNED',
      completedAt: _parseDateTime(json['completedAt']),
      notes: json['notes'] as String?,
    );
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
