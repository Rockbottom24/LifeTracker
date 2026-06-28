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
    final hadCachedData = dashboard != null;
    isLoading = !hadCachedData;
    isRefreshing = hadCachedData;
    if (!hadCachedData) {
      errorMessage = null;
    }

    dashboard = _service.getDashboardLocal();
    _refreshSyncState();
    notifyListeners();

    try {
      await _service.syncWithServer();
      dashboard = _service.getDashboardLocal();
      _refreshSyncState();
      errorMessage = null;
    } on ApiException catch (e) {
      if (dashboard == null) {
        errorMessage = e.message;
        syncMessage = null;
        isOffline = false;
      } else {
        _refreshSyncState(networkUnavailable: true);
        errorMessage = null;
      }
    } catch (e) {
      if (dashboard == null) {
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

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
