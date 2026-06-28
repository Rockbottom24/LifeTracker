import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/dashboard_response.dart';
import '../models/habit_category_response.dart';
import '../models/habit_response.dart';
import '../models/learning_session_response.dart';
import '../utils/app_logger.dart';

enum CacheEntity {
  habits,
  habitCategories,
  learningSessions,
  dashboard,
}

class LocalCacheStore {
  LocalCacheStore._();

  static final LocalCacheStore instance = LocalCacheStore._();

  static const _boxName = 'life_tracker_cache';

  static const _habitsKey = 'habits';
  static const _categoriesKey = 'habit_categories';
  static const _learningKey = 'learning_sessions';
  static const _dashboardKey = 'dashboard';
  static const _completedTodayKey = 'completed_today_habits';

  Box<String>? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    AppLogger.debug('LocalCacheStore initialized');
  }

  Box<String> get box {
    final current = _box;
    if (current == null || !current.isOpen) {
      throw StateError('LocalCacheStore.init() must be called before use.');
    }
    return current;
  }

  // --- Habits ---

  List<HabitResponse> getHabits() => _readList(_habitsKey, HabitResponse.fromJson);

  Future<void> saveHabits(List<HabitResponse> habits) async {
    await _writeList(_habitsKey, habits, (item) => item.toJson(), CacheEntity.habits);
  }

  Future<void> upsertHabit(HabitResponse habit) async {
    final habits = getHabits().where((item) => item.id != habit.id).toList();
    habits.insert(0, habit);
    await saveHabits(habits);
  }

  Future<void> removeHabit(int habitId) async {
    final habits = getHabits().where((item) => item.id != habitId).toList();
    await saveHabits(habits);
    await removeCompletedToday(habitId);
  }

  // --- Habit categories ---

  List<HabitCategoryResponse> getHabitCategories() =>
      _readList(_categoriesKey, HabitCategoryResponse.fromJson);

  Future<void> saveHabitCategories(List<HabitCategoryResponse> categories) async {
    await _writeList(_categoriesKey, categories, (item) => item.toJson(), CacheEntity.habitCategories);
  }

  // --- Learning sessions ---

  List<LearningSessionResponse> getLearningSessions() =>
      _readList(_learningKey, LearningSessionResponse.fromJson);

  Future<void> saveLearningSessions(List<LearningSessionResponse> sessions) async {
    await _writeList(_learningKey, sessions, (item) => item.toJson(), CacheEntity.learningSessions);
  }

  Future<void> upsertLearningSession(LearningSessionResponse session) async {
    final sessions = getLearningSessions().where((item) => item.id != session.id).toList();
    sessions.insert(0, session);
    await saveLearningSessions(sessions);
  }

  Future<void> removeLearningSession(int sessionId) async {
    final sessions = getLearningSessions().where((item) => item.id != sessionId).toList();
    await saveLearningSessions(sessions);
  }

  // --- Dashboard ---

  DashboardResponse? getDashboard() {
    final raw = box.get(_dashboardKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DashboardResponse.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      AppLogger.debug('Failed to read cached dashboard: $error');
      return null;
    }
  }

  Future<void> saveDashboard(DashboardResponse dashboard) async {
    await box.put(_dashboardKey, jsonEncode(dashboard.toJson()));
    await _setLastSynced(CacheEntity.dashboard);
  }

  // --- Completed today ---

  Set<int> getCompletedTodayHabitIds() {
    final raw = box.get(_completedTodayKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => (item as num).toInt()).toSet();
    } catch (error) {
      AppLogger.debug('Failed to read completed today cache: $error');
      return {};
    }
  }

  Future<void> saveCompletedTodayHabitIds(Set<int> habitIds) async {
    await box.put(_completedTodayKey, jsonEncode(habitIds.toList()));
  }

  Future<void> addCompletedToday(int habitId) async {
    final ids = getCompletedTodayHabitIds()..add(habitId);
    await saveCompletedTodayHabitIds(ids);
  }

  Future<void> removeCompletedToday(int habitId) async {
    final ids = getCompletedTodayHabitIds()..remove(habitId);
    await saveCompletedTodayHabitIds(ids);
  }

  // --- Sync metadata ---

  DateTime? getLastSynced(CacheEntity entity) {
    final raw = box.get(_lastSyncedKey(entity));
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _setLastSynced(CacheEntity entity) async {
    await box.put(_lastSyncedKey(entity), DateTime.now().toIso8601String());
  }

  String _lastSyncedKey(CacheEntity entity) => 'last_synced_${entity.name}';

  List<T> _readList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final raw = box.get(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (error) {
      AppLogger.debug('Failed to read cached list for $key: $error');
      return [];
    }
  }

  Future<void> _writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T item) toJson,
    CacheEntity entity,
  ) async {
    await box.put(key, jsonEncode(items.map(toJson).toList()));
    await _setLastSynced(entity);
  }
}
