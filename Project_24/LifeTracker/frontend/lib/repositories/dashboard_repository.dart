import '../local/local_cache_store.dart';
import '../local/offline_data_store.dart';
import '../models/dashboard_response.dart';

class DashboardRepository {
  DashboardRepository(this._cache, this._offlineStore);

  final LocalCacheStore _cache;
  final OfflineDataStore _offlineStore;

  DashboardResponse buildLocal() {
    final habits = _offlineStore.getVisibleHabits();
    final completedIds = _cache.getCompletedTodayHabitIds();
    final activeHabits = habits.where((item) => item.habit.isActive).toList();
    final total = activeHabits.length;
    final completed = activeHabits.where((item) => completedIds.contains(item.habit.id)).length;
    final pending = (total - completed).clamp(0, total);
    final completionPercentage = total == 0 ? 0.0 : (completed / total) * 100.0;

    final cached = _cache.getDashboard();
    final streak = cached?.summary?.currentStreak ?? 0;
    final longestStreak = cached?.summary?.longestStreak ?? 0;

    return DashboardResponse(
      currentDate: DateTime.now(),
      greeting: cached?.greeting,
      userName: cached?.userName,
      summary: DashboardSummary(
        totalHabits: total,
        completedHabits: completed,
        pendingHabits: pending,
        completionPercentage: completionPercentage,
        currentStreak: streak,
        longestStreak: longestStreak,
      ),
      todayHabits: activeHabits
          .map(
            (item) => TodayHabit(
              habitId: item.habit.id,
              habitName: item.habit.name,
              icon: item.habit.iconName,
              color: item.habit.colorHex,
              completed: completedIds.contains(item.habit.id),
            ),
          )
          .toList(),
    );
  }

  Future<void> saveLocalSnapshot() async {
    await _cache.saveDashboard(buildLocal());
  }
}
