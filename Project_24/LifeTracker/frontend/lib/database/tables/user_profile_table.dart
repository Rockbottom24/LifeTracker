import 'package:drift/drift.dart';

/// User profile — replaces app_user + user_settings on server
class UserProfileTable extends Table {
  @override
  String get tableName => 'user_profile';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get googleId => text().withLength(max: 255)();
  TextColumn get email => text().withLength(max: 255)();
  TextColumn get displayName => text().withLength(max: 150).nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get timezone => text().withDefault(const Constant('Asia/Kolkata'))();
  TextColumn get locale => text().withDefault(const Constant('en_IN'))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  // house key / style preference kept from current app
  TextColumn get houseKey => text().nullable()();
  TextColumn get appStyle => text().withDefault(const Constant('classic'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
