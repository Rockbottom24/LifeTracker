import '../../models/workout/workout_schedule_model.dart';
import '../../models/workout/workout_template_model.dart';
import '../api_client.dart';

class WorkoutService {
  WorkoutService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<WorkoutTemplateModel>> getTemplates() async {
    return _apiClient.get<List<WorkoutTemplateModel>>(
      '/workouts/templates',
      parser: (data) {
        if (data is! List) return [];
        return data
            .map((item) => WorkoutTemplateModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      },
    );
  }

  Future<WorkoutTemplateModel> createTemplate(WorkoutTemplateModel template) async {
    return _apiClient.post<WorkoutTemplateModel>(
      '/workouts/templates',
      data: template.toJson(),
      parser: (data) => WorkoutTemplateModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<WorkoutTemplateModel> updateTemplate(int id, WorkoutTemplateModel template) async {
    return _apiClient.put<WorkoutTemplateModel>(
      '/workouts/templates/$id',
      data: template.toJson(),
      parser: (data) => WorkoutTemplateModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<void> deleteTemplate(int id) async {
    await _apiClient.delete<void>(
      '/workouts/templates/$id',
      parser: (_) {},
    );
  }

  Future<List<WorkoutScheduleModel>> getWeeklySchedule({DateTime? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) {
      queryParams['date'] = date.toIso8601String().split('T')[0];
    }
    return _apiClient.get<List<WorkoutScheduleModel>>(
      '/workouts/schedule',
      queryParameters: queryParams,
      parser: (data) {
        if (data is! List) return [];
        return data
            .map((item) => WorkoutScheduleModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      },
    );
  }

  Future<List<WorkoutScheduleModel>> missedToday({DateTime? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) {
      queryParams['date'] = date.toIso8601String().split('T')[0];
    }
    return _apiClient.post<List<WorkoutScheduleModel>>(
      '/workouts/schedule/missed-today',
      queryParameters: queryParams,
      parser: (data) {
        if (data is! List) return [];
        return data
            .map((item) => WorkoutScheduleModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      },
    );
  }

  Future<WorkoutScheduleModel> completeWorkout(int scheduleId, {String? notes}) async {
    final queryParams = <String, dynamic>{};
    if (notes != null && notes.isNotEmpty) {
      queryParams['notes'] = notes;
    }
    return _apiClient.post<WorkoutScheduleModel>(
      '/workouts/schedule/$scheduleId/complete',
      queryParameters: queryParams,
      parser: (data) => WorkoutScheduleModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<List<WorkoutScheduleModel>> applyCycle({
    DateTime? startDate,
    required List<int?> templateIdsInOrder,
  }) async {
    return _apiClient.post<List<WorkoutScheduleModel>>(
      '/workouts/schedule/apply-cycle',
      data: {
        if (startDate != null) 'startDate': startDate.toIso8601String().split('T')[0],
        'templateIdsInOrder': templateIdsInOrder,
      },
      parser: (data) {
        if (data is! List) return [];
        return data
            .map((item) => WorkoutScheduleModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      },
    );
  }
}
