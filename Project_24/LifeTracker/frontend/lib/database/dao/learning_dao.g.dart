// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_dao.dart';

// ignore_for_file: type=lint
mixin _$LearningDaoMixin on DatabaseAccessor<AppDatabase> {
  $LearningSessionsTableTable get learningSessionsTable =>
      attachedDatabase.learningSessionsTable;
  LearningDaoManager get managers => LearningDaoManager(this);
}

class LearningDaoManager {
  final _$LearningDaoMixin _db;
  LearningDaoManager(this._db);
  $$LearningSessionsTableTableTableManager get learningSessionsTable =>
      $$LearningSessionsTableTableTableManager(
        _db.attachedDatabase,
        _db.learningSessionsTable,
      );
}
