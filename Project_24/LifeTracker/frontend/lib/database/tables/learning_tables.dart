import 'package:drift/drift.dart';

/// Learning session records
class LearningSessionsTable extends Table {
  @override
  String get tableName => 'learning_sessions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  TextColumn get title => text().withLength(max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get subject => text().nullable()();
  TextColumn get resourceUrl => text().nullable()();
  TextColumn get resourceType => text().nullable()(); // VIDEO | ARTICLE | BOOK | COURSE | OTHER
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('IN_PROGRESS'))(); // IN_PROGRESS | COMPLETED | PAUSED
  IntColumn get progressPercent => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  IntColumn get rating => integer().nullable()(); // 1-5
  TextColumn get tags => text().nullable()(); // comma-separated
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
