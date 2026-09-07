import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/habit_tables.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [HabitCategoriesTable, HabitsTable, HabitLogsTable])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<HabitCategoriesTableData>> getAllCategories() =>
      (select(habitCategoriesTable)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
          .get();

  Stream<List<HabitCategoriesTableData>> watchAllCategories() =>
      (select(habitCategoriesTable)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
          .watch();

  // ── Habits ──────────────────────────────────────────────────────────────────

  Future<List<HabitsTableData>> getAllActiveHabits() =>
      (select(habitsTable)
            ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
          .get();

  Stream<List<HabitsTableData>> watchAllActiveHabits() =>
      (select(habitsTable)
            ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
          .watch();

  Future<HabitsTableData?> getHabitById(int id) =>
      (select(habitsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertHabit(HabitsTableCompanion habit) =>
      into(habitsTable).insert(habit);

  Future<bool> updateHabit(HabitsTableCompanion habit) =>
      update(habitsTable).replace(habit);

  Future<void> softDeleteHabit(int id) => (update(habitsTable)
        ..where((t) => t.id.equals(id)))
      .write(HabitsTableCompanion(
        deletedAt: Value(DateTime.now()),
        isActive: const Value(false),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  Future<List<HabitsTableData>> getUnsyncedHabits() =>
      (select(habitsTable)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markHabitsSynced(List<int> ids) => (update(habitsTable)
        ..where((t) => t.id.isIn(ids)))
      .write(const HabitsTableCompanion(isSynced: Value(true)));

  // ── Habit Logs ──────────────────────────────────────────────────────────────

  /// Returns all logs for today (midnight to now)
  Future<List<HabitLogsTableData>> getTodayLogs() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(habitLogsTable)
          ..where((t) =>
              t.loggedAt.isBiggerOrEqualValue(startOfDay) &
              t.loggedAt.isSmallerThanValue(endOfDay) &
              t.deletedAt.isNull()))
        .get();
  }

  Stream<List<HabitLogsTableData>> watchTodayLogs() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(habitLogsTable)
          ..where((t) =>
              t.loggedAt.isBiggerOrEqualValue(startOfDay) &
              t.loggedAt.isSmallerThanValue(endOfDay) &
              t.deletedAt.isNull()))
        .watch();
  }

  /// Returns all logs for a specific habit (for streak calculation)
  Future<List<HabitLogsTableData>> getLogsForHabit(int habitId) =>
      (select(habitLogsTable)
            ..where((t) => t.habitId.equals(habitId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
          .get();

  /// Returns logs within a date range (for analytics)
  Future<List<HabitLogsTableData>> getLogsInRange(
      DateTime from, DateTime to) =>
      (select(habitLogsTable)
            ..where((t) =>
                t.loggedAt.isBiggerOrEqualValue(from) &
                t.loggedAt.isSmallerThanValue(to) &
                t.deletedAt.isNull()))
          .get();

  Future<int> insertLog(HabitLogsTableCompanion log) =>
      into(habitLogsTable).insert(log);

  Future<void> softDeleteLog(int id) => (update(habitLogsTable)
        ..where((t) => t.id.equals(id)))
      .write(HabitLogsTableCompanion(
        deletedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ));

  /// Check if a habit was completed today
  Future<bool> isCompletedToday(int habitId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final count = await (select(habitLogsTable)
          ..where((t) =>
              t.habitId.equals(habitId) &
              t.loggedAt.isBiggerOrEqualValue(startOfDay) &
              t.loggedAt.isSmallerThanValue(endOfDay) &
              t.deletedAt.isNull()))
        .get();
    return count.isNotEmpty;
  }

  Future<List<HabitLogsTableData>> getUnsyncedLogs() =>
      (select(habitLogsTable)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markLogsSynced(List<int> ids) => (update(habitLogsTable)
        ..where((t) => t.id.isIn(ids)))
      .write(const HabitLogsTableCompanion(isSynced: Value(true)));

  // ── Streak calculation ──────────────────────────────────────────────────────

  /// Calculate current streak for a habit (consecutive days completed)
  Future<int> getCurrentStreak(int habitId) async {
    final logs = await getLogsForHabit(habitId);
    if (logs.isEmpty) return 0;

    final logDates = logs
        .map((l) => DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // descending

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    if (logDates.first != todayDate && logDates.first != yesterdayDate) {
      return 0;
    }

    int streak = 1;
    for (int i = 1; i < logDates.length; i++) {
      final expected = logDates[i - 1].subtract(const Duration(days: 1));
      if (logDates[i] == expected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Calculate longest streak for a habit
  Future<int> getLongestStreak(int habitId) async {
    final logs = await getLogsForHabit(habitId);
    if (logs.isEmpty) return 0;

    final logDates = logs
        .map((l) => DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day))
        .toSet()
        .toList()
      ..sort();

    int longest = 1;
    int current = 1;
    for (int i = 1; i < logDates.length; i++) {
      final expected = logDates[i - 1].add(const Duration(days: 1));
      if (logDates[i] == expected) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }
}
