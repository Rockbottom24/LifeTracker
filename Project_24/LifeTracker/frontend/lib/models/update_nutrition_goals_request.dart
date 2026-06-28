class UpdateNutritionGoalsRequest {
  const UpdateNutritionGoalsRequest({
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.fiberGoal,
  });

  final double calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;
  final double fiberGoal;

  Map<String, dynamic> toJson() {
    return {
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
      'fiberGoal': fiberGoal,
    };
  }
}
