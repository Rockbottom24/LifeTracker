import 'package:flutter/foundation.dart';

import '../local/local_cache_store.dart';
import '../models/create_habit_request.dart';
import '../models/habit_category_response.dart';
import '../models/habit_response.dart';
import '../models/update_habit_request.dart';
import '../services/api_client.dart';
import '../services/habit_service.dart';
import '../sync/sync_status.dart';

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
    _refreshSyncState();
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
    _refreshSyncState();
    notifyListeners();

    try {
      await _habitService.syncWithServer();
      habits = _habitService.getHabitsLocal();
      _completedToday
        ..clear()
        ..addAll(_cache.getCompletedTodayHabitIds());
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
    final hadCachedData = categories.isNotEmpty;
    isLoadingCategories = !hadCachedData;
    if (!hadCachedData) {
      categoriesErrorMessage = null;
    }
    notifyListeners();

    try {
      categories = await _habitService.getCategories();
      categoriesErrorMessage = null;
    } on ApiException catch (e) {
      if (categories.isEmpty) {
        categories = _cache.getHabitCategories();
      }
      categoriesErrorMessage = categories.isEmpty ? e.message : null;
    } catch (e) {
      if (categories.isEmpty) {
        categories = _cache.getHabitCategories();
      }
      categoriesErrorMessage = categories.isEmpty ? e.toString() : null;
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
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
    _refreshSyncState();
    notifyListeners();
  }

  Future<void> undoHabit(int habitId) async {
    await _habitService.undoHabit(habitId);
    _completedToday.remove(habitId);
    _refreshSyncState();
    notifyListeners();
  }

  Future<bool> deleteHabit(int id) async {
    try {
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
