import 'package:lifetracker/core/api/api_client.dart';
import 'package:lifetracker/models/dashboard_response.dart';

class DashboardService {
  DashboardService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<DashboardResponse> getDashboard() async {
    return _apiClient.get<DashboardResponse>(
      '/dashboard',
      parser: (data) => DashboardResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
