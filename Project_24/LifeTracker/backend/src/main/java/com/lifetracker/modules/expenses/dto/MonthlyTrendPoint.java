package com.lifetracker.modules.expenses.dto;

import java.math.BigDecimal;

public record MonthlyTrendPoint(
        String monthLabel,
        int year,
        int month,
        BigDecimal amount
) {
}
