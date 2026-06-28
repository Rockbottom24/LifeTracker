class NutritionGoalsResponse {
  const NutritionGoalsResponse({
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.fiberGoal,
  });

  static const defaults = NutritionGoalsResponse(
    calorieGoal: 2500,
    proteinGoal: 150,
    carbsGoal: 300,
    fatGoal: 70,
    fiberGoal: 35,
  );

  final double calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;
  final double fiberGoal;

  factory NutritionGoalsResponse.fromJson(Map<String, dynamic> json) {
    return NutritionGoalsResponse(
      calorieGoal: _toDouble(json['calorieGoal'], 2500),
      proteinGoal: _toDouble(json['proteinGoal'], 150),
      carbsGoal: _toDouble(json['carbsGoal'], 300),
      fatGoal: _toDouble(json['fatGoal'], 70),
      fiberGoal: _toDouble(json['fiberGoal'], 35),
    );
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
