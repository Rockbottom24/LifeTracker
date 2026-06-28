package com.lifetracker.modules.expenses.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.expenses.dto.CreateExpenseRequest;
import com.lifetracker.modules.expenses.dto.ExpenseDashboardResponse;
import com.lifetracker.modules.expenses.dto.ExpenseResponse;
import com.lifetracker.modules.expenses.dto.UpdateExpenseRequest;
import com.lifetracker.modules.expenses.entity.Expense;
import com.lifetracker.modules.expenses.mapper.ExpenseMapper;
import com.lifetracker.modules.expenses.repository.ExpenseRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Comparator;
import java.util.List;

@Service
@Transactional
public class ExpenseServiceImpl implements ExpenseService {
    private final ExpenseRepository expenseRepository;
    private final ExpenseMapper expenseMapper;
    private final ExpenseDashboardBuilder expenseDashboardBuilder;
    private final CurrentUserService currentUserService;

    public ExpenseServiceImpl(
            ExpenseRepository expenseRepository,
            ExpenseMapper expenseMapper,
            ExpenseDashboardBuilder expenseDashboardBuilder,
            CurrentUserService currentUserService
    ) {
        this.expenseRepository = expenseRepository;
        this.expenseMapper = expenseMapper;
        this.expenseDashboardBuilder = expenseDashboardBuilder;
        this.currentUserService = currentUserService;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ExpenseResponse> getAllExpenses() {
        List<Expense> expenses = expenseRepository.findByUserId(currentUserService.getCurrentUserId());
        expenses.sort(expenseComparator());
        return expenseMapper.toResponseList(expenses);
    }

    @Override
    @Transactional(readOnly = true)
    public ExpenseDashboardResponse getDashboard() {
        return expenseDashboardBuilder.build(expenseRepository.findByUserId(currentUserService.getCurrentUserId()));
    }

    @Override
    @Transactional(readOnly = true)
    public ExpenseResponse getExpenseById(Long id) {
        return expenseMapper.toResponse(findExpenseOrThrow(id));
    }

    @Override
    public ExpenseResponse createExpense(CreateExpenseRequest request) {
        Expense expense = expenseMapper.toEntity(request, currentUserService.getCurrentUserId());
        try {
            Expense saved = expenseRepository.save(expense);
            return expenseMapper.toResponse(saved);
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unable to create expense.", ex);
        }
    }

    @Override
    public ExpenseResponse updateExpense(Long id, UpdateExpenseRequest request) {
        Expense expense = findExpenseOrThrow(id);
        expenseMapper.updateEntity(expense, request);

        try {
            Expense saved = expenseRepository.saveAndFlush(expense);
            return expenseMapper.toResponse(saved);
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unable to update expense.", ex);
        }
    }

    @Override
    public void deleteExpense(Long id) {
        Expense expense = findExpenseOrThrow(id);
        try {
            expenseRepository.delete(expense);
            expenseRepository.flush();
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Expense cannot be deleted.", ex);
        }
    }

    private Expense findExpenseOrThrow(Long id) {
        return expenseRepository.findByIdAndUserId(id, currentUserService.getCurrentUserId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Expense not found"));
    }

    private Comparator<Expense> expenseComparator() {
        return Comparator
                .comparing(Expense::getExpenseDate, Comparator.nullsLast(Comparator.reverseOrder()))
                .thenComparing(Expense::getTitle, String.CASE_INSENSITIVE_ORDER)
                .thenComparing(Expense::getId);
    }
}
