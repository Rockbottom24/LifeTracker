import '../models/expense_response.dart';
import '../models/expense_type.dart';

class ExpenseTypeSummary {
  const ExpenseTypeSummary({
    required this.totalAmount,
    required this.transactionCount,
    this.latestExpense,
  });

  final double totalAmount;
  final int transactionCount;
  final ExpenseResponse? latestExpense;

  static ExpenseTypeSummary empty() {
    return const ExpenseTypeSummary(totalAmount: 0, transactionCount: 0);
  }
}

class ExpenseSummaryMapper {
  static ExpenseTypeSummary forType(List<ExpenseResponse> expenses, ExpenseType type) {
    final filtered = expenses.where((expense) => expense.expenseType == type).toList();
    if (filtered.isEmpty) {
      return ExpenseTypeSummary.empty();
    }

    filtered.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    final total = filtered.fold<double>(0, (sum, expense) => sum + expense.amount);

    return ExpenseTypeSummary(
      totalAmount: total,
      transactionCount: filtered.length,
      latestExpense: filtered.first,
    );
  }
}
