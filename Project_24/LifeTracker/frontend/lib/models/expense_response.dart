import 'expense_type.dart';

class ExpenseResponse {
  const ExpenseResponse({
    required this.id,
    required this.uuid,
    required this.expenseType,
    required this.category,
    required this.title,
    this.description,
    required this.amount,
    required this.expenseDate,
    this.paymentMode,
    this.notes,
  });

  final int id;
  final String uuid;
  final ExpenseType expenseType;
  final String category;
  final String title;
  final String? description;
  final double amount;
  final DateTime expenseDate;
  final String? paymentMode;
  final String? notes;

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseResponse(
      id: _toInt(json['id']) ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      expenseType: ExpenseType.fromApiValue(json['expenseType']?.toString()),
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      amount: _toDouble(json['amount']),
      expenseDate: _parseDate(json['expenseDate']) ?? DateTime.now(),
      paymentMode: json['paymentMode'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'expenseType': expenseType.apiValue,
      'category': category,
      'title': title,
      'description': description,
      'amount': amount,
      'expenseDate': _formatDate(expenseDate),
      'paymentMode': paymentMode,
      'notes': notes,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
