class CompleteLearningRequest {
  const CompleteLearningRequest({required this.completedMinutes});

  final int completedMinutes;

  Map<String, dynamic> toJson() => {'completedMinutes': completedMinutes};
}
