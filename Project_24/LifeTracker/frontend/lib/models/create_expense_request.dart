import 'expense_type.dart';

class CreateExpenseRequest {
  const CreateExpenseRequest({
    required this.expenseType,
    required this.category,
    required this.title,
    this.description,
    required this.amount,
    required this.expenseDate,
    this.paymentMode,
    this.notes,
  });

  final ExpenseType expenseType;
  final String category;
  final String title;
  final String? description;
  final double amount;
  final DateTime expenseDate;
  final String? paymentMode;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
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

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;
}
