package com.lifetracker.modules.expenses.dto;

import java.math.BigDecimal;

public record ComparisonMetric(
        BigDecimal thisMonth,
        BigDecimal lastMonth,
        BigDecimal changeAmount,
        Double changePercent
) {
}
