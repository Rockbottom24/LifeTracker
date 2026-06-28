enum ExpenseType {
  personal('PERSONAL'),
  sharedLiving('SHARED_LIVING'),
  family('FAMILY');

  const ExpenseType(this.apiValue);

  final String apiValue;

  static ExpenseType fromApiValue(String? value) {
    return ExpenseType.values.firstWhere(
      (type) => type.apiValue == value?.toUpperCase(),
      orElse: () => ExpenseType.personal,
    );
  }

  String get label => switch (this) {
        ExpenseType.personal => 'Personal Expenses',
        ExpenseType.sharedLiving => 'Shared Living',
        ExpenseType.family => 'Family Support',
      };

  String get shortLabel => switch (this) {
        ExpenseType.personal => 'Personal',
        ExpenseType.sharedLiving => 'Shared Living',
        ExpenseType.family => 'Family',
      };

  String get listTitle => switch (this) {
        ExpenseType.personal => 'Personal expenses',
        ExpenseType.sharedLiving => 'Shared living expenses',
        ExpenseType.family => 'Family support expenses',
      };
}
