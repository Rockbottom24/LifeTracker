enum MealType {
  breakfast('BREAKFAST', 'Breakfast'),
  lunch('LUNCH', 'Lunch'),
  snack('SNACK', 'Snacks'),
  dinner('DINNER', 'Dinner');

  const MealType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MealType fromApiValue(String? value) {
    return MealType.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => MealType.breakfast,
    );
  }
}
