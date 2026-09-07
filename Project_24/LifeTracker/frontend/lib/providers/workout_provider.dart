import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/preset_workout_templates.dart';
import '../models/workout/workout_schedule_model.dart';
import '../models/workout/workout_template_model.dart';
import '../services/api_client.dart';
import '../services/workout_service.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider(this._workoutService);

  final WorkoutService _workoutService;

  static const _scheduleStoreKey = 'offline_workout_schedules_store_v1';
  static const _templatesStoreKey = 'offline_workout_templates_store_v1';

  bool isLoading = false;
  bool isActionLoading = false;
  String? errorMessage;

  List<WorkoutScheduleModel> weeklySchedule = [];
  List<WorkoutTemplateModel> templates = List.of(kPresetWorkoutTemplates);

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
    isLoading = false;
    errorMessage = null;
    await _loadScheduleFromDisk();
    notifyListeners();

    _fetchFromServerInBackground(date: date);
  }

  Future<void> _saveScheduleToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = weeklySchedule.map((s) => s.toJson()).toList();
      await prefs.setString(_scheduleStoreKey, jsonEncode(jsonList));

      final customOnly = templates.where((t) => !t.isPreset).map((t) => t.toJson()).toList();
      await prefs.setString(_templatesStoreKey, jsonEncode(customOnly));
    } catch (e) {
      debugPrint('Failed to save workout schedule to disk: $e');
    }
  }

  Future<void> _loadScheduleFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scheduleStoreKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        final loaded = decoded
            .whereType<Map>()
            .map((item) => WorkoutScheduleModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (loaded.isNotEmpty) {
          weeklySchedule = loaded;
        }
      }

      final rawT = prefs.getString(_templatesStoreKey);
      if (rawT != null && rawT.isNotEmpty) {
        final decodedT = jsonDecode(rawT) as List;
        final loadedT = decodedT
            .whereType<Map>()
            .map((item) => WorkoutTemplateModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (loadedT.isNotEmpty) {
          templates = [...kPresetWorkoutTemplates, ...loadedT];
        }
      }
    } catch (e) {
      debugPrint('Failed to load workout schedule from disk: $e');
    }
  }

  void _fetchFromServerInBackground({DateTime? date}) async {
    try {
      final results = await Future.wait([
        _workoutService.getWeeklySchedule(date: date),
        _workoutService.getTemplates(),
      ]);

      weeklySchedule = results[0] as List<WorkoutScheduleModel>;
      final serverTemplates = results[1] as List<WorkoutTemplateModel>;
      if (serverTemplates.isNotEmpty) {
        final customOnly = serverTemplates.where((t) => !t.isPreset);
        templates = [...kPresetWorkoutTemplates, ...customOnly];
      }
      await _saveScheduleToDisk();
      notifyListeners();
    } catch (_) {
      // Ignore errors when background fetching
    }
  }

  Future<bool> missedToday({DateTime? date}) async {
    isActionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = date ?? DateTime.now();
      final targetDate = DateTime(now.year, now.month, now.day);

      final updatedList = <WorkoutScheduleModel>[];

      for (final item in weeklySchedule) {
        final itemDate = DateTime(item.scheduledDate.year, item.scheduledDate.month, item.scheduledDate.day);
        if (itemDate.isBefore(targetDate)) {
          updatedList.add(item);
        } else if (itemDate.isAtSameMomentAs(targetDate)) {
          if (item.status == 'COMPLETED') {
            updatedList.add(item);
          } else {
            // Shift this planned workout +1 day forward
            updatedList.add(WorkoutScheduleModel(
              id: item.id,
              scheduledDate: item.scheduledDate.add(const Duration(days: 1)),
              customTitle: item.customTitle,
              template: item.template,
              notes: item.notes,
              status: item.status,
              completedAt: item.completedAt,
            ));
          }
        } else {
          // Future item on or after targetDate
          if (item.status == 'PLANNED') {
            updatedList.add(WorkoutScheduleModel(
              id: item.id,
              scheduledDate: item.scheduledDate.add(const Duration(days: 1)),
              customTitle: item.customTitle,
              template: item.template,
              notes: item.notes,
              status: item.status,
              completedAt: item.completedAt,
            ));
          } else {
            updatedList.add(item);
          }
        }
      }

      // Add MISSED entry for targetDate
      final missedEntryId = DateTime.now().millisecondsSinceEpoch;
      updatedList.add(WorkoutScheduleModel(
        id: missedEntryId,
        scheduledDate: targetDate,
        customTitle: 'Missed Workout',
        template: null,
        notes: null,
        status: 'MISSED',
        completedAt: null,
      ));

      updatedList.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      weeklySchedule = updatedList;
      await _saveScheduleToDisk();

      // Try server in background
      _workoutService.missedToday(date: date).then((serverSchedule) async {
        if (serverSchedule.isNotEmpty) {
          weeklySchedule = serverSchedule;
          await _saveScheduleToDisk();
          notifyListeners();
        }
      }).catchError((_) {});

      return true;
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
      final index = weeklySchedule.indexWhere((s) => s.id == scheduleId);
      if (index != -1) {
        final current = weeklySchedule[index];
        weeklySchedule[index] = WorkoutScheduleModel(
          id: current.id,
          scheduledDate: current.scheduledDate,
          customTitle: current.customTitle,
          template: current.template,
          notes: notes ?? current.notes,
          status: 'COMPLETED',
          completedAt: DateTime.now(),
        );
        await _saveScheduleToDisk();
      }
      _workoutService.completeWorkout(scheduleId, notes: notes).then((updated) async {
        final idx = weeklySchedule.indexWhere((s) => s.id == scheduleId);
        if (idx != -1) {
          weeklySchedule[idx] = updated;
          await _saveScheduleToDisk();
          notifyListeners();
        }
      }).catchError((_) {});
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
      final localId = DateTime.now().millisecondsSinceEpoch;
      final created = WorkoutTemplateModel(
        id: localId,
        name: template.name,
        category: template.category,
        description: template.description,
        isPreset: template.isPreset,
        exercises: template.exercises,
      );
      templates.add(created);
      await _saveScheduleToDisk();
      
      _workoutService.createTemplate(template).catchError((_) => created);
      return true;
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
      final index = templates.indexWhere((t) => t.id == id);
      if (index != -1) {
        templates[index] = WorkoutTemplateModel(
          id: id,
          name: template.name,
          category: template.category,
          description: template.description,
          isPreset: template.isPreset,
          exercises: template.exercises,
        );
        await _saveScheduleToDisk();
      }
      _workoutService.updateTemplate(id, template).catchError((_) => template);
      return true;
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
      await _saveScheduleToDisk();
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

  Future<bool> assignTemplateToDate(WorkoutTemplateModel template, DateTime targetDate) async {
    isActionLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final normalizedTarget = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final index = weeklySchedule.indexWhere((s) {
        final schedNorm = DateTime(s.scheduledDate.year, s.scheduledDate.month, s.scheduledDate.day);
        return schedNorm.isAtSameMomentAs(normalizedTarget);
      });

      final localScheduleId = index != -1 ? weeklySchedule[index].id : DateTime.now().millisecondsSinceEpoch;
      final updatedSchedule = WorkoutScheduleModel(
        id: localScheduleId,
        scheduledDate: normalizedTarget,
        customTitle: template.name,
        template: template,
        status: 'PLANNED',
      );

      if (index != -1) {
        weeklySchedule[index] = updatedSchedule;
      } else {
        weeklySchedule.add(updatedSchedule);
        weeklySchedule.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      }

      await _saveScheduleToDisk();
      _workoutService.assignWorkoutToDate(template.id, normalizedTarget).catchError((_) => updatedSchedule);
      return true;
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
