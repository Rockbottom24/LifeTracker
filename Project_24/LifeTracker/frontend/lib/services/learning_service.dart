import 'dart:async';

import '../local/local_cache_store.dart';
import '../models/complete_learning_request.dart';
import '../models/learning_session_response.dart';
import '../repositories/learning_repository.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_status.dart';
import 'api_client.dart';

class LearningService {
  LearningService({
    required this._apiClient,
    required this._cache,
    required this._repository,
    required this._syncEngine,
  });

  final ApiClient _apiClient;
  final LocalCacheStore _cache;
  final LearningRepository _repository;
  final SyncEngine _syncEngine;

  List<LearningSessionResponse> getSessionsLocal() => _repository.getVisibleSessions();

  bool get hasPendingSync => _syncEngine.hasPendingChanges;

  SyncStatus? syncStatusFor(int sessionId) => _repository.syncStatusFor(sessionId);

  Future<void> syncWithServer() async {
    await _syncEngine.syncAll();
  }

  Future<List<LearningSessionResponse>> getSessions() async {
    unawaited(_syncEngine.syncAll());
    return getSessionsLocal();
  }

  Future<LearningSessionResponse> getSession(int id) async {
    final stored = _repository.findStoredById(id);
    if (stored != null) return stored.session;

    try {
      final session = await _apiClient.get<LearningSessionResponse>(
        '/learning/$id',
        parser: (data) => LearningSessionResponse.fromJson(Map<String, dynamic>.from(data as Map)),
      );
      await _cache.upsertLearningSession(session);
      return session;
    } on ApiException {
      final local = _repository.findStoredById(id);
      if (local != null) return local.session;
      rethrow;
    }
  }

  Future<LearningSessionResponse> createSession(Map<String, dynamic> payload) async {
    final stored = await _repository.createLocal(payload);
    unawaited(_syncEngine.syncAll());
    return stored.session;
  }

  Future<LearningSessionResponse> updateSession(int id, Map<String, dynamic> payload) async {
    final stored = await _repository.updateLocal(id, payload);
    unawaited(_syncEngine.syncAll());
    return stored.session;
  }

  Future<void> deleteSession(int id) async {
    await _repository.deleteLocal(id);
    unawaited(_syncEngine.syncAll());
  }

  Future<LearningSessionResponse> startSession(int id) async {
    final stored = await _repository.startLocal(id);
    unawaited(_syncEngine.syncAll());
    return stored.session;
  }

  Future<LearningSessionResponse> completeSession(int id, CompleteLearningRequest request) async {
    final stored = await _repository.completeLocal(id, request);
    unawaited(_syncEngine.syncAll());
    return stored.session;
  }
}
