package com.lifetracker.modules.expenses.mapper;

import com.lifetracker.modules.expenses.dto.CreateExpenseRequest;
import com.lifetracker.modules.expenses.dto.ExpenseResponse;
import com.lifetracker.modules.expenses.dto.UpdateExpenseRequest;
import com.lifetracker.modules.expenses.entity.Expense;
import com.lifetracker.modules.expenses.enums.ExpenseType;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Component
public class ExpenseMapper {

    public Expense toEntity(CreateExpenseRequest request, Long userId) {
        Expense expense = new Expense();
        expense.setUuid(UUID.randomUUID());
        applyCreateRequest(expense, request, userId);
        expense.setCreatedAt(LocalDateTime.now());
        expense.setUpdatedAt(LocalDateTime.now());
        return expense;
    }

    public void updateEntity(Expense expense, UpdateExpenseRequest request) {
        expense.setExpenseType(request.expenseType());
        expense.setCategory(request.category().trim());
        expense.setTitle(request.title().trim());
        expense.setDescription(normalizeNullableText(request.description()));
        expense.setAmount(request.amount());
        expense.setExpenseDate(request.expenseDate());
        expense.setPaymentMode(normalizeNullableText(request.paymentMode()));
        expense.setNotes(normalizeNullableText(request.notes()));
        expense.setUpdatedAt(LocalDateTime.now());
    }

    public ExpenseResponse toResponse(Expense expense) {
        return new ExpenseResponse(
                expense.getId(),
                expense.getUuid(),
                expense.getExpenseType(),
                expense.getCategory(),
                expense.getTitle(),
                expense.getDescription(),
                expense.getAmount(),
                expense.getExpenseDate(),
                expense.getPaymentMode(),
                expense.getNotes()
        );
    }

    public List<ExpenseResponse> toResponseList(List<Expense> expenses) {
        return expenses.stream().map(this::toResponse).toList();
    }

    private void applyCreateRequest(Expense expense, CreateExpenseRequest request, Long userId) {
        expense.setUserId(userId);
        expense.setExpenseType(request.expenseType() == null ? ExpenseType.PERSONAL : request.expenseType());
        expense.setCategory(request.category().trim());
        expense.setTitle(request.title().trim());
        expense.setDescription(normalizeNullableText(request.description()));
        expense.setAmount(request.amount());
        expense.setExpenseDate(request.expenseDate());
        expense.setPaymentMode(normalizeNullableText(request.paymentMode()));
        expense.setNotes(normalizeNullableText(request.notes()));
    }

    private String normalizeNullableText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
