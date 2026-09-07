import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workout_tables.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [WorkoutTemplatesTable, WorkoutTemplateExercisesTable, WorkoutScheduleTable])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // ── Templates ───────────────────────────────────────────────────────────────

  Future<List<WorkoutTemplatesTableData>> getAllTemplates() =>
      (select(workoutTemplatesTable)
            ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Stream<List<WorkoutTemplatesTableData>> watchAllTemplates() =>
      (select(workoutTemplatesTable)
            ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<WorkoutTemplatesTableData?> getTemplateById(int id) =>
      (select(workoutTemplatesTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertTemplate(WorkoutTemplatesTableCompanion template) =>
      into(workoutTemplatesTable).insert(template);

  Future<bool> updateTemplate(WorkoutTemplatesTableCompanion template) =>
      update(workoutTemplatesTable).replace(template);

  Future<void> softDeleteTemplate(int id) =>
      (update(workoutTemplatesTable)..where((t) => t.id.equals(id))).write(
          WorkoutTemplatesTableCompanion(
        deletedAt: Value(DateTime.now()),
        isActive: const Value(false),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  // ── Template Exercises ──────────────────────────────────────────────────────

  Future<List<WorkoutTemplateExercisesTableData>> getExercisesForTemplate(
          int templateId) =>
      (select(workoutTemplateExercisesTable)
            ..where((t) =>
                t.templateId.equals(templateId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
          .get();

  Stream<List<WorkoutTemplateExercisesTableData>> watchExercisesForTemplate(
          int templateId) =>
      (select(workoutTemplateExercisesTable)
            ..where((t) =>
                t.templateId.equals(templateId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
          .watch();

  Future<int> insertExercise(
          WorkoutTemplateExercisesTableCompanion exercise) =>
      into(workoutTemplateExercisesTable).insert(exercise);

  Future<bool> updateExercise(
          WorkoutTemplateExercisesTableCompanion exercise) =>
      update(workoutTemplateExercisesTable).replace(exercise);

  Future<void> softDeleteExercise(int id) =>
      (update(workoutTemplateExercisesTable)..where((t) => t.id.equals(id)))
          .write(WorkoutTemplateExercisesTableCompanion(
        deletedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ));

  // ── Schedule ────────────────────────────────────────────────────────────────

  Future<List<WorkoutScheduleTableData>> getScheduleForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return (select(workoutScheduleTable)
          ..where((t) =>
              t.scheduledDate.isBiggerOrEqualValue(weekStart) &
              t.scheduledDate.isSmallerThanValue(weekEnd))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  Stream<List<WorkoutScheduleTableData>> watchScheduleForWeek(
      DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return (select(workoutScheduleTable)
          ..where((t) =>
              t.scheduledDate.isBiggerOrEqualValue(weekStart) &
              t.scheduledDate.isSmallerThanValue(weekEnd))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .watch();
  }

  Future<WorkoutScheduleTableData?> getScheduleForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(workoutScheduleTable)
          ..where((t) =>
              t.scheduledDate.isBiggerOrEqualValue(startOfDay) &
              t.scheduledDate.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }

  Future<int> insertSchedule(WorkoutScheduleTableCompanion schedule) =>
      into(workoutScheduleTable).insert(schedule);

  Future<bool> updateSchedule(WorkoutScheduleTableCompanion schedule) =>
      update(workoutScheduleTable).replace(schedule);

  /// Mark today as completed
  Future<void> completeSchedule(int id, {String? notes}) =>
      (update(workoutScheduleTable)..where((t) => t.id.equals(id))).write(
          WorkoutScheduleTableCompanion(
        status: const Value('COMPLETED'),
        completedAt: Value(DateTime.now()),
        notes: Value(notes),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  /// Mark today as missed (shifts the cycle forward)
  Future<void> markMissed(int id) =>
      (update(workoutScheduleTable)..where((t) => t.id.equals(id))).write(
          WorkoutScheduleTableCompanion(
        status: const Value('MISSED'),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  Future<List<WorkoutScheduleTableData>> getUnsyncedSchedules() =>
      (select(workoutScheduleTable)
            ..where((t) => t.isSynced.equals(false)))
          .get();

  Future<void> markSchedulesSynced(List<int> ids) =>
      (update(workoutScheduleTable)..where((t) => t.id.isIn(ids)))
          .write(const WorkoutScheduleTableCompanion(isSynced: Value(true)));
}
