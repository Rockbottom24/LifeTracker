import '../models/expense_response.dart';
import '../models/expense_type.dart';
import '../navigation/fade_slide_page_route.dart';
import '../screens/add_expense_screen.dart';

class AddExpensePageRoute extends FadeSlidePageRoute<void> {
  AddExpensePageRoute({
    required super.settings,
    required this.expenseType,
    this.expense,
  }) : super(page: AddExpenseScreen(expenseType: expenseType, expense: expense));

  final ExpenseType expenseType;
  final ExpenseResponse? expense;
}
