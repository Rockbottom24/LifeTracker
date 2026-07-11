class DailyPerformanceResponse {
  const DailyPerformanceResponse({
    required this.date,
    required this.earnedPoints,
    required this.possiblePoints,
    required this.completionPercentage,
    required this.completedHabits,
    required this.plannedHabits,
    required this.habits,
    required this.nutrition,
  });

  final DateTime date;
  final int earnedPoints;
  final int possiblePoints;
  final double completionPercentage;
  final int completedHabits;
  final int plannedHabits;
  final List<HabitPerformanceItem> habits;
  final NutritionPerformance nutrition;

  factory DailyPerformanceResponse.fromJson(Map<String, dynamic> json) {
    return DailyPerformanceResponse(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      earnedPoints: _toInt(json['earnedPoints']),
      possiblePoints: _toInt(json['possiblePoints']),
      completionPercentage: _toDouble(json['completionPercentage']),
      completedHabits: _toInt(json['completedHabits']),
      plannedHabits: _toInt(json['plannedHabits']),
      habits: (json['habits'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => HabitPerformanceItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      nutrition: NutritionPerformance.fromJson(
        Map<String, dynamic>.from((json['nutrition'] as Map?) ?? const {}),
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class HabitPerformanceItem {
  const HabitPerformanceItem({
    required this.habitId,
    required this.habitName,
    required this.completed,
    required this.configuredPoints,
    required this.pointsAwarded,
  });

  final int habitId;
  final String habitName;
  final bool completed;
  final int configuredPoints;
  final int pointsAwarded;

  factory HabitPerformanceItem.fromJson(Map<String, dynamic> json) {
    return HabitPerformanceItem(
      habitId: DailyPerformanceResponse._toInt(json['habitId']),
      habitName: json['habitName']?.toString() ?? 'Habit',
      completed: json['completed'] as bool? ?? false,
      configuredPoints: DailyPerformanceResponse._toInt(json['configuredPoints']),
      pointsAwarded: DailyPerformanceResponse._toInt(json['pointsAwarded']),
    );
  }
}

class NutritionPerformance {
  const NutritionPerformance({
    required this.calories,
    required this.calorieGoal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.meals,
  });

  final double calories;
  final double calorieGoal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final List<MealPerformanceItem> meals;

  factory NutritionPerformance.fromJson(Map<String, dynamic> json) {
    return NutritionPerformance(
      calories: DailyPerformanceResponse._toDouble(json['calories']),
      calorieGoal: DailyPerformanceResponse._toDouble(json['calorieGoal']),
      protein: DailyPerformanceResponse._toDouble(json['protein']),
      carbs: DailyPerformanceResponse._toDouble(json['carbs']),
      fat: DailyPerformanceResponse._toDouble(json['fat']),
      fiber: DailyPerformanceResponse._toDouble(json['fiber']),
      meals: (json['meals'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => MealPerformanceItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
    );
  }
}

class MealPerformanceItem {
  const MealPerformanceItem({
    required this.mealId,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final int mealId;
  final String mealType;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  factory MealPerformanceItem.fromJson(Map<String, dynamic> json) {
    return MealPerformanceItem(
      mealId: DailyPerformanceResponse._toInt(json['mealId']),
      mealType: json['mealType']?.toString() ?? '',
      calories: DailyPerformanceResponse._toDouble(json['calories']),
      protein: DailyPerformanceResponse._toDouble(json['protein']),
      carbs: DailyPerformanceResponse._toDouble(json['carbs']),
      fat: DailyPerformanceResponse._toDouble(json['fat']),
      fiber: DailyPerformanceResponse._toDouble(json['fiber']),
    );
  }
}
