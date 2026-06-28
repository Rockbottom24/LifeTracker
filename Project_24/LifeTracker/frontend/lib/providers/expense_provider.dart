import 'package:flutter/foundation.dart';

import '../models/create_expense_request.dart';
import '../models/expense_dashboard_response.dart';
import '../models/expense_response.dart';
import '../models/expense_type.dart';
import '../models/update_expense_request.dart';
import '../services/api_client.dart';
import '../services/expense_service.dart';
import '../utils/expense_summary_mapper.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._service);

  final ExpenseService _service;

  bool isLoading = false;
  bool isRefreshing = false;
  bool isDashboardLoading = false;
  bool isSaving = false;
  String? errorMessage;
  String? dashboardErrorMessage;
  List<ExpenseResponse> expenses = [];
  ExpenseDashboardResponse? dashboard;

  ExpenseTypeSummary summaryFor(ExpenseType type) {
    return ExpenseSummaryMapper.forType(expenses, type);
  }

  List<ExpenseResponse> expensesForType(ExpenseType type) {
    final filtered = expenses.where((expense) => expense.expenseType == type).toList();
    filtered.sort((a, b) {
      final dateCompare = b.expenseDate.compareTo(a.expenseDate);
      if (dateCompare != 0) return dateCompare;
      return b.id.compareTo(a.id);
    });
    return filtered;
  }

  ExpenseResponse? findExpenseById(int id) {
    for (final expense in expenses) {
      if (expense.id == id) return expense;
    }
    return null;
  }

  Future<void> refreshExpenseData() async {
    await Future.wait([loadExpenses(), loadDashboard()]);
  }

  Future<void> loadExpenses() async {
    final hadCachedData = expenses.isNotEmpty;
    isLoading = !hadCachedData;
    isRefreshing = hadCachedData;
    if (!hadCachedData) {
      errorMessage = null;
    }
    notifyListeners();

    try {
      expenses = await _service.getExpenses();
      errorMessage = null;
    } on ApiException catch (e) {
      if (expenses.isEmpty) {
        errorMessage = e.message;
      }
    } catch (e) {
      if (expenses.isEmpty) {
        errorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboard() async {
    final hadCachedData = dashboard != null;
    isDashboardLoading = !hadCachedData;
    notifyListeners();

    try {
      dashboard = await _service.getDashboard();
      dashboardErrorMessage = null;
    } on ApiException catch (e) {
      if (dashboard == null) {
        dashboardErrorMessage = e.message;
      }
    } catch (e) {
      if (dashboard == null) {
        dashboardErrorMessage = e.toString();
      }
    } finally {
      isDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<ExpenseResponse?> createExpense(CreateExpenseRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final expense = await _service.createExpense(request);
      expenses = [expense, ...expenses.where((item) => item.id != expense.id)];
      notifyListeners();
      await refreshExpenseData();
      return expense;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateExpense(int id, UpdateExpenseRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.updateExpense(id, request);
      expenses = expenses.map((expense) => expense.id == id ? updated : expense).toList();
      notifyListeners();
      await refreshExpenseData();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _service.deleteExpense(id);
      expenses = expenses.where((expense) => expense.id != id).toList();
      notifyListeners();
      await refreshExpenseData();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
