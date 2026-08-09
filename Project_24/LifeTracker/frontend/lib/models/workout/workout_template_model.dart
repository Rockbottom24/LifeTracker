class WorkoutTemplateExerciseModel {
  const WorkoutTemplateExerciseModel({
    this.id,
    this.uuid,
    required this.exerciseName,
    this.sets = 3,
    this.reps = '12-15',
    this.restSeconds = 45,
    this.sequenceOrder = 1,
  });

  final int? id;
  final String? uuid;
  final String exerciseName;
  final int sets;
  final String reps;
  final int restSeconds;
  final int sequenceOrder;

  factory WorkoutTemplateExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplateExerciseModel(
      id: _toInt(json['id']),
      uuid: json['uuid']?.toString(),
      exerciseName: json['exerciseName'] as String? ?? 'Exercise',
      sets: _toInt(json['sets']) ?? 3,
      reps: json['reps']?.toString() ?? '12-15',
      restSeconds: _toInt(json['restSeconds']) ?? 45,
      sequenceOrder: _toInt(json['sequenceOrder']) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'sequenceOrder': sequenceOrder,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class WorkoutTemplateModel {
  const WorkoutTemplateModel({
    this.id,
    this.uuid,
    required this.name,
    required this.category,
    this.description,
    this.isPreset = false,
    this.exercises = const [],
  });

  final int? id;
  final String? uuid;
  final String name;
  final String category;
  final String? description;
  final bool isPreset;
  final List<WorkoutTemplateExerciseModel> exercises;

  factory WorkoutTemplateModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['exercises'] as List<dynamic>?;
    final exercises = rawList != null
        ? rawList.map((item) => WorkoutTemplateExerciseModel.fromJson(Map<String, dynamic>.from(item as Map))).toList()
        : <WorkoutTemplateExerciseModel>[];

    return WorkoutTemplateModel(
      id: WorkoutTemplateExerciseModel._toInt(json['id']),
      uuid: json['uuid']?.toString(),
      name: json['name'] as String? ?? 'Template',
      category: json['category'] as String? ?? 'GENERAL',
      description: json['description'] as String?,
      isPreset: json['preset'] as bool? ?? json['isPreset'] as bool? ?? false,
      exercises: exercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}
