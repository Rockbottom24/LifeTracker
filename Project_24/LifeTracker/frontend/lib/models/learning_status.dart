enum LearningStatus {
  planned('PLANNED', 'Planned'),
  inProgress('IN_PROGRESS', 'In Progress'),
  completed('COMPLETED', 'Completed'),
  skipped('SKIPPED', 'Skipped');

  const LearningStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static LearningStatus fromApiValue(String value) {
    return LearningStatus.values.firstWhere(
      (item) => item.apiValue == value.toUpperCase(),
      orElse: () => LearningStatus.planned,
    );
  }
}
