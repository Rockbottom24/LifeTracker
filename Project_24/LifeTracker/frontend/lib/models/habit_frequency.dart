enum HabitFrequency {
  daily('DAILY', 'Daily'),
  weekly('WEEKLY', 'Weekly'),
  monthly('MONTHLY', 'Monthly'),
  custom('CUSTOM', 'Custom days');

  const HabitFrequency(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static HabitFrequency fromApiValue(String value) {
    return HabitFrequency.values.firstWhere(
      (item) => item.apiValue == value.toUpperCase(),
      orElse: () => HabitFrequency.daily,
    );
  }
}
