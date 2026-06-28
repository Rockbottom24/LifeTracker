import 'dart:convert';

import '../models/habit_response.dart';
import '../models/learning_session_response.dart';
import '../sync/sync_operation.dart';
import '../sync/sync_status.dart';
import '../utils/local_key_generator.dart';
import '../utils/app_logger.dart';
import 'local_cache_store.dart';
import 'stored_habit.dart';
import 'stored_learning_session.dart';

class OfflineDataStore {
  OfflineDataStore(this._cache);

  final LocalCacheStore _cache;

  static const _storedHabitsKey = 'stored_habits';
  static const _storedLearningKey = 'stored_learning';
  static const _syncQueueKey = 'sync_queue';
  static const _localIdCounterKey = 'local_id_counter';
  static const _migrationKey = 'offline_migration_v1';

  Future<void> ensureMigrated() async {
    if (_cache.box.get(_migrationKey) == 'done') return;

    final legacyHabits = _cache.getHabits();
    if (legacyHabits.isNotEmpty && getStoredHabits().isEmpty) {
      final stored = legacyHabits
          .map(
            (habit) => StoredHabit(
              localKey: habit.uuid.isNotEmpty ? habit.uuid : 'habit-${habit.id}',
              habit: habit,
              syncStatus: SyncStatus.synced,
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
      await saveStoredHabits(stored);
    }

    final legacyLearning = _cache.getLearningSessions();
    if (legacyLearning.isNotEmpty && getStoredLearningSessions().isEmpty) {
      final stored = legacyLearning
          .map(
            (session) => StoredLearningSession(
              localKey: session.uuid.isNotEmpty ? session.uuid : 'learning-${session.id}',
              session: session,
              syncStatus: SyncStatus.synced,
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
      await saveStoredLearningSessions(stored);
    }

    await _cache.box.put(_migrationKey, 'done');
  }

  int nextLocalId() {
    final current = int.tryParse(_cache.box.get(_localIdCounterKey) ?? '') ?? 0;
    final next = current == 0 ? -1 : current - 1;
    _cache.box.put(_localIdCounterKey, next.toString());
    return next;
  }

  List<StoredHabit> getStoredHabits() => _readList(_storedHabitsKey, StoredHabit.fromJson);

  List<StoredHabit> getVisibleHabits() =>
      getStoredHabits().where((item) => item.syncStatus != SyncStatus.pendingDelete).toList();

  Future<void> saveStoredHabits(List<StoredHabit> habits) async {
    await _writeList(_storedHabitsKey, habits, (item) => item.toJson(), CacheEntity.habits);
    await _mirrorLegacyHabits(habits);
  }

  StoredHabit? findHabitByLocalKey(String localKey) {
    for (final item in getStoredHabits()) {
      if (item.localKey == localKey) return item;
    }
    return null;
  }

  StoredHabit? findHabitById(int id) {
    for (final item in getStoredHabits()) {
      if (item.habit.id == id) return item;
    }
    return null;
  }

  StoredHabit? findHabitByUuid(String uuid) {
    if (uuid.isEmpty) return null;
    for (final item in getStoredHabits()) {
      if (item.habit.uuid == uuid) return item;
    }
    return null;
  }

  Future<StoredHabit> upsertStoredHabit(StoredHabit stored) async {
    final habits = getStoredHabits()
        .where((item) => item.localKey != stored.localKey && item.habit.id != stored.habit.id)
        .toList();
    habits.insert(0, stored);
    await saveStoredHabits(habits);
    return stored;
  }

  Future<void> removeStoredHabit(String localKey) async {
    final habits = getStoredHabits().where((item) => item.localKey != localKey).toList();
    await saveStoredHabits(habits);
  }

  Future<void> remapHabitId(int oldId, int newId, String uuid) async {
    final habits = getStoredHabits().map((item) {
      if (item.habit.id != oldId) return item;
      return item.copyWith(
        habit: HabitResponse(
          id: newId,
          uuid: uuid.isNotEmpty ? uuid : item.habit.uuid,
          name: item.habit.name,
          description: item.habit.description,
          frequency: item.habit.frequency,
          startDate: item.habit.startDate,
          endDate: item.habit.endDate,
          reminderTime: item.habit.reminderTime,
          notificationsEnabled: item.habit.notificationsEnabled,
          iconName: item.habit.iconName,
          colorHex: item.habit.colorHex,
          isActive: item.habit.isActive,
          habitCategoryId: item.habit.habitCategoryId,
        ),
      );
    }).toList();
    await saveStoredHabits(habits);

    final completed = _cache.getCompletedTodayHabitIds();
    if (completed.remove(oldId)) {
      completed.add(newId);
      await _cache.saveCompletedTodayHabitIds(completed);
    }

    final queue = getSyncQueue().map((operation) {
      if (operation.entityId != oldId) return operation;
      return operation.copyWith(entityId: newId);
    }).toList();
    await saveSyncQueue(queue);
  }

  List<StoredLearningSession> getStoredLearningSessions() =>
      _readList(_storedLearningKey, StoredLearningSession.fromJson);

  List<StoredLearningSession> getVisibleLearningSessions() => getStoredLearningSessions()
      .where((item) => item.syncStatus != SyncStatus.pendingDelete)
      .toList();

  Future<void> saveStoredLearningSessions(List<StoredLearningSession> sessions) async {
    await _writeList(_storedLearningKey, sessions, (item) => item.toJson(), CacheEntity.learningSessions);
    await _mirrorLegacyLearning(sessions);
  }

  StoredLearningSession? findLearningByLocalKey(String localKey) {
    for (final item in getStoredLearningSessions()) {
      if (item.localKey == localKey) return item;
    }
    return null;
  }

  StoredLearningSession? findLearningById(int id) {
    for (final item in getStoredLearningSessions()) {
      if (item.session.id == id) return item;
    }
    return null;
  }

  StoredLearningSession? findLearningByUuid(String uuid) {
    if (uuid.isEmpty) return null;
    for (final item in getStoredLearningSessions()) {
      if (item.session.uuid == uuid) return item;
    }
    return null;
  }

  Future<StoredLearningSession> upsertStoredLearning(StoredLearningSession stored) async {
    final sessions = getStoredLearningSessions()
        .where((item) => item.localKey != stored.localKey && item.session.id != stored.session.id)
        .toList();
    sessions.insert(0, stored);
    await saveStoredLearningSessions(sessions);
    return stored;
  }

  Future<void> removeStoredLearning(String localKey) async {
    final sessions = getStoredLearningSessions().where((item) => item.localKey != localKey).toList();
    await saveStoredLearningSessions(sessions);
  }

  Future<void> remapLearningId(int oldId, int newId, String uuid) async {
    final sessions = getStoredLearningSessions().map((item) {
      if (item.session.id != oldId) return item;
      return item.copyWith(
        session: LearningSessionResponse(
          id: newId,
          uuid: uuid.isNotEmpty ? uuid : item.session.uuid,
          title: item.session.title,
          description: item.session.description,
          topic: item.session.topic,
          resourceType: item.session.resourceType,
          resourceUrl: item.session.resourceUrl,
          plannedMinutes: item.session.plannedMinutes,
          completedMinutes: item.session.completedMinutes,
          status: item.session.status,
          priority: item.session.priority,
          scheduledDate: item.session.scheduledDate,
          completedDate: item.session.completedDate,
          reminderTime: item.session.reminderTime,
          notificationsEnabled: item.session.notificationsEnabled,
          colorHex: item.session.colorHex,
          iconName: item.session.iconName,
          displayOrder: item.session.displayOrder,
        ),
      );
    }).toList();
    await saveStoredLearningSessions(sessions);

    final queue = getSyncQueue().map((operation) {
      if (operation.entityId != oldId) return operation;
      return operation.copyWith(entityId: newId);
    }).toList();
    await saveSyncQueue(queue);
  }

  List<SyncOperation> getSyncQueue() => _readList(_syncQueueKey, SyncOperation.fromJson);

  Future<void> saveSyncQueue(List<SyncOperation> operations) async {
    await _cache.box.put(_syncQueueKey, jsonEncode(operations.map((item) => item.toJson()).toList()));
  }

  Future<void> enqueue(SyncOperation operation) async {
    final queue = getSyncQueue()..add(operation);
    await saveSyncQueue(queue);
  }

  Future<void> removeFromQueue(String operationId) async {
    final queue = getSyncQueue().where((item) => item.id != operationId).toList();
    await saveSyncQueue(queue);
  }

  Future<void> updateQueueOperation(SyncOperation operation) async {
    final queue = getSyncQueue().map((item) => item.id == operation.id ? operation : item).toList();
    await saveSyncQueue(queue);
  }

  Future<void> removeQueueForLocalKey(String localKey) async {
    final queue = getSyncQueue().where((item) => item.localKey != localKey).toList();
    await saveSyncQueue(queue);
  }

  Future<SyncOperation> enqueueHabitCreate(String localKey, Map<String, dynamic> payload) {
    return _enqueue(
      SyncOperationType.habitCreate,
      localKey: localKey,
      entityId: payload['id'] as int?,
      payload: payload,
    );
  }

  Future<SyncOperation> enqueueHabitUpdate(String localKey, int entityId, Map<String, dynamic> payload) {
    return _enqueue(
      SyncOperationType.habitUpdate,
      localKey: localKey,
      entityId: entityId,
      payload: payload,
    );
  }

  Future<SyncOperation> enqueueHabitDelete(String localKey, int entityId) {
    return _enqueue(
      SyncOperationType.habitDelete,
      localKey: localKey,
      entityId: entityId,
      payload: const {},
    );
  }

  Future<SyncOperation> enqueueHabitComplete(int entityId, Map<String, dynamic> payload) {
    return _enqueue(
      SyncOperationType.habitComplete,
      localKey: 'complete-$entityId-${DateTime.now().millisecondsSinceEpoch}',
      entityId: entityId,
      payload: payload,
    );
  }

  Future<SyncOperation> enqueueHabitUndo(int entityId) {
    return _enqueue(
      SyncOperationType.habitUndo,
      localKey: 'undo-$entityId-${DateTime.now().millisecondsSinceEpoch}',
      entityId: entityId,
      payload: const {},
    );
  }

  Future<SyncOperation> enqueueLearningCreate(String localKey, Map<String, dynamic> payload) {
    return _enqueue(
      SyncOperationType.learningCreate,
      localKey: localKey,
      entityId: payload['id'] as int?,
      payload: payload,
    );
  }

  Future<SyncOperation> enqueueLearningUpdate(String localKey, int entityId, Map<String, dynamic> payload) {
    return _enqueue(
      SyncOperationType.learningUpdate,
      localKey: localKey,
      entityId: entityId,
      payload: payload,
    );
  }

  Future<SyncOperation> enqueueLearningDelete(String localKey, int entityId) {
    return _enqueue(
      SyncOperationType.learningDelete,
      localKey: localKey,
      entityId: entityId,
      payload: const {},
    );
  }

  Future<SyncOperation> enqueueLearningStart(String localKey, int entityId) {
    return _enqueue(
      SyncOperationType.learningStart,
      localKey: localKey,
      entityId: entityId,
      payload: const {},
    );
  }

  Future<SyncOperation> enqueueLearningComplete(String localKey, int entityId, Map<String, dynamic> payload) {
    return _enqueue(
      SyncOperationType.learningComplete,
      localKey: localKey,
      entityId: entityId,
      payload: payload,
    );
  }

  Future<SyncOperation> _enqueue(
    SyncOperationType type, {
    required String localKey,
    int? entityId,
    required Map<String, dynamic> payload,
  }) async {
    final operation = SyncOperation(
      id: LocalKeyGenerator.nextKey('op'),
      type: type,
      localKey: localKey,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
      status: SyncStatus.pendingCreate,
    );
    await enqueue(operation);
    return operation;
  }

  bool get hasPendingChanges {
    final habitPending = getStoredHabits().any((item) => item.syncStatus.isPending);
    final learningPending = getStoredLearningSessions().any((item) => item.syncStatus.isPending);
    return habitPending || learningPending || getSyncQueue().isNotEmpty;
  }

  SyncStatus? syncStatusForHabitId(int id) => findHabitById(id)?.syncStatus;

  SyncStatus? syncStatusForLearningId(int id) => findLearningById(id)?.syncStatus;

  Future<void> _mirrorLegacyHabits(List<StoredHabit> habits) async {
    await _cache.saveHabits(
      habits
          .where((item) => item.syncStatus != SyncStatus.pendingDelete)
          .map((item) => item.habit)
          .toList(),
    );
  }

  Future<void> _mirrorLegacyLearning(List<StoredLearningSession> sessions) async {
    await _cache.saveLearningSessions(
      sessions
          .where((item) => item.syncStatus != SyncStatus.pendingDelete)
          .map((item) => item.session)
          .toList(),
    );
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final raw = _cache.box.get(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (error) {
      AppLogger.debug('Failed to read offline list for $key: $error');
      return [];
    }
  }

  Future<void> _writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T item) toJson,
    CacheEntity entity,
  ) async {
    await _cache.box.put(key, jsonEncode(items.map(toJson).toList()));
    await _cache.box.put('last_synced_${entity.name}', DateTime.now().toIso8601String());
  }
}
