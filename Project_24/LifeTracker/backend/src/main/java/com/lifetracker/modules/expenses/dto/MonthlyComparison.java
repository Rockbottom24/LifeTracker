package com.lifetracker.modules.expenses.dto;

import java.math.BigDecimal;
import java.util.List;

public record MonthlyComparison(
        ComparisonMetric total,
        ComparisonMetric personal,
        ComparisonMetric sharedLiving,
        ComparisonMetric family
) {
}
