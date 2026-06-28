import '../models/create_expense_request.dart';
import '../models/expense_dashboard_response.dart';
import '../models/expense_response.dart';
import '../models/update_expense_request.dart';
import 'api_client.dart';

class ExpenseService {
  ExpenseService({required this._apiClient});

  final ApiClient _apiClient;

  Future<List<ExpenseResponse>> getExpenses() async {
    return _apiClient.get<List<ExpenseResponse>>(
      '/expenses',
      parser: _parseExpenseList,
    );
  }

  Future<ExpenseDashboardResponse> getDashboard() async {
    return _apiClient.get<ExpenseDashboardResponse>(
      '/expenses/dashboard',
      parser: (data) => ExpenseDashboardResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ExpenseResponse> getExpense(int id) async {
    return _apiClient.get<ExpenseResponse>(
      '/expenses/$id',
      parser: _parseExpense,
    );
  }

  Future<ExpenseResponse> createExpense(CreateExpenseRequest request) async {
    return _apiClient.post<ExpenseResponse>(
      '/expenses',
      data: request.toJson(),
      parser: _parseExpense,
    );
  }

  Future<ExpenseResponse> updateExpense(int id, UpdateExpenseRequest request) async {
    return _apiClient.put<ExpenseResponse>(
      '/expenses/$id',
      data: request.toJson(),
      parser: _parseExpense,
    );
  }

  Future<void> deleteExpense(int id) async {
    await _apiClient.delete<void>(
      '/expenses/$id',
      parser: (_) {},
    );
  }

  List<ExpenseResponse> _parseExpenseList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => ExpenseResponse.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  ExpenseResponse _parseExpense(dynamic data) {
    return ExpenseResponse.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
