import '../local/local_cache_store.dart';
import '../local/offline_data_store.dart';
import '../models/dashboard_response.dart';
import '../models/habit_log_response.dart';
import '../models/habit_response.dart';
import '../models/learning_session_response.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/habit_repository.dart';
import '../repositories/learning_repository.dart';
import '../services/api_client.dart';
import '../utils/app_logger.dart';
import '../sync/sync_operation.dart';
import '../sync/sync_status.dart';

class SyncResult {
  const SyncResult({required this.success, this.offline = false});

  final bool success;
  final bool offline;

  static const successResult = SyncResult(success: true);
  static const offlineResult = SyncResult(success: false, offline: true);
  static const failedResult = SyncResult(success: false);
}

class SyncEngine {
  SyncEngine({
    required this._apiClient,
    required this._offlineStore,
    required this._habitRepository,
    required this._learningRepository,
    required this._dashboardRepository,
    required this._cache,
  });

  final ApiClient _apiClient;
  final OfflineDataStore _offlineStore;
  final HabitRepository _habitRepository;
  final LearningRepository _learningRepository;
  final DashboardRepository _dashboardRepository;
  final LocalCacheStore _cache;

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  bool get hasPendingChanges => _offlineStore.hasPendingChanges;

  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult.successResult;
    _isSyncing = true;

