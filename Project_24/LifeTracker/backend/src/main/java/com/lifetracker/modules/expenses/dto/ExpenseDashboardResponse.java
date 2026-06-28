package com.lifetracker.modules.expenses.dto;

import java.math.BigDecimal;
import java.util.List;

public record ExpenseDashboardResponse(
        BigDecimal totalSpentThisMonth,
        BigDecimal personalSpentThisMonth,
        BigDecimal sharedLivingSpentThisMonth,
        BigDecimal familySpentThisMonth,
        List<MonthlyTrendPoint> monthlyTrend,
        List<CategoryBreakdownItem> categoryBreakdown,
        List<ExpenseResponse> recentTransactions,
        List<SpendingInsight> insights,
        MonthlyComparison monthlyComparison
) {
}
