import 'package:flutter/foundation.dart';

import '../core/services/dashboard_service.dart';
import '../models/dashboard_response.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._service);

  final DashboardService _service;
  DashboardResponse? dashboard;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      dashboard = await _service.getDashboard();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
