enum LearningPriority {
  low('LOW', 'Low'),
  medium('MEDIUM', 'Medium'),
  high('HIGH', 'High');

  const LearningPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static LearningPriority fromApiValue(String value) {
    return LearningPriority.values.firstWhere(
      (item) => item.apiValue == value.toUpperCase(),
      orElse: () => LearningPriority.medium,
    );
  }
}
