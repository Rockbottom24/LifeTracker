class MacroProgressItem {
  const MacroProgressItem({
    required this.key,
    required this.label,
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.progressPercent,
  });

  final String key;
  final String label;
  final double consumed;
  final double goal;
  final double remaining;
  final double progressPercent;

  factory MacroProgressItem.fromJson(Map<String, dynamic> json) {
    return MacroProgressItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      consumed: _toDouble(json['consumed']),
      goal: _toDouble(json['goal']),
      remaining: _toDouble(json['remaining']),
      progressPercent: _toDouble(json['progressPercent']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
