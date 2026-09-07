import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/learning_tables.dart';

part 'learning_dao.g.dart';

@DriftAccessor(tables: [LearningSessionsTable])
class LearningDao extends DatabaseAccessor<AppDatabase>
    with _$LearningDaoMixin {
  LearningDao(super.db);

  Future<List<LearningSessionsTableData>> getAllSessions() =>
      (select(learningSessionsTable)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Stream<List<LearningSessionsTableData>> watchAllSessions() =>
      (select(learningSessionsTable)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<List<LearningSessionsTableData>> getSessionsByStatus(
          String status) =>
      (select(learningSessionsTable)
            ..where(
                (t) => t.deletedAt.isNull() & t.status.equals(status))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Stream<List<LearningSessionsTableData>> watchSessionsByStatus(
          String status) =>
      (select(learningSessionsTable)
            ..where(
                (t) => t.deletedAt.isNull() & t.status.equals(status))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<LearningSessionsTableData?> getSessionById(int id) =>
      (select(learningSessionsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertSession(LearningSessionsTableCompanion session) =>
      into(learningSessionsTable).insert(session);

  Future<bool> updateSession(LearningSessionsTableCompanion session) =>
      update(learningSessionsTable).replace(session);

  Future<void> softDeleteSession(int id) =>
      (update(learningSessionsTable)..where((t) => t.id.equals(id)))
          .write(LearningSessionsTableCompanion(
        deletedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  /// Total minutes studied in a time range
  Future<int> getTotalMinutesInRange(DateTime from, DateTime to) async {
    final sessions = await (select(learningSessionsTable)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.startedAt.isBiggerOrEqualValue(from) &
              t.startedAt.isSmallerThanValue(to)))
        .get();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  Future<int> getCompletedCount() async {
    final sessions = await getSessionsByStatus('COMPLETED');
    return sessions.length;
  }

  Future<List<LearningSessionsTableData>> getUnsyncedSessions() =>
      (select(learningSessionsTable)
            ..where((t) => t.isSynced.equals(false)))
          .get();

  Future<void> markSessionsSynced(List<int> ids) =>
      (update(learningSessionsTable)..where((t) => t.id.isIn(ids)))
          .write(const LearningSessionsTableCompanion(isSynced: Value(true)));
}
