import 'package:flutter/foundation.dart';

import '../models/workout/workout_schedule_model.dart';
import '../models/workout/workout_template_model.dart';
import '../services/api_client.dart';
import '../services/workout_service.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider(this._workoutService);

  final WorkoutService _workoutService;

  bool isLoading = false;
  bool isActionLoading = false;
  String? errorMessage;

  List<WorkoutScheduleModel> weeklySchedule = [];
  List<WorkoutTemplateModel> templates = [];

  WorkoutScheduleModel? get todaySchedule {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    for (final item in weeklySchedule) {
      final scheduled = DateTime(item.scheduledDate.year, item.scheduledDate.month, item.scheduledDate.day);
      if (scheduled.isAtSameMomentAs(todayDate)) {
        return item;
      }
    }
    return weeklySchedule.isNotEmpty ? weeklySchedule.first : null;
  }

  Future<void> loadScheduleAndTemplates({DateTime? date}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _workoutService.getWeeklySchedule(date: date),
        _workoutService.getTemplates(),
      ]);

      weeklySchedule = results[0] as List<WorkoutScheduleModel>;
      templates = results[1] as List<WorkoutTemplateModel>;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> missedToday({DateTime? date}) async {
    isActionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      weeklySchedule = await _workoutService.missedToday(date: date);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeWorkout(int scheduleId, {String? notes}) async {
    isActionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _workoutService.completeWorkout(scheduleId, notes: notes);
      final index = weeklySchedule.indexWhere((s) => s.id == scheduleId);
      if (index != -1) {
        weeklySchedule[index] = updated;
      }
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTemplate(WorkoutTemplateModel template) async {
    isActionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final created = await _workoutService.createTemplate(template);
      templates.add(created);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTemplate(int id, WorkoutTemplateModel template) async {
    isActionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _workoutService.updateTemplate(id, template);
      final index = templates.indexWhere((t) => t.id == id);
      if (index != -1) {
        templates[index] = updated;
      }
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyCycle(List<int?> templateIdsInOrder) async {
    isActionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      weeklySchedule = await _workoutService.applyCycle(templateIdsInOrder: templateIdsInOrder);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
