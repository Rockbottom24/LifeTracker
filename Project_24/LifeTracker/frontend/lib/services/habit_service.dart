import 'dart:async';

import '../local/local_cache_store.dart';
import '../models/habit_category_response.dart';
import '../models/habit_log_response.dart';
import '../models/habit_response.dart';
import '../repositories/habit_repository.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_status.dart';
import 'api_client.dart';

class HabitService {
  HabitService({
    required this._apiClient,
    required this._cache,
    required this._repository,
    required this._syncEngine,
  });

  final ApiClient _apiClient;
  final LocalCacheStore _cache;
  final HabitRepository _repository;
  final SyncEngine _syncEngine;

  List<HabitResponse> getHabitsLocal() => _repository.getVisibleHabits();

  bool get hasPendingSync => _offlineStoreHasPending();

  bool _offlineStoreHasPending() => _syncEngine.hasPendingChanges;

  SyncStatus? syncStatusFor(int habitId) => _repository.syncStatusFor(habitId);

  Future<void> syncWithServer() async {
    await _syncEngine.syncAll();
  }

  Future<List<HabitCategoryResponse>> getCategories() async {
    try {
      final categories = await _apiClient.get<List<HabitCategoryResponse>>(
        '/habit-categories',
        parser: (data) {
          final items = data as List<dynamic>;
          return items
              .map((item) => HabitCategoryResponse.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        },
      );
      await _cache.saveHabitCategories(categories);
      return categories;
    } on ApiException {
      return _cache.getHabitCategories();
    }
  }

  Future<List<HabitResponse>> getHabits() async {
    unawaited(_syncEngine.syncAll());
    return getHabitsLocal();
  }

  Future<HabitResponse> getHabit(int id) async {
    final stored = _repository.findStoredById(id);
    if (stored != null) return stored.habit;

    try {
      final habit = await _apiClient.get<HabitResponse>(
        '/habits/$id',
        parser: (data) => HabitResponse.fromJson(Map<String, dynamic>.from(data as Map)),
      );
      await _cache.upsertHabit(habit);
      return habit;
    } on ApiException {
      final local = _repository.findStoredById(id);
      if (local != null) return local.habit;
      rethrow;
    }
  }

  Future<HabitResponse> updateHabit(int id, Map<String, dynamic> payload) async {
    final stored = await _repository.updateLocal(id, payload);
    unawaited(_syncEngine.syncAll());
    return stored.habit;
  }

  Future<HabitResponse> createHabit(Map<String, dynamic> payload) async {
    final stored = await _repository.createLocal(payload);
    unawaited(_syncEngine.syncAll());
    return stored.habit;
  }

  Future<HabitLogResponse> completeHabit(int habitId, {double value = 1.0, String? notes}) async {
    await _cache.addCompletedToday(habitId);
    await _repository.completeLocal(habitId, value: value, notes: notes);
    unawaited(_syncEngine.syncAll());
    return HabitLogResponse(habitId: habitId, completed: true);
  }

  Future<HabitLogResponse> undoHabit(int habitId) async {
    await _cache.removeCompletedToday(habitId);
    await _repository.undoLocal(habitId);
    unawaited(_syncEngine.syncAll());
    return HabitLogResponse(habitId: habitId, completed: false);
  }

  Future<void> deleteHabit(int id) async {
    await _cache.removeCompletedToday(id);
    await _repository.deleteLocal(id);
    unawaited(_syncEngine.syncAll());
  }
}
