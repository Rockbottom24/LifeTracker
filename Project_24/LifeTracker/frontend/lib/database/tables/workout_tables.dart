import 'package:drift/drift.dart';

/// Workout template (e.g. "Push Day", "Pull Day")
class WorkoutTemplatesTable extends Table {
  @override
  String get tableName => 'workout_templates';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  TextColumn get name => text().withLength(max: 150)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()(); // PUSH | PULL | LEGS | UPPER | LOWER | REST
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Exercises within a workout template
class WorkoutTemplateExercisesTable extends Table {
  @override
  String get tableName => 'workout_template_exercises';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  IntColumn get templateId => integer()();
  TextColumn get name => text().withLength(max: 150)();
  IntColumn get sets => integer().withDefault(const Constant(3))();
  TextColumn get reps => text().withDefault(const Constant('10'))();
  TextColumn get notes => text().nullable()();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Weekly workout schedule (which template is scheduled on which date)
class WorkoutScheduleTable extends Table {
  @override
  String get tableName => 'workout_schedule';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  // nullable = rest day
  IntColumn get templateId => integer().nullable()();
  DateTimeColumn get scheduledDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('SCHEDULED'))(); // SCHEDULED | COMPLETED | MISSED
  TextColumn get notes => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
