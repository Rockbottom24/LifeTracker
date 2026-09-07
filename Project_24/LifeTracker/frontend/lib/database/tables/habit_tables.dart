import 'package:drift/drift.dart';

/// Habit categories (seed data stored locally)
class HabitCategoriesTable extends Table {
  @override
  String get tableName => 'habit_categories';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  TextColumn get code => text().withLength(max: 100)();
  TextColumn get name => text().withLength(max: 150)();
  TextColumn get description => text().nullable()();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// User-defined habits
class HabitsTable extends Table {
  @override
  String get tableName => 'habits';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  IntColumn get habitCategoryId => integer()();
  TextColumn get name => text().withLength(max: 150)();
  TextColumn get description => text().nullable()();
  // frequency: DAILY | WEEKLY | MONTHLY | CUSTOM
  TextColumn get frequency => text().withDefault(const Constant('DAILY'))();
  // comma-separated ISO weekday numbers for CUSTOM (e.g. "1,2,3,4,5")
  TextColumn get scheduleDays => text().nullable()();
  // day-of-month anchor for MONTHLY habits
  DateTimeColumn get reminderDate => dateTime().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get reminderTime => text().nullable()(); // "HH:mm:ss"
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get points => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // sync metadata
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Daily habit completion logs
class HabitLogsTable extends Table {
  @override
  String get tableName => 'habit_logs';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  IntColumn get habitId => integer()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
