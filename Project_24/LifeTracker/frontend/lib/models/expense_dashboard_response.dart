import 'expense_response.dart';

class ComparisonMetric {
  const ComparisonMetric({
    required this.thisMonth,
    required this.lastMonth,
    required this.changeAmount,
    required this.changePercent,
  });

  final double thisMonth;
  final double lastMonth;
  final double changeAmount;
  final double changePercent;

  factory ComparisonMetric.fromJson(Map<String, dynamic> json) {
    return ComparisonMetric(
      thisMonth: _toDouble(json['thisMonth']),
      lastMonth: _toDouble(json['lastMonth']),
      changeAmount: _toDouble(json['changeAmount']),
      changePercent: _toDouble(json['changePercent']),
    );
  }

  bool get isIncrease => changeAmount > 0;
  bool get isDecrease => changeAmount < 0;
}

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.monthLabel,
    required this.year,
    required this.month,
    required this.amount,
  });

  final String monthLabel;
  final int year;
  final int month;
  final double amount;

  factory MonthlyTrendPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendPoint(
      monthLabel: json['monthLabel'] as String? ?? '',
      year: _toInt(json['year']) ?? 0,
      month: _toInt(json['month']) ?? 0,
      amount: _toDouble(json['amount']),
    );
  }
}

class CategoryBreakdownItem {
  const CategoryBreakdownItem({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final String category;
  final double amount;
  final double percentage;

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItem(
      category: json['category'] as String? ?? 'Other',
      amount: _toDouble(json['amount']),
      percentage: _toDouble(json['percentage']),
    );
  }
}

class SpendingInsight {
  const SpendingInsight({
    required this.message,
    required this.category,
  });

  final String message;
  final String category;

  factory SpendingInsight.fromJson(Map<String, dynamic> json) {
    return SpendingInsight(
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

class MonthlyComparison {
  const MonthlyComparison({
    required this.total,
    required this.personal,
    required this.sharedLiving,
    required this.family,
  });

  final ComparisonMetric total;
  final ComparisonMetric personal;
  final ComparisonMetric sharedLiving;
  final ComparisonMetric family;

  factory MonthlyComparison.fromJson(Map<String, dynamic> json) {
    return MonthlyComparison(
      total: ComparisonMetric.fromJson(Map<String, dynamic>.from(json['total'] as Map)),
      personal: ComparisonMetric.fromJson(Map<String, dynamic>.from(json['personal'] as Map)),
      sharedLiving: ComparisonMetric.fromJson(Map<String, dynamic>.from(json['sharedLiving'] as Map)),
      family: ComparisonMetric.fromJson(Map<String, dynamic>.from(json['family'] as Map)),
    );
  }
}

class ExpenseDashboardResponse {
  const ExpenseDashboardResponse({
    required this.totalSpentThisMonth,
    required this.personalSpentThisMonth,
    required this.sharedLivingSpentThisMonth,
    required this.familySpentThisMonth,
    required this.monthlyTrend,
    required this.categoryBreakdown,
    required this.recentTransactions,
    required this.insights,
    required this.monthlyComparison,
  });

  final double totalSpentThisMonth;
  final double personalSpentThisMonth;
  final double sharedLivingSpentThisMonth;
  final double familySpentThisMonth;
  final List<MonthlyTrendPoint> monthlyTrend;
  final List<CategoryBreakdownItem> categoryBreakdown;
  final List<ExpenseResponse> recentTransactions;
  final List<SpendingInsight> insights;
  final MonthlyComparison monthlyComparison;

  factory ExpenseDashboardResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseDashboardResponse(
      totalSpentThisMonth: _toDouble(json['totalSpentThisMonth']),
      personalSpentThisMonth: _toDouble(json['personalSpentThisMonth']),
      sharedLivingSpentThisMonth: _toDouble(json['sharedLivingSpentThisMonth']),
      familySpentThisMonth: _toDouble(json['familySpentThisMonth']),
      monthlyTrend: (json['monthlyTrend'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => MonthlyTrendPoint.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => CategoryBreakdownItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => ExpenseResponse.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      insights: (json['insights'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => SpendingInsight.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      monthlyComparison: MonthlyComparison.fromJson(
        Map<String, dynamic>.from(json['monthlyComparison'] as Map),
      ),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
