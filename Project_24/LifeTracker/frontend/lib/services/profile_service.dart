import '../models/daily_performance_response.dart';
import '../models/profile_response.dart';
import 'api_client.dart';

class ProfileService {
  ProfileService({required this._apiClient});

  final ApiClient _apiClient;

  Future<ProfileResponse> getProfile() {
    return _apiClient.get<ProfileResponse>(
      '/profile',
      parser: (data) => ProfileResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<DailyPerformanceResponse> getDailyPerformance(DateTime date) {
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _apiClient.get<DailyPerformanceResponse>(
      '/profile/performance/$dateKey',
      parser: (data) => DailyPerformanceResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }
}
