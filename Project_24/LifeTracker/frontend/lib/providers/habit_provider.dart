import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/local_cache_store.dart';
import '../models/create_habit_request.dart';
import '../models/habit_category_response.dart';
import '../models/habit_frequency.dart';
import '../models/habit_response.dart';
import '../models/update_habit_request.dart';
import '../services/api_client.dart';
import '../services/habit_service.dart';
import '../services/user_xp_manager.dart';
import '../services/widget_service.dart';
import '../sync/sync_status.dart';
import '../utils/habit_notification_helper.dart';

/// Fallback categories used when the server is unreachable and the cache is empty.
/// These mirror the seed data in AppDatabase._seedHabitCategories().
const _kFallbackCategories = [
  HabitCategoryResponse(id: 1, name: 'Health & Fitness', code: 'HEALTH_AND_FITNESS', displayOrder: 1),
  HabitCategoryResponse(id: 2, name: 'Mindfulness', code: 'MINDFULNESS', displayOrder: 2),
  HabitCategoryResponse(id: 3, name: 'Learning & Growth', code: 'LEARNING_AND_GROWTH', displayOrder: 3),
  HabitCategoryResponse(id: 4, name: 'Social', code: 'SOCIAL', displayOrder: 4),
  HabitCategoryResponse(id: 5, name: 'Finance', code: 'FINANCE', displayOrder: 5),
  HabitCategoryResponse(id: 6, name: 'Creativity', code: 'CREATIVITY', displayOrder: 6),
  HabitCategoryResponse(id: 7, name: 'Other', code: 'OTHER', displayOrder: 7),
];

class HabitProvider extends ChangeNotifier {
  HabitProvider(this._habitService, this._cache) {
    _hydrateFromLocal();
  }

  final HabitService _habitService;
  final LocalCacheStore _cache;

  bool isLoading = false;
  bool isRefreshing = false;
  bool isLoadingCategories = false;
  bool isSaving = false;
  bool isOffline = false;
  String? errorMessage;
  String? categoriesErrorMessage;
  String? syncMessage;
  DateTime? lastSyncedAt;
  List<HabitResponse> habits = [];
  List<HabitCategoryResponse> categories = [];
  final Set<int> _completedToday = {};
  final Map<int, int> _streaks = {};

  /// Returns active streak count for a habit (starts at 0, increases only on completion).
  int streakForHabit(int habitId) => _streaks[habitId] ?? 0;

  /// Returns habits scheduled for [date] that are active.
  List<HabitResponse> habitsForDate(DateTime date) {
    return habits.where((h) => h.isActive && h.isScheduledForDate(date)).toList();
  }

  /// Returns active habits scheduled for today.
  List<HabitResponse> get todayHabits => habitsForDate(DateTime.now());

  bool isCompletedToday(int habitId) => _completedToday.contains(habitId);

  SyncStatus? syncStatusForHabit(int habitId) => _habitService.syncStatusFor(habitId);

  bool get hasPendingSync => _habitService.hasPendingSync;

  void _hydrateFromLocal() {
    habits = _habitService.getHabitsLocal();
    final cachedCategories = _cache.getHabitCategories();
    if (cachedCategories.isNotEmpty) {
      categories = cachedCategories;
    }
    _completedToday
      ..clear()
      ..addAll(_cache.getCompletedTodayHabitIds());
    _loadStreaks();
    _refreshSyncState();
  }

