import 'package:flutter/foundation.dart';

import '../local/local_cache_store.dart';
import '../models/complete_learning_request.dart';
import '../models/create_learning_request.dart';
import '../models/learning_session_response.dart';
import '../models/update_learning_request.dart';
import '../services/api_client.dart';
import '../services/learning_service.dart';
import '../sync/sync_status.dart';

class LearningProvider extends ChangeNotifier {
  LearningProvider(this._service, this._cache) {
    _hydrateFromLocal();
  }

  final LearningService _service;
  final LocalCacheStore _cache;

  bool isLoading = false;
  bool isRefreshing = false;
  bool isSaving = false;
  bool isOffline = false;
  String? errorMessage;
  String? syncMessage;
  DateTime? lastSyncedAt;
  List<LearningSessionResponse> sessions = [];

  SyncStatus? syncStatusForSession(int sessionId) => _service.syncStatusFor(sessionId);

  bool get hasPendingSync => _service.hasPendingSync;

  void _hydrateFromLocal() {
    sessions = _service.getSessionsLocal();
    _refreshSyncState();
  }

  void _refreshSyncState({bool networkUnavailable = false}) {
    if (_service.hasPendingSync) {
      syncMessage = 'Saved locally. Will sync when server is available.';
      isOffline = false;
    } else if (networkUnavailable && sessions.isNotEmpty) {
      syncMessage = "You're offline. Showing your last synced data.";
      isOffline = true;
    } else {
      syncMessage = null;
      isOffline = false;
    }
    lastSyncedAt = _cache.getLastSynced(CacheEntity.learningSessions);
  }

  Future<void> loadSessions() async {
    final hadCachedData = sessions.isNotEmpty;
    isLoading = !hadCachedData;
    isRefreshing = hadCachedData;
    if (!hadCachedData) {
      errorMessage = null;
    }

    sessions = _service.getSessionsLocal();
    _refreshSyncState();
    notifyListeners();

    try {
      await _service.syncWithServer();
      sessions = _service.getSessionsLocal();
      _refreshSyncState();
      errorMessage = null;
    } on ApiException catch (e) {
      if (sessions.isEmpty) {
        errorMessage = e.message;
        syncMessage = null;
        isOffline = false;
      } else {
        _refreshSyncState(networkUnavailable: true);
        errorMessage = null;
      }
    } catch (e) {
      if (sessions.isEmpty) {
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

  LearningSessionResponse? findSessionById(int id) {
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  List<LearningSessionResponse> get todaySessions {
    final today = DateTime.now();
    return sessions.where((session) {
      final date = session.scheduledDate;
      if (date == null) return true;
      return date.year == today.year && date.month == today.month && date.day == today.day;
    }).toList();
  }

  Future<LearningSessionResponse?> createSession(CreateLearningRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await _service.createSession(request.toJson());
      sessions = _service.getSessionsLocal();
      _refreshSyncState();
      notifyListeners();
      return session;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateSession(int id, UpdateLearningRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.updateSession(id, request.toJson());
      sessions = _service.getSessionsLocal();
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

  Future<bool> deleteSession(int id) async {
    try {
      await _service.deleteSession(id);
      sessions = _service.getSessionsLocal();
      _refreshSyncState();
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<LearningSessionResponse?> startSession(int id) async {
    try {
      final session = await _service.startSession(id);
      sessions = _service.getSessionsLocal();
      _refreshSyncState();
      notifyListeners();
      return session;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<LearningSessionResponse?> completeSession(int id, int completedMinutes) async {
    try {
      final session = await _service.completeSession(
        id,
        CompleteLearningRequest(completedMinutes: completedMinutes),
      );
      sessions = _service.getSessionsLocal();
      _refreshSyncState();
      notifyListeners();
      return session;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
