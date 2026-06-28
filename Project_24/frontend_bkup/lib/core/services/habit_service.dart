import 'package:lifetracker/core/api/api_client.dart';
import 'package:lifetracker/models/habit_log_response.dart';
import 'package:lifetracker/models/habit_response.dart';

class HabitService {
  HabitService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<HabitResponse>> getHabits() async {
    return _apiClient.get<List<HabitResponse>>(
      '/habits',
      parser: (data) {
        final items = data as List<dynamic>;
        return items
            .map((item) => HabitResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<HabitResponse> getHabit(int id) async {
    return _apiClient.get<HabitResponse>(
      '/habits/$id',
      parser: (data) => HabitResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<HabitResponse> createHabit(Map<String, dynamic> payload) async {
    return _apiClient.post<HabitResponse>(
      '/habits',
      parser: (data) => HabitResponse.fromJson(data as Map<String, dynamic>),
      data: payload,
    );
  }

  Future<HabitResponse> updateHabit(int id, Map<String, dynamic> payload) async {
    return _apiClient.put<HabitResponse>(
      '/habits/$id',
      parser: (data) => HabitResponse.fromJson(data as Map<String, dynamic>),
      data: payload,
    );
  }

  Future<HabitLogResponse> completeHabit(int habitId, {double value = 1.0, String? notes}) async {
    return _apiClient.post<HabitLogResponse>(
      '/habit-logs/complete',
      parser: (data) => HabitLogResponse.fromJson(data as Map<String, dynamic>),
      data: {
        'habitId': habitId,
        'value': value,
        'notes': notes,
      },
    );
  }

  Future<HabitLogResponse> undoHabit(int habitId) async {
    return _apiClient.delete<HabitLogResponse>(
      '/habit-logs/$habitId/today',
      parser: (data) => HabitLogResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> deleteHabit(int id) async {
    await _apiClient.delete<void>(
      '/habits/$id',
      parser: (data) => const <String, dynamic>{},
    );
  }
}
