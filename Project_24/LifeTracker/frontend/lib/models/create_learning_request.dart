class CreateLearningRequest {
  const CreateLearningRequest({
    required this.title,
    required this.description,
    required this.topic,
    required this.plannedMinutes,
    required this.status,
    required this.priority,
    required this.scheduledDate,
    required this.reminderTime,
    required this.notificationsEnabled,
    required this.colorHex,
    required this.iconName,
  });

  final String title;
  final String description;
  final String topic;
  final int plannedMinutes;
  final String status;
  final String priority;
  final DateTime scheduledDate;
  final DateTime reminderTime;
  final bool notificationsEnabled;
  final String colorHex;
  final String iconName;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'topic': topic,
      'plannedMinutes': plannedMinutes,
      'status': status,
      'priority': priority,
      'scheduledDate': _date(scheduledDate),
      'reminderTime': _time(reminderTime),
      'notificationsEnabled': notificationsEnabled,
      'colorHex': colorHex,
      'iconName': iconName,
    };
  }

  String _date(DateTime date) => date.toIso8601String().split('T').first;

  String _time(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }
}
