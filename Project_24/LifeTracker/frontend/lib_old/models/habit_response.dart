class HabitResponse {
  HabitResponse({
    this.id,
    this.uuid,
    this.userId,
    this.habitCategoryId,
    this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.displayOrder,
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? uuid;
  final int? userId;
  final int? habitCategoryId;
  final String? name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? displayOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HabitResponse.fromJson(Map<String, dynamic> json) {
    return HabitResponse(
      id: _toInt(json['id']),
      uuid: json['uuid']?.toString(),
      userId: _toInt(json['userId']),
      habitCategoryId: _toInt(json['habitCategoryId']),
      name: json['name'] as String?,
      description: json['description'] as String?,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      displayOrder: _toInt(json['displayOrder']),
      isActive: json['isActive'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'userId': userId,
        'habitCategoryId': habitCategoryId,
        'name': name,
        'description': description,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'displayOrder': displayOrder,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static int? _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse(value.toString());
  }
}
