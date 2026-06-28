import '../models/dashboard_response.dart';
import '../repositories/dashboard_repository.dart';
import '../sync/sync_engine.dart';

class DashboardService {
  DashboardService({
    required this._repository,
    required this._syncEngine,
  });

  final DashboardRepository _repository;
  final SyncEngine _syncEngine;

  DashboardResponse getDashboardLocal() => _repository.buildLocal();

  bool get hasPendingSync => _syncEngine.hasPendingChanges;

  Future<void> syncWithServer() async {
    await _syncEngine.syncAll();
  }

  Future<DashboardResponse> getDashboard() async {
    final local = getDashboardLocal();
    await _repository.saveLocalSnapshot();
    return local;
  }
}
