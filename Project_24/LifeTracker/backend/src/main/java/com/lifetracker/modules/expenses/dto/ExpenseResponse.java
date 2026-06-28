package com.lifetracker.modules.expenses.dto;

import com.lifetracker.modules.expenses.enums.ExpenseType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record ExpenseResponse(
        Long id,
        UUID uuid,
        ExpenseType expenseType,
        String category,
        String title,
        String description,
        BigDecimal amount,
        LocalDate expenseDate,
        String paymentMode,
        String notes
) {
}
