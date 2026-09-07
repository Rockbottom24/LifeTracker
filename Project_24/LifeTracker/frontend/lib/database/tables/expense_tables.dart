import 'package:drift/drift.dart';

/// Expense categories
class ExpenseCategoriesTable extends Table {
  @override
  String get tableName => 'expense_categories';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Individual expenses
class ExpensesTable extends Table {
  @override
  String get tableName => 'expenses';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(max: 36)();
  IntColumn get categoryId => integer()();
  TextColumn get title => text().withLength(max: 200)();
  TextColumn get description => text().nullable()();
  // Stored as integer cents to avoid floating point issues (e.g. 1500 = ₹15.00)
  IntColumn get amountCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  DateTimeColumn get spentAt => dateTime()();
  TextColumn get paymentMethod => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
