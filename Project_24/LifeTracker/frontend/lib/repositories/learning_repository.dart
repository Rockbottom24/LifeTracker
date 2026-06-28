import '../local/offline_data_store.dart';
import '../local/stored_learning_session.dart';
import '../models/complete_learning_request.dart';
import '../models/learning_session_response.dart';
import '../sync/sync_operation.dart';
import '../sync/sync_status.dart';
import '../utils/local_key_generator.dart';

class LearningRepository {
  LearningRepository(this._store);

  final OfflineDataStore _store;

  List<LearningSessionResponse> getVisibleSessions() =>
      _store.getVisibleLearningSessions().map((item) => item.session).toList();

  Map<int, SyncStatus> getSyncStatusById() {
    final result = <int, SyncStatus>{};
    for (final item in _store.getVisibleLearningSessions()) {
      result[item.session.id] = item.syncStatus;
    }
    return result;
  }

  bool get hasPendingChanges => _store.hasPendingChanges;

  SyncStatus? syncStatusFor(int sessionId) => _store.syncStatusForLearningId(sessionId);

  StoredLearningSession? findStoredById(int id) => _store.findLearningById(id);

  Future<StoredLearningSession> createLocal(Map<String, dynamic> payload) async {
    final localKey = LocalKeyGenerator.nextKey('learning');
    final localId = _store.nextLocalId();
    final session = _sessionFromPayload(payload, id: localId, uuid: localKey);
    final stored = StoredLearningSession(
      localKey: localKey,
      session: session,
      syncStatus: SyncStatus.pendingCreate,
      updatedAt: DateTime.now(),
    );
    await _store.upsertStoredLearning(stored);
    await _store.enqueueLearningCreate(localKey, Map<String, dynamic>.from(payload));
    return stored;
  }

  Future<StoredLearningSession> updateLocal(int id, Map<String, dynamic> payload) async {
    final existing = _store.findLearningById(id);
    if (existing == null) {
      throw StateError('Learning session $id not found locally.');
    }

    final updatedSession = _applyUpdate(existing.session, payload);
    final status = existing.syncStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      await _replaceCreatePayload(existing.localKey, payload);
    } else {
      await _store.enqueueLearningUpdate(existing.localKey, id, Map<String, dynamic>.from(payload));
    }

