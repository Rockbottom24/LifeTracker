import '../local/offline_data_store.dart';
import '../local/stored_habit.dart';
import '../models/habit_response.dart';
import '../sync/sync_operation.dart';
import '../sync/sync_status.dart';
import '../utils/local_key_generator.dart';

class HabitRepository {
  HabitRepository(this._store);

  final OfflineDataStore _store;

  List<HabitResponse> getVisibleHabits() =>
      _store.getVisibleHabits().map((item) => item.habit).toList();

  Map<int, SyncStatus> getSyncStatusById() {
    final result = <int, SyncStatus>{};
    for (final item in _store.getVisibleHabits()) {
      result[item.habit.id] = item.syncStatus;
    }
    return result;
  }

  bool get hasPendingChanges => _store.hasPendingChanges;

  SyncStatus? syncStatusFor(int habitId) => _store.syncStatusForHabitId(habitId);

  StoredHabit? findStoredById(int id) => _store.findHabitById(id);

  Future<StoredHabit> createLocal(Map<String, dynamic> payload) async {
    final localKey = LocalKeyGenerator.nextKey('habit');
    final localId = _store.nextLocalId();
    final habit = _habitFromPayload(payload, id: localId, uuid: localKey);
    final stored = StoredHabit(
      localKey: localKey,
      habit: habit,
      syncStatus: SyncStatus.pendingCreate,
      updatedAt: DateTime.now(),
    );
    await _store.upsertStoredHabit(stored);
    await _store.enqueueHabitCreate(localKey, Map<String, dynamic>.from(payload));
    return stored;
  }

  Future<StoredHabit> updateLocal(int id, Map<String, dynamic> payload) async {
    final existing = _store.findHabitById(id);
    if (existing == null) {
      throw StateError('Habit $id not found locally.');
    }

    final updatedHabit = _applyUpdate(existing.habit, payload);
    final status = existing.syncStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      await _replaceCreatePayload(existing.localKey, payload);
    } else {
      await _store.enqueueHabitUpdate(existing.localKey, id, Map<String, dynamic>.from(payload));
    }

    final stored = existing.copyWith(
      habit: updatedHabit,
      syncStatus: status,
      updatedAt: DateTime.now(),
    );
    await _store.upsertStoredHabit(stored);
    return stored;
  }

  Future<void> deleteLocal(int id) async {
    final existing = _store.findHabitById(id);
    if (existing == null) return;

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      await _store.removeStoredHabit(existing.localKey);
      await _store.removeQueueForLocalKey(existing.localKey);
      return;
    }

    await _store.removeStoredHabit(existing.localKey);
    if (id > 0) {
      await _store.enqueueHabitDelete(existing.localKey, id);
    }
  }

  Future<void> completeLocal(int habitId, {double value = 1.0, String? notes}) async {
    await _store.enqueueHabitComplete(
      habitId,
      {
        'habitId': habitId,
        'value': value,
        'notes': ?notes,
      },
    );
  }

  Future<void> undoLocal(int habitId) async {
    await _store.enqueueHabitUndo(habitId);
  }

  Future<void> mergeRemoteHabits(List<HabitResponse> remoteHabits) async {
    final localItems = _store.getStoredHabits();
    final byUuid = {for (final item in localItems) item.habit.uuid: item};
    final byId = {for (final item in localItems) item.habit.id: item};
    final merged = <StoredHabit>[];

    for (final remote in remoteHabits) {
      final local = (remote.uuid.isNotEmpty ? byUuid[remote.uuid] : null) ?? byId[remote.id];
      if (local == null) {
        merged.add(
          StoredHabit(
            localKey: remote.uuid.isNotEmpty ? remote.uuid : 'habit-${remote.id}',
            habit: remote,
            syncStatus: SyncStatus.synced,
            updatedAt: DateTime.now(),
          ),
        );
        continue;
      }

      if (local.syncStatus.isPending) {
        merged.add(local);
      } else {
        merged.add(
          local.copyWith(
            habit: remote,
            syncStatus: SyncStatus.synced,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    for (final local in localItems) {
      if (local.syncStatus.isPending && !merged.any((item) => item.localKey == local.localKey)) {
        merged.insert(0, local);
      }
    }

    await _store.saveStoredHabits(merged);
  }

  Future<void> markSynced(String localKey, HabitResponse habit) async {
    final existing = _store.findHabitByLocalKey(localKey);
    if (existing == null) return;
    await _store.upsertStoredHabit(
      existing.copyWith(
        habit: habit,
        syncStatus: SyncStatus.synced,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _replaceCreatePayload(String localKey, Map<String, dynamic> payload) async {
    final queue = _store.getSyncQueue();
    final updated = queue.map((operation) {
      if (operation.localKey != localKey || operation.type != SyncOperationType.habitCreate) {
        return operation;
      }
      return operation.copyWith(payload: Map<String, dynamic>.from(payload));
    }).toList();
    await _store.saveSyncQueue(updated);
  }

  HabitResponse _habitFromPayload(
    Map<String, dynamic> payload, {
    required int id,
    required String uuid,
  }) {
    return HabitResponse(
      id: id,
      uuid: uuid,
      name: payload['name'] as String? ?? '',
      description: payload['description'] as String?,
      frequency: payload['frequency']?.toString() ?? 'DAILY',
      startDate: _parsePayloadDate(payload['startDate']),
      endDate: _parseOptionalDate(payload['endDate']),
      reminderTime: _parsePayloadTime(payload['reminderTime']),
      notificationsEnabled: payload['notificationsEnabled'] as bool? ?? false,
      iconName: payload['iconName'] as String?,
      colorHex: payload['colorHex'] as String?,
      isActive: true,
      habitCategoryId: _toInt(payload['habitCategoryId']),
    );
  }

  HabitResponse _applyUpdate(HabitResponse habit, Map<String, dynamic> payload) {
    return HabitResponse(
      id: habit.id,
      uuid: habit.uuid,
      name: payload['name'] as String? ?? habit.name,
      description: payload['description'] as String? ?? habit.description,
      frequency: payload['frequency']?.toString() ?? habit.frequency,
      startDate: payload.containsKey('startDate')
          ? _parsePayloadDate(payload['startDate'])
          : habit.startDate,
      endDate: payload.containsKey('endDate')
          ? _parseOptionalDate(payload['endDate'])
          : habit.endDate,
      reminderTime: payload.containsKey('reminderTime')
          ? _parsePayloadTime(payload['reminderTime'])
          : habit.reminderTime,
      notificationsEnabled: payload['notificationsEnabled'] as bool? ?? habit.notificationsEnabled,
      iconName: payload['iconName'] as String? ?? habit.iconName,
      colorHex: payload['colorHex'] as String? ?? habit.colorHex,
      isActive: habit.isActive,
      habitCategoryId: _toInt(payload['habitCategoryId']) ?? habit.habitCategoryId,
    );
  }

  DateTime _parsePayloadDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DateTime? _parsePayloadTime(dynamic value) {
    if (value == null) return null;
    final parts = value.toString().split(':');
    if (parts.length >= 2) {
      return DateTime(
        1970,
        1,
        1,
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
      );
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
