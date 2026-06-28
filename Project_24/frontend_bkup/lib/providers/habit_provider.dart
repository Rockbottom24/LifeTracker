import 'package:flutter/material.dart';

import '../models/create_habit_request.dart';
import '../models/habit_response.dart';
import '../../../frontend/lib/services/habit_service.dart';

class HabitProvider extends ChangeNotifier {
  HabitProvider(this._habitService);

  final HabitService _habitService;

  bool isLoading = false;
  bool isSaving = false;

  String? errorMessage;

  List<HabitResponse> habits = [];

  Future<void> loadHabits() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      habits = await _habitService.getHabits();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createHabit(CreateHabitRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _habitService.createHabit(request.toJson());

      await loadHabits();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> completeHabit(int habitId) async {
    try {
      await _habitService.completeHabit(habitId);
      await loadHabits();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> undoHabit(int habitId) async {
    try {
      await _habitService.undoHabit(habitId);
      await loadHabits();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteHabit(int id) async {
    try {
      await _habitService.deleteHabit(id);
      await loadHabits();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}