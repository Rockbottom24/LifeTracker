import 'package:flutter/foundation.dart';

import '../local/local_cache_store.dart';
import '../models/dashboard_response.dart';
import '../services/api_client.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._service, this._cache) {
    _hydrateFromLocal();
  }

  final DashboardService _service;
  final LocalCacheStore _cache;

  DashboardResponse? dashboard;
  bool isLoading = false;
  bool isRefreshing = false;
  bool isOffline = false;
  String? errorMessage;
  String? syncMessage;
  DateTime? lastSyncedAt;

  bool get hasPendingSync => _service.hasPendingSync;

  void _hydrateFromLocal() {
    dashboard = _service.getDashboardLocal();
    _refreshSyncState();
  }

  void _refreshSyncState({bool networkUnavailable = false}) {
    if (_service.hasPendingSync) {
      syncMessage = 'Saved locally. Will sync when server is available.';
      isOffline = false;
    } else if (networkUnavailable && dashboard != null) {
      syncMessage = "You're offline. Showing your last synced data.";
      isOffline = true;
    } else {
      syncMessage = null;
      isOffline = false;
    }
    lastSyncedAt = _cache.getLastSynced(CacheEntity.dashboard);
  }

  Future<void> loadDashboard() async {
    isLoading = false;
    isRefreshing = false;
    errorMessage = null;

    dashboard = _service.getDashboardLocal();
    _refreshSyncState();
    notifyListeners();

    _syncWithServerInBackground();
  }

  void _syncWithServerInBackground() async {
    try {
      await _service.syncWithServer();
      dashboard = _service.getDashboardLocal();
      _refreshSyncState();
      errorMessage = null;
      notifyListeners();
    } catch (_) {
      _refreshSyncState(networkUnavailable: true);
      errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
