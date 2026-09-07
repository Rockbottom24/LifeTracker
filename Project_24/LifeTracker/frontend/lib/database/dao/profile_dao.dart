import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_profile_table.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [UserProfileTable])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  Future<UserProfileTableData?> getProfile() =>
      (select(userProfileTable)..limit(1)).getSingleOrNull();

  Future<int> insertProfile(UserProfileTableCompanion profile) =>
      into(userProfileTable).insert(profile);

  Future<bool> updateProfile(UserProfileTableCompanion profile) =>
      update(userProfileTable).replace(profile);

  /// Upsert — insert on first launch, update on subsequent calls
  Future<void> upsertProfile(UserProfileTableCompanion profile) =>
      into(userProfileTable).insertOnConflictUpdate(profile);

  Future<void> clearProfile() => delete(userProfileTable).go();

  Stream<UserProfileTableData?> watchProfile() =>
      (select(userProfileTable)..limit(1)).watchSingleOrNull();
}
