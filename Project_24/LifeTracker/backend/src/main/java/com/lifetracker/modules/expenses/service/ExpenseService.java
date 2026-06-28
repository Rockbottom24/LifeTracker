package com.lifetracker.modules.expenses.service;

import com.lifetracker.modules.expenses.dto.CreateExpenseRequest;
import com.lifetracker.modules.expenses.dto.ExpenseDashboardResponse;
import com.lifetracker.modules.expenses.dto.ExpenseResponse;
import com.lifetracker.modules.expenses.dto.UpdateExpenseRequest;

import java.util.List;

public interface ExpenseService {
    List<ExpenseResponse> getAllExpenses();

    ExpenseDashboardResponse getDashboard();

    ExpenseResponse getExpenseById(Long id);

    ExpenseResponse createExpense(CreateExpenseRequest request);

    ExpenseResponse updateExpense(Long id, UpdateExpenseRequest request);

    void deleteExpense(Long id);
}
