class HabitCategoryResponse {
  const HabitCategoryResponse({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String? code;
  final String? description;
  final int displayOrder;
  final bool isActive;

  factory HabitCategoryResponse.fromJson(Map<String, dynamic> json) {
    return HabitCategoryResponse(
      id: _toInt(json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      description: json['description'] as String?,
      displayOrder: _toInt(json['displayOrder']) ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
