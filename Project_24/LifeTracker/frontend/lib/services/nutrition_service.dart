import 'api_client.dart';
import '../models/nutrition_dashboard_response.dart';
import '../models/nutrition_goals_response.dart';
import '../models/update_nutrition_goals_request.dart';

class NutritionService {
  NutritionService({required this._apiClient});

  final ApiClient _apiClient;

  Future<NutritionDashboardResponse> getDashboard({DateTime? date}) async {
    final query = date == null ? null : {'date': _formatDate(date)};
    return _apiClient.get<NutritionDashboardResponse>(
      '/nutrition/dashboard',
      queryParameters: query,
      parser: (data) => NutritionDashboardResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<NutritionGoalsResponse> getGoals() async {
    return _apiClient.get<NutritionGoalsResponse>(
      '/nutrition/goals',
      parser: (data) => NutritionGoalsResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<NutritionGoalsResponse> updateGoals(UpdateNutritionGoalsRequest request) async {
    return _apiClient.put<NutritionGoalsResponse>(
      '/nutrition/goals',
      data: request.toJson(),
      parser: (data) => NutritionGoalsResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