  void _loadStreaks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final h in habits) {
        _streaks[h.id] = prefs.getInt('habit_streak_${h.id}') ?? 0;
      }
      notifyListeners();
    } catch (_) {}
  }

  void _refreshSyncState({bool networkUnavailable = false}) {
    if (_habitService.hasPendingSync) {
      syncMessage = 'Saved locally. Will sync when server is available.';
      isOffline = false;
    } else if (networkUnavailable && habits.isNotEmpty) {
      syncMessage = "You're offline. Showing your last synced data.";
      isOffline = true;
    } else {
      syncMessage = null;
      isOffline = false;
    }
    lastSyncedAt = _cache.getLastSynced(CacheEntity.habits);
  }

  Future<void> loadHabits() async {
    final hadCachedData = habits.isNotEmpty;
    isLoading = !hadCachedData;
    isRefreshing = hadCachedData;
    if (!hadCachedData) {
      errorMessage = null;
    }

    habits = _habitService.getHabitsLocal();
    _completedToday
      ..clear()
      ..addAll(_cache.getCompletedTodayHabitIds());
    _loadStreaks();
    _refreshSyncState();
    notifyListeners();

    try {
      await _habitService.syncWithServer();
      habits = _habitService.getHabitsLocal();
      _completedToday
        ..clear()
        ..addAll(_cache.getCompletedTodayHabitIds());
      _loadStreaks();
      _refreshSyncState();
      errorMessage = null;
    } on ApiException catch (e) {
      if (habits.isEmpty) {
        errorMessage = e.message;
        syncMessage = null;
        isOffline = false;
      } else {
        _refreshSyncState(networkUnavailable: true);
        errorMessage = null;
      }
    } catch (e) {
      if (habits.isEmpty) {
        errorMessage = e.toString();
        syncMessage = null;
        isOffline = false;
      } else {
        _refreshSyncState(networkUnavailable: true);
        errorMessage = null;
      }
    } finally {
      isLoading = false;
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    // If we already have categories (from cache or previous load), show immediately
    if (categories.isNotEmpty) {
      notifyListeners();
      return;
    }

    // Use fallback categories instantly — no server wait
    categories = _kFallbackCategories;
    categoriesErrorMessage = null;
    isLoadingCategories = false;
    notifyListeners();

    // Try server in background to get updated categories (non-blocking)
    try {
      final serverCategories = await _habitService.getCategories();
      if (serverCategories.isNotEmpty) {
        categories = serverCategories;
        categoriesErrorMessage = null;
        notifyListeners();
      }
    } catch (_) {
      // Server unavailable — fallback already shown, nothing to do
    }
  }

  Future<HabitCategoryResponse?> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final code = trimmed.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '_');
    final newCat = HabitCategoryResponse(
      id: categories.length + 100,
      name: trimmed,
      code: code,
      displayOrder: categories.length + 1,
    );
    categories = [...categories, newCat];
    await _cache.saveHabitCategories(categories);
    notifyListeners();
    return newCat;
  }

  Future<HabitResponse?> createHabit(CreateHabitRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final habit = await _habitService.createHabit(request.toJson());
      habits = _habitService.getHabitsLocal();
      _refreshSyncState();
      notifyListeners();
      return habit;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateHabit(int id, UpdateHabitRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _habitService.updateHabit(id, request.toJson());
      habits = _habitService.getHabitsLocal();
      _refreshSyncState();
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  HabitResponse? findHabitById(int id) {
    for (final habit in habits) {
      if (habit.id == id) {
        return habit;
      }
    }
    return null;
  }

  String? categoryNameForHabit(HabitResponse habit) {
    if (habit.habitCategoryId == null) {
      return null;
    }

    for (final category in categories) {
      if (category.id == habit.habitCategoryId) {
        return category.name;
      }
    }
    return null;
  }

  Future<void> completeHabit(int habitId) async {
    await _habitService.completeHabit(habitId);
    _completedToday.add(habitId);
    final current = _streaks[habitId] ?? 0;
    final updated = current + 1;
    _streaks[habitId] = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('habit_streak_$habitId', updated);
    } catch (_) {}
    await HabitNotificationHelper.cancelForHabit(userId: 1, habitId: habitId);
    await UserXpManager.addXp(120);
    _syncWidget();
    _refreshSyncState();
    notifyListeners();
  }

  Future<void> undoHabit(int habitId) async {
    await _habitService.undoHabit(habitId);
    _completedToday.remove(habitId);
    final current = _streaks[habitId] ?? 1;
    final updated = (current - 1).clamp(0, 999999);
    _streaks[habitId] = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('habit_streak_$habitId', updated);
    } catch (_) {}
    final habit = findHabitById(habitId);
    if (habit != null && habit.notificationsEnabled && habit.reminderTime != null) {
      await HabitNotificationHelper.scheduleIfEnabled(
        userId: 1,
        habitId: habit.id,
        name: habit.name,
        description: habit.description,
        hour: habit.reminderTime!.hour,
        minute: habit.reminderTime!.minute,
        notificationsEnabled: habit.notificationsEnabled,
        frequency: HabitFrequency.fromApiValue(habit.frequency),
        anchorDate: habit.startDate,
      );
    }
    await UserXpManager.deductXp(120);
    _syncWidget();
    _refreshSyncState();
    notifyListeners();
  }

  void _syncWidget() async {
    final active = todayHabits;
    final done = active.where((h) => isCompletedToday(h.id)).length;
    final sp = await SharedPreferences.getInstance();
    final houseKey = sp.getString('user_house_key') ?? 'stark';
    final workout = sp.getString('widget_workout_name') ?? 'Rest Day 🛡️';
    final nutrition = sp.getString('widget_calories_text') ?? 'Log Meals 🍎';
    final maxStreak = _streaks.values.fold<int>(0, (maxVal, v) => v > maxVal ? v : maxVal);
    WidgetService.updateWidgetData(
      houseKey: houseKey,
      completedQuests: done,
      totalQuests: active.length,
      streakDays: maxStreak,
      workoutName: workout,
      nutritionText: nutrition,
    );
  }

  Future<bool> deleteHabit(int id) async {
    try {
      await HabitNotificationHelper.cancelForHabit(userId: 1, habitId: id);
      await _habitService.deleteHabit(id);
      _completedToday.remove(id);
      habits = _habitService.getHabitsLocal();
      _refreshSyncState();
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