    final stored = existing.copyWith(
      session: updatedSession,
      syncStatus: status,
      updatedAt: DateTime.now(),
    );
    await _store.upsertStoredLearning(stored);
    return stored;
  }

  Future<void> deleteLocal(int id) async {
    final existing = _store.findLearningById(id);
    if (existing == null) return;

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      await _store.removeStoredLearning(existing.localKey);
      await _store.removeQueueForLocalKey(existing.localKey);
      return;
    }

    await _store.removeStoredLearning(existing.localKey);
    if (id > 0) {
      await _store.enqueueLearningDelete(existing.localKey, id);
    }
  }

  Future<StoredLearningSession> startLocal(int id) async {
    final existing = _store.findLearningById(id);
    if (existing == null) {
      throw StateError('Learning session $id not found locally.');
    }

    final updated = existing.session.copyWithStatus('IN_PROGRESS');
    final status = existing.syncStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      await _replaceCreatePayload(existing.localKey, _payloadFromSession(updated));
    } else {
      await _store.enqueueLearningStart(existing.localKey, id);
    }

    final stored = existing.copyWith(
      session: updated,
      syncStatus: status,
      updatedAt: DateTime.now(),
    );
    await _store.upsertStoredLearning(stored);
    return stored;
  }

  Future<StoredLearningSession> completeLocal(int id, CompleteLearningRequest request) async {
    final existing = _store.findLearningById(id);
    if (existing == null) {
      throw StateError('Learning session $id not found locally.');
    }

    final updated = existing.session.copyWithCompletion(
      completedMinutes: request.completedMinutes,
      status: 'COMPLETED',
    );
    final status = existing.syncStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      await _replaceCreatePayload(existing.localKey, _payloadFromSession(updated));
    } else {
      await _store.enqueueLearningComplete(
        existing.localKey,
        id,
        request.toJson(),
      );
    }

    final stored = existing.copyWith(
      session: updated,
      syncStatus: status,
      updatedAt: DateTime.now(),
    );
    await _store.upsertStoredLearning(stored);
    return stored;
  }

  Future<void> mergeRemoteSessions(List<LearningSessionResponse> remoteSessions) async {
    final localItems = _store.getStoredLearningSessions();
    final byUuid = {for (final item in localItems) item.session.uuid: item};
    final byId = {for (final item in localItems) item.session.id: item};
    final merged = <StoredLearningSession>[];

    for (final remote in remoteSessions) {
      final local = (remote.uuid.isNotEmpty ? byUuid[remote.uuid] : null) ?? byId[remote.id];
      if (local == null) {
        merged.add(
          StoredLearningSession(
            localKey: remote.uuid.isNotEmpty ? remote.uuid : 'learning-${remote.id}',
            session: remote,
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
            session: remote,
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

    await _store.saveStoredLearningSessions(merged);
  }

  Future<void> markSynced(String localKey, LearningSessionResponse session) async {
    final existing = _store.findLearningByLocalKey(localKey);
    if (existing == null) return;
    await _store.upsertStoredLearning(
      existing.copyWith(
        session: session,
        syncStatus: SyncStatus.synced,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> _payloadFromSession(LearningSessionResponse session) {
    return {
      'title': session.title,
      'description': session.description,
      'topic': session.topic,
      'plannedMinutes': session.plannedMinutes,
      'status': session.status,
      'priority': session.priority,
      'scheduledDate': session.scheduledDate?.toIso8601String().split('T').first,
      'reminderTime': session.reminderTime == null
          ? null
          : '${session.reminderTime!.hour.toString().padLeft(2, '0')}:${session.reminderTime!.minute.toString().padLeft(2, '0')}:00',
      'notificationsEnabled': session.notificationsEnabled,
      'colorHex': session.colorHex,
      'iconName': session.iconName,
    };
  }

  Future<void> _replaceCreatePayload(String localKey, Map<String, dynamic> payload) async {
    final queue = _store.getSyncQueue();
    final updated = queue.map((operation) {
      if (operation.localKey != localKey || operation.type != SyncOperationType.learningCreate) {
        return operation;
      }
      return operation.copyWith(payload: Map<String, dynamic>.from(payload));
    }).toList();
    await _store.saveSyncQueue(updated);
  }

  LearningSessionResponse _sessionFromPayload(
    Map<String, dynamic> payload, {
    required int id,
    required String uuid,
  }) {
    return LearningSessionResponse(
      id: id,
      uuid: uuid,
      title: payload['title'] as String? ?? '',
      description: payload['description'] as String?,
      topic: payload['topic'] as String?,
      plannedMinutes: _toInt(payload['plannedMinutes']) ?? 0,
      completedMinutes: 0,
      status: payload['status']?.toString() ?? 'PLANNED',
      priority: payload['priority']?.toString() ?? 'MEDIUM',
      scheduledDate: _parseOptionalDate(payload['scheduledDate']),
      reminderTime: _parsePayloadTime(payload['reminderTime']),
      notificationsEnabled: payload['notificationsEnabled'] as bool? ?? false,
      colorHex: payload['colorHex'] as String?,
      iconName: payload['iconName'] as String?,
    );
  }

  LearningSessionResponse _applyUpdate(LearningSessionResponse session, Map<String, dynamic> payload) {
    return LearningSessionResponse(
      id: session.id,
      uuid: session.uuid,
      title: payload['title'] as String? ?? session.title,
      description: payload['description'] as String? ?? session.description,
      topic: payload['topic'] as String? ?? session.topic,
      resourceType: session.resourceType,
      resourceUrl: session.resourceUrl,
      plannedMinutes: _toInt(payload['plannedMinutes']) ?? session.plannedMinutes,
      completedMinutes: session.completedMinutes,
      status: payload['status']?.toString() ?? session.status,
      priority: payload['priority']?.toString() ?? session.priority,
      scheduledDate: payload.containsKey('scheduledDate')
          ? _parseOptionalDate(payload['scheduledDate'])
          : session.scheduledDate,
      completedDate: session.completedDate,
      reminderTime: payload.containsKey('reminderTime')
          ? _parsePayloadTime(payload['reminderTime'])
          : session.reminderTime,
      notificationsEnabled: payload['notificationsEnabled'] as bool? ?? session.notificationsEnabled,
      colorHex: payload['colorHex'] as String? ?? session.colorHex,
      iconName: payload['iconName'] as String? ?? session.iconName,
      displayOrder: session.displayOrder,
    );
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

extension _LearningSessionCopy on LearningSessionResponse {
  LearningSessionResponse copyWithStatus(String status) {
    return LearningSessionResponse(
      id: id,
      uuid: uuid,
      title: title,
      description: description,
      topic: topic,
      resourceType: resourceType,
      resourceUrl: resourceUrl,
      plannedMinutes: plannedMinutes,
      completedMinutes: completedMinutes,
      status: status,
      priority: priority,
      scheduledDate: scheduledDate,
      completedDate: completedDate,
      reminderTime: reminderTime,
      notificationsEnabled: notificationsEnabled,
      colorHex: colorHex,
      iconName: iconName,
      displayOrder: displayOrder,
    );
  }

  LearningSessionResponse copyWithCompletion({
    required int completedMinutes,
    required String status,
  }) {
    return LearningSessionResponse(
      id: id,
      uuid: uuid,
      title: title,
      description: description,
      topic: topic,
      resourceType: resourceType,
      resourceUrl: resourceUrl,
      plannedMinutes: plannedMinutes,
      completedMinutes: completedMinutes,
      status: status,
      priority: priority,
      scheduledDate: scheduledDate,
      completedDate: DateTime.now(),
      reminderTime: reminderTime,
      notificationsEnabled: notificationsEnabled,
      colorHex: colorHex,
      iconName: iconName,
      displayOrder: displayOrder,
    );
  }
}
