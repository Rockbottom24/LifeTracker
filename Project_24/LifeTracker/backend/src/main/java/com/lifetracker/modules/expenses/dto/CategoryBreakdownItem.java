package com.lifetracker.modules.expenses.dto;

import java.math.BigDecimal;

public record CategoryBreakdownItem(
        String category,
        BigDecimal amount,
        Double percentage
) {
}
