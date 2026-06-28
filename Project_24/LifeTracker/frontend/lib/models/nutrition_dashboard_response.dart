import 'macro_progress_item.dart';
import 'meal_response.dart';
import 'nutrition_goals_response.dart';

class NutritionDashboardResponse {
  const NutritionDashboardResponse({
    required this.date,
    required this.goals,
    required this.progress,
    required this.insights,
    required this.meals,
  });

  final DateTime date;
  final NutritionGoalsResponse goals;
  final List<MacroProgressItem> progress;
  final List<String> insights;
  final List<MealResponse> meals;

  factory NutritionDashboardResponse.fromJson(Map<String, dynamic> json) {
    final progressJson = json['progress'];
    final insightsJson = json['insights'];
    final mealsJson = json['meals'];

    return NutritionDashboardResponse(
      date: DateTime.parse(json['date'].toString()),
      goals: NutritionGoalsResponse.fromJson(Map<String, dynamic>.from(json['goals'] as Map)),
      progress: progressJson is List
          ? progressJson
              .whereType<Map>()
              .map((item) => MacroProgressItem.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      insights: insightsJson is List ? insightsJson.map((item) => item.toString()).toList() : const [],
      meals: mealsJson is List
          ? mealsJson
              .whereType<Map>()
              .map((item) => MealResponse.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }
}
