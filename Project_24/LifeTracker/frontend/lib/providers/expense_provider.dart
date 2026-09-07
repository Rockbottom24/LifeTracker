import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/expense_form_options.dart';
import '../models/create_expense_request.dart';
import '../models/expense_dashboard_response.dart';
import '../models/expense_response.dart';
import '../models/expense_type.dart';
import '../models/money_lent_item.dart';
import '../models/update_expense_request.dart';
import '../services/api_client.dart';
import '../services/expense_service.dart';
import '../utils/expense_summary_mapper.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._service) {
    loadExpenses();
  }

  final ExpenseService _service;

  bool isLoading = false;
  bool isRefreshing = false;
  bool isDashboardLoading = false;
  bool isSaving = false;
  String? errorMessage;
  String? dashboardErrorMessage;
  List<ExpenseResponse> expenses = [];
  ExpenseDashboardResponse? dashboard;
  double monthlyIncome = 0.0;
  double targetSalary = 2000000.0; // Default ₹20 LPA target
  double currentSalary = 600000.0; // Default TCS baseline
  List<MoneyLentItem> moneyLentList = [];
  List<String> categories = List.from(ExpenseFormOptions.categories);

  Future<bool> addCategory(String categoryName) async {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty) return false;
    if (categories.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      return false;
    }
    categories = [...categories, trimmed];
    await _saveCategoriesToDisk();
    notifyListeners();
    return true;
  }

  Future<bool> removeCategory(String categoryName) async {
    final trimmed = categoryName.trim();
    if (categories.length <= 1) return false;
    categories = categories.where((c) => c.toLowerCase() != trimmed.toLowerCase()).toList();
    await _saveCategoriesToDisk();
    notifyListeners();
    return true;
  }

  Future<void> _loadCategoriesFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('user_custom_expense_categories_v1');
      if (saved != null && saved.isNotEmpty) {
        categories = saved;
      }
    } catch (e) {
      debugPrint('Error loading expense categories from disk: $e');
    }
  }

  Future<void> _saveCategoriesToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_custom_expense_categories_v1', categories);
    } catch (e) {
      debugPrint('Error saving expense categories to disk: $e');
    }
  }

  double get totalSpentThisMonth {
    final now = DateTime.now();
    return expenses
        .where((e) => e.expenseDate.month == now.month && e.expenseDate.year == now.year)
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  double get totalOutstandingLent {
    return moneyLentList
        .where((item) => !item.isReceived)
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  double get remainingVaultBalance => monthlyIncome - totalSpentThisMonth - totalOutstandingLent;

  Future<void> setTargetSalary(double current, double target) async {
    currentSalary = current;
    targetSalary = target;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('iron_bank_current_salary', current);
      await prefs.setDouble('iron_bank_target_salary', target);
    } catch (e) {
      debugPrint('Error saving target salary: $e');
    }
    notifyListeners();
  }

  Future<void> setMonthlyIncome(double amount) async {
    monthlyIncome = amount;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('iron_bank_monthly_income', amount);
    } catch (e) {
      debugPrint('Error saving monthly income: $e');
    }
    _loadDashboardInBackground();
    notifyListeners();
  }

  Future<void> addMoneyLent(String personName, double amount, {String? notes}) async {
    final newItem = MoneyLentItem(
      id: DateTime.now().millisecondsSinceEpoch,
      personName: personName.trim(),
      amount: amount,
      date: DateTime.now(),
      notes: notes?.trim(),
      isReceived: false,
    );
    moneyLentList = [newItem, ...moneyLentList];
    await _saveMoneyLentToDisk();
    _loadDashboardInBackground();
    notifyListeners();
  }

  Future<void> markMoneyReceived(int id) async {
    moneyLentList = moneyLentList.map((item) {
      if (item.id == id) {
        return item.copyWith(
          isReceived: true,
          receivedAt: DateTime.now(),
        );
      }
      return item;
    }).toList();
    await _saveMoneyLentToDisk();
    _loadDashboardInBackground();
    notifyListeners();
  }

  Future<void> deleteMoneyLent(int id) async {
    moneyLentList = moneyLentList.where((item) => item.id != id).toList();
    await _saveMoneyLentToDisk();
    _loadDashboardInBackground();
    notifyListeners();
  }

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
    isLoading = false;
    isRefreshing = false;
    errorMessage = null;
    await _loadExpensesFromDisk();
    notifyListeners();

    _loadExpensesInBackground();
  }

  Future<void> _loadExpensesFromDisk() async {
    try {
      await _loadCategoriesFromDisk();
      final prefs = await SharedPreferences.getInstance();
      monthlyIncome = prefs.getDouble('iron_bank_monthly_income') ?? 0.0;
      currentSalary = prefs.getDouble('iron_bank_current_salary') ?? 600000.0;
      targetSalary = prefs.getDouble('iron_bank_target_salary') ?? 2000000.0;
      final lentRaw = prefs.getString('iron_bank_money_lent_v1');
      if (lentRaw != null && lentRaw.isNotEmpty) {
        final List list = jsonDecode(lentRaw);
        moneyLentList = list.map((item) => MoneyLentItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
      final jsonStr = prefs.getString('offline_user_expenses_store_v1');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        expenses = list.map((e) => ExpenseResponse.fromJson(e as Map<String, dynamic>)).toList();
        _loadDashboardInBackground();
      }
    } catch (e) {
      debugPrint('Error loading expenses from disk: $e');
    }
  }

  Future<void> _saveMoneyLentToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = moneyLentList.map((item) => item.toJson()).toList();
      await prefs.setString('iron_bank_money_lent_v1', jsonEncode(listMap));
    } catch (e) {
      debugPrint('Error saving money lent list to disk: $e');
    }
  }

  Future<void> _saveExpensesToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = expenses.map((e) => e.toJson()).toList();
      await prefs.setString('offline_user_expenses_store_v1', jsonEncode(listMap));
    } catch (e) {
      debugPrint('Error saving expenses to disk: $e');
    }
  }

  void _loadExpensesInBackground() async {
    try {
      final serverExpenses = await _service.getExpenses();
      expenses = serverExpenses;
      errorMessage = null;
      await _saveExpensesToDisk();
      notifyListeners();
    } catch (_) {
      // Ignore errors when background fetching, keep existing local data
    }
  }

  Future<void> loadDashboard() async {
    isDashboardLoading = false;
    dashboardErrorMessage = null;
    notifyListeners();

    _loadDashboardInBackground();
  }

  void _loadDashboardInBackground() async {
    try {
      final serverDashboard = await _service.getDashboard();
      dashboard = serverDashboard;
      dashboardErrorMessage = null;
      notifyListeners();
    } catch (_) {
      // Calculate real local dashboard from local expenses list
      final now = DateTime.now();
      final thisMonthExpenses = expenses.where((e) => e.expenseDate.month == now.month && e.expenseDate.year == now.year).toList();
      final lastMonthDate = DateTime(now.year, now.month - 1, 1);
      final lastMonthExpenses = expenses.where((e) => e.expenseDate.month == lastMonthDate.month && e.expenseDate.year == lastMonthDate.year).toList();

      final totalThisMonth = thisMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      final totalLastMonth = lastMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      final personal = thisMonthExpenses.where((e) => e.expenseType == ExpenseType.personal).fold<double>(0, (sum, e) => sum + e.amount);
      final family = thisMonthExpenses.where((e) => e.expenseType == ExpenseType.family).fold<double>(0, (sum, e) => sum + e.amount);

      // ── Category Breakdown ──────────────────────────────────────────
      final catMap = <String, double>{};
      for (final e in expenses) {
        final cat = (e.category.isEmpty) ? 'Other' : e.category;
        catMap[cat] = (catMap[cat] ?? 0) + e.amount;
      }
      final allTotalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final categoryBreakdown = catMap.entries.map((entry) {
        final pct = allTotalSpent > 0 ? (entry.value / allTotalSpent * 100) : 0.0;
        return CategoryBreakdownItem(
          category: entry.key,
          amount: entry.value,
          percentage: double.parse(pct.toStringAsFixed(1)),
        );
      }).toList();
      categoryBreakdown.sort((a, b) => b.amount.compareTo(a.amount));

      // ── Monthly Trend (Last 6 Months) ────────────────────────────────
      final monthlyTrend = <MonthlyTrendPoint>[];
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (var i = 5; i >= 0; i--) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final monthTotal = expenses
            .where((e) => e.expenseDate.month == targetDate.month && e.expenseDate.year == targetDate.year)
            .fold<double>(0, (sum, e) => sum + e.amount);
        monthlyTrend.add(MonthlyTrendPoint(
          monthLabel: monthNames[targetDate.month - 1],
          year: targetDate.year,
          month: targetDate.month,
          amount: monthTotal,
        ));
      }

      // ── Insights ──────────────────────────────────────────────────
      final insights = <SpendingInsight>[];
      if (categoryBreakdown.isNotEmpty) {
        final topCat = categoryBreakdown.first;
        insights.add(SpendingInsight(
          message: '${topCat.category} is your highest spending category (${topCat.percentage}%)',
          category: topCat.category,
        ));
      }

      ComparisonMetric makeMetric(double cur, double prev) {
        final diff = cur - prev;
        final pct = prev > 0 ? (diff / prev * 100) : 0.0;
        return ComparisonMetric(
          thisMonth: cur,
          lastMonth: prev,
          changeAmount: diff,
          changePercent: double.parse(pct.toStringAsFixed(1)),
        );
      }

      dashboard = ExpenseDashboardResponse(
        totalSpentThisMonth: totalThisMonth,
        personalSpentThisMonth: personal,
        familySpentThisMonth: family,
        monthlyTrend: monthlyTrend,
        categoryBreakdown: categoryBreakdown,
        recentTransactions: expenses.take(10).toList(),
        insights: insights,
        monthlyComparison: MonthlyComparison(
          total: makeMetric(totalThisMonth, totalLastMonth),
          personal: makeMetric(personal, lastMonthExpenses.where((e) => e.expenseType == ExpenseType.personal).fold(0, (s, e) => s + e.amount)),
          family: makeMetric(family, lastMonthExpenses.where((e) => e.expenseType == ExpenseType.family).fold(0, (s, e) => s + e.amount)),
        ),
      );
      notifyListeners();
    }
  }

  Future<ExpenseResponse?> createExpense(CreateExpenseRequest request) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final localId = DateTime.now().millisecondsSinceEpoch;
      final localExpense = ExpenseResponse(
        id: localId,
        uuid: 'local-$localId',
        title: request.title,
        amount: request.amount,
        expenseType: request.expenseType,
        category: request.category,
        expenseDate: request.expenseDate,
        notes: request.notes,
      );

      expenses = [localExpense, ...expenses];
      await _saveExpensesToDisk();
      notifyListeners();
      _loadDashboardInBackground();

      _service.createExpense(request).catchError((_) => localExpense);
      return localExpense;
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
      expenses = expenses.map((expense) {
        if (expense.id == id) {
          return ExpenseResponse(
            id: expense.id,
            uuid: expense.uuid,
            title: request.title,
            amount: request.amount,
            expenseType: request.expenseType,
            category: request.category,
            expenseDate: request.expenseDate,
            notes: request.notes,
          );
        }
        return expense;
      }).toList();
      await _saveExpensesToDisk();
      notifyListeners();
      _loadDashboardInBackground();

      _service.updateExpense(id, request).catchError((_) => expenses.first);
      return true;
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
    expenses = expenses.where((expense) => expense.id != id).toList();
    await _saveExpensesToDisk();
    notifyListeners();
    _loadDashboardInBackground();

    _service.deleteExpense(id).catchError((_) {});
    return true;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