    try {
      await _pushQueue();
      await _pullRemoteData();
      await _dashboardRepository.saveLocalSnapshot();
      return SyncResult.successResult;
    } on ApiException catch (error) {
      AppLogger.debug('Sync paused (API): ${error.message}');
      await _dashboardRepository.saveLocalSnapshot();
      return SyncResult.offlineResult;
    } catch (error) {
      AppLogger.debug('Sync paused: $error');
      await _dashboardRepository.saveLocalSnapshot();
      return SyncResult.failedResult;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushQueue() async {
    final queue = List<SyncOperation>.from(_offlineStore.getSyncQueue());
    for (final operation in queue) {
      final processed = await _processOperation(operation);
      if (!processed) {
        await _offlineStore.updateQueueOperation(
          operation.copyWith(status: SyncStatus.failed),
        );
      }
    }
  }

  Future<bool> _processOperation(SyncOperation operation) async {
    try {
      switch (operation.type) {
        case SyncOperationType.habitCreate:
          return _syncHabitCreate(operation);
        case SyncOperationType.habitUpdate:
          return _syncHabitUpdate(operation);
        case SyncOperationType.habitDelete:
          return _syncHabitDelete(operation);
        case SyncOperationType.habitComplete:
          return _syncHabitComplete(operation);
        case SyncOperationType.habitUndo:
          return _syncHabitUndo(operation);
        case SyncOperationType.learningCreate:
          return _syncLearningCreate(operation);
        case SyncOperationType.learningUpdate:
          return _syncLearningUpdate(operation);
        case SyncOperationType.learningDelete:
          return _syncLearningDelete(operation);
        case SyncOperationType.learningStart:
          return _syncLearningStart(operation);
        case SyncOperationType.learningComplete:
          return _syncLearningComplete(operation);
      }
    } on ApiException catch (error) {
      AppLogger.debug('Sync operation ${operation.type.name} failed: ${error.message}');
      return false;
    }
  }

  Future<bool> _syncHabitCreate(SyncOperation operation) async {
    final stored = _offlineStore.findHabitByLocalKey(operation.localKey);
    if (stored == null) {
      await _offlineStore.removeFromQueue(operation.id);
      return true;
    }

    final serverHabit = await _apiClient.post<HabitResponse>(
      '/habits',
      parser: (data) => HabitResponse.fromJson(Map<String, dynamic>.from(data as Map)),
      data: operation.payload,
    );

    final oldId = stored.habit.id;
    await _offlineStore.remapHabitId(oldId, serverHabit.id, serverHabit.uuid);
    await _habitRepository.markSynced(operation.localKey, serverHabit);
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<bool> _syncHabitUpdate(SyncOperation operation) async {
    final serverId = _resolveEntityId(operation.entityId);
    if (serverId == null || serverId <= 0) return false;

    final serverHabit = await _apiClient.put<HabitResponse>(
      '/habits/$serverId',
      parser: (data) => HabitResponse.fromJson(Map<String, dynamic>.from(data as Map)),
      data: operation.payload,
    );

    await _habitRepository.markSynced(operation.localKey, serverHabit);
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<bool> _syncHabitDelete(SyncOperation operation) async {
    final serverId = _resolveEntityId(operation.entityId);
    if (serverId != null && serverId > 0) {
      await _apiClient.delete<void>('/habits/$serverId', parser: (_) {});
    }
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<bool> _syncHabitComplete(SyncOperation operation) async {
    final serverId = _resolveEntityId(operation.entityId);
    if (serverId == null || serverId <= 0) return false;

    final payload = Map<String, dynamic>.from(operation.payload);
    payload['habitId'] = serverId;

    await _apiClient.post<HabitLogResponse>(
      '/habit-logs/complete',
      parser: (data) => HabitLogResponse.fromJson(Map<String, dynamic>.from(data as Map)),
      data: payload,
    );

    await _cache.addCompletedToday(serverId);
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<bool> _syncHabitUndo(SyncOperation operation) async {
    final serverId = _resolveEntityId(operation.entityId);
    if (serverId == null || serverId <= 0) return false;

    await _apiClient.delete<HabitLogResponse>(
      '/habit-logs/$serverId/today',
      parser: (data) {
        if (data == null) return const HabitLogResponse(completed: false);
        return HabitLogResponse.fromJson(Map<String, dynamic>.from(data as Map));
      },
    );

    await _cache.removeCompletedToday(serverId);
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<bool> _syncLearningCreate(SyncOperation operation) async {
    final stored = _offlineStore.findLearningByLocalKey(operation.localKey);
    if (stored == null) {
      await _offlineStore.removeFromQueue(operation.id);
      return true;
    }

    final serverSession = await _apiClient.post<LearningSessionResponse>(
      '/learning',
      parser: (data) => LearningSessionResponse.fromJson(Map<String, dynamic>.from(data as Map)),
      data: operation.payload,
    );

    final oldId = stored.session.id;
    await _offlineStore.remapLearningId(oldId, serverSession.id, serverSession.uuid);
    await _learningRepository.markSynced(operation.localKey, serverSession);
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<bool> _syncLearningUpdate(SyncOperation operation) async {
    final serverId = _resolveLearningEntityId(operation.entityId);
    if (serverId == null || serverId <= 0) return false;

    final serverSession = await _apiClient.put<LearningSessionResponse>(
      '/learning/$serverId',
      parser: (data) => LearningSessionResponse.fromJson(Map<String, dynamic>.from(data as Map)),
      data: operation.payload,
    );

    await _learningRepository.markSynced(operation.localKey, serverSession);
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<bool> _syncLearningDelete(SyncOperation operation) async {
    final serverId = _resolveLearningEntityId(operation.entityId);
    if (serverId != null && serverId > 0) {
      await _apiClient.delete<void>('/learning/$serverId', parser: (_) {});
    }
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<bool> _syncLearningStart(SyncOperation operation) async {
    final serverId = _resolveLearningEntityId(operation.entityId);
    if (serverId == null || serverId <= 0) return false;

    final serverSession = await _apiClient.post<LearningSessionResponse>(
      '/learning/$serverId/start',
      parser: (data) => LearningSessionResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    await _learningRepository.markSynced(operation.localKey, serverSession);
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<bool> _syncLearningComplete(SyncOperation operation) async {
    final serverId = _resolveLearningEntityId(operation.entityId);
    if (serverId == null || serverId <= 0) return false;

    final serverSession = await _apiClient.post<LearningSessionResponse>(
      '/learning/$serverId/complete',
      parser: (data) => LearningSessionResponse.fromJson(Map<String, dynamic>.from(data as Map)),
      data: operation.payload,
    );

    await _learningRepository.markSynced(operation.localKey, serverSession);
    await _offlineStore.removeFromQueue(operation.id);
    return true;
  }

  Future<void> _pullRemoteData() async {
    final habits = await _apiClient.get<List<HabitResponse>>(
      '/habits',
      parser: (data) {
        if (data is! List) return const [];
        return data
            .whereType<Map>()
            .map((item) => HabitResponse.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
    await _habitRepository.mergeRemoteHabits(habits);

    final sessions = await _apiClient.get<List<LearningSessionResponse>>(
      '/learning',
      parser: (data) {
        if (data is! List) return const [];
        return data
            .whereType<Map>()
            .map((item) => LearningSessionResponse.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
    await _learningRepository.mergeRemoteSessions(sessions);

    await _mergeDashboardStreak();
  }

  Future<void> _mergeDashboardStreak() async {
    try {
      final remote = await _apiClient.get<DashboardResponse>(
        '/dashboard',
        parser: (data) => DashboardResponse.fromJson(Map<String, dynamic>.from(data as Map)),
      );
      final local = _dashboardRepository.buildLocal();
      await _cache.saveDashboard(
        DashboardResponse(
          currentDate: DateTime.now(),
          greeting: remote.greeting ?? local.greeting,
          userName: remote.userName ?? local.userName,
          summary: DashboardSummary(
            totalHabits: local.summary?.totalHabits ?? 0,
            completedHabits: local.summary?.completedHabits ?? 0,
            pendingHabits: local.summary?.pendingHabits ?? 0,
            completionPercentage: local.summary?.completionPercentage ?? 0,
            currentStreak: remote.summary?.currentStreak ?? local.summary?.currentStreak ?? 0,
            longestStreak: remote.summary?.longestStreak ?? local.summary?.longestStreak ?? 0,
          ),
          todayHabits: local.todayHabits,
        ),
      );
    } catch (error) {
      AppLogger.debug('Dashboard streak merge skipped: $error');
    }
  }

  int? _resolveEntityId(int? entityId) {
    if (entityId == null) return null;
    if (entityId > 0) return entityId;
    final stored = _offlineStore.findHabitById(entityId);
    if (stored == null) return null;
    return stored.habit.id > 0 ? stored.habit.id : null;
  }

  int? _resolveLearningEntityId(int? entityId) {
    if (entityId == null) return null;
    if (entityId > 0) return entityId;
    final stored = _offlineStore.findLearningById(entityId);
    if (stored == null) return null;
    return stored.session.id > 0 ? stored.session.id : null;
  }
}
