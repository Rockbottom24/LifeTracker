package com.lifetracker.modules.expenses.dto;

import com.lifetracker.modules.expenses.enums.ExpenseType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CreateExpenseRequest(
        @NotNull ExpenseType expenseType,
        @NotBlank String category,
        @NotBlank String title,
        String description,
        @NotNull @DecimalMin("0.01") BigDecimal amount,
        @NotNull LocalDate expenseDate,
        String paymentMode,
        String notes
) {
}
