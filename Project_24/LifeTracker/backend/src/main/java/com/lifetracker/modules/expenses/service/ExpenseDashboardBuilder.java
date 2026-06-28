package com.lifetracker.modules.expenses.service;

import com.lifetracker.modules.expenses.dto.CategoryBreakdownItem;
import com.lifetracker.modules.expenses.dto.ComparisonMetric;
import com.lifetracker.modules.expenses.dto.ExpenseDashboardResponse;
import com.lifetracker.modules.expenses.dto.ExpenseResponse;
import com.lifetracker.modules.expenses.dto.MonthlyComparison;
import com.lifetracker.modules.expenses.dto.MonthlyTrendPoint;
import com.lifetracker.modules.expenses.dto.SpendingInsight;
import com.lifetracker.modules.expenses.entity.Expense;
import com.lifetracker.modules.expenses.enums.ExpenseType;
import com.lifetracker.modules.expenses.mapper.ExpenseMapper;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Component
public class ExpenseDashboardBuilder {
    private static final List<String> DISPLAY_CATEGORIES = List.of(
            "Food",
            "Fitness",
            "Entertainment",
            "Shopping",
            "Medical",
            "Travel",
            "Parents",
            "Groceries",
            "Other"
    );

    private final ExpenseMapper expenseMapper;

    public ExpenseDashboardBuilder(ExpenseMapper expenseMapper) {
        this.expenseMapper = expenseMapper;
    }

    public ExpenseDashboardResponse build(List<Expense> expenses) {
        LocalDate today = LocalDate.now();
        YearMonth currentMonth = YearMonth.from(today);
        YearMonth previousMonth = currentMonth.minusMonths(1);

        BigDecimal personalThisMonth = sumForMonthAndType(expenses, currentMonth, ExpenseType.PERSONAL);
        BigDecimal sharedThisMonth = sumForMonthAndType(expenses, currentMonth, ExpenseType.SHARED_LIVING);
        BigDecimal familyThisMonth = sumForMonthAndType(expenses, currentMonth, ExpenseType.FAMILY);
        BigDecimal totalThisMonth = personalThisMonth.add(sharedThisMonth).add(familyThisMonth);

        BigDecimal personalLastMonth = sumForMonthAndType(expenses, previousMonth, ExpenseType.PERSONAL);
        BigDecimal sharedLastMonth = sumForMonthAndType(expenses, previousMonth, ExpenseType.SHARED_LIVING);
        BigDecimal familyLastMonth = sumForMonthAndType(expenses, previousMonth, ExpenseType.FAMILY);
        BigDecimal totalLastMonth = personalLastMonth.add(sharedLastMonth).add(familyLastMonth);

        return new ExpenseDashboardResponse(
                totalThisMonth,
                personalThisMonth,
                sharedThisMonth,
                familyThisMonth,
                buildMonthlyTrend(expenses, currentMonth),
                buildCategoryBreakdown(expenses, currentMonth),
                buildRecentTransactions(expenses),
                buildInsights(expenses, currentMonth, previousMonth),
                new MonthlyComparison(
                        compare(totalThisMonth, totalLastMonth),
                        compare(personalThisMonth, personalLastMonth),
                        compare(sharedThisMonth, sharedLastMonth),
                        compare(familyThisMonth, familyLastMonth)
                )
        );
    }

    private List<MonthlyTrendPoint> buildMonthlyTrend(List<Expense> expenses, YearMonth currentMonth) {
        List<MonthlyTrendPoint> trend = new ArrayList<>();
        for (int offset = 5; offset >= 0; offset--) {
            YearMonth month = currentMonth.minusMonths(offset);
            BigDecimal amount = sumForMonth(expenses, month);
            String label = month.getMonth().getDisplayName(TextStyle.SHORT, Locale.ENGLISH);
            trend.add(new MonthlyTrendPoint(label, month.getYear(), month.getMonthValue(), amount));
        }
        return trend;
    }

    private List<CategoryBreakdownItem> buildCategoryBreakdown(List<Expense> expenses, YearMonth month) {
        Map<String, BigDecimal> totals = new LinkedHashMap<>();
        for (String category : DISPLAY_CATEGORIES) {
            totals.put(category, BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP));
        }

        for (Expense expense : expenses) {
            if (!isInMonth(expense.getExpenseDate(), month)) {
                continue;
            }
            String normalized = normalizeCategory(expense.getCategory());
            totals.merge(normalized, expense.getAmount(), BigDecimal::add);
        }

        BigDecimal grandTotal = totals.values().stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        if (grandTotal.compareTo(BigDecimal.ZERO) == 0) {
            return DISPLAY_CATEGORIES.stream()
                    .map(category -> new CategoryBreakdownItem(category, BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP), 0.0))
                    .toList();
        }

        return DISPLAY_CATEGORIES.stream()
                .map(category -> {
                    BigDecimal amount = totals.get(category).setScale(2, RoundingMode.HALF_UP);
                    double percentage = amount
                            .multiply(BigDecimal.valueOf(100))
                            .divide(grandTotal, 2, RoundingMode.HALF_UP)
                            .doubleValue();
                    return new CategoryBreakdownItem(category, amount, percentage);
                })
                .filter(item -> item.amount().compareTo(BigDecimal.ZERO) > 0)
                .toList();
    }

    private List<ExpenseResponse> buildRecentTransactions(List<Expense> expenses) {
        return expenses.stream()
                .sorted(Comparator
                        .comparing(Expense::getExpenseDate).reversed()
                        .thenComparing(Expense::getId).reversed())
                .limit(10)
                .map(expenseMapper::toResponse)
                .toList();
    }

    private List<SpendingInsight> buildInsights(
            List<Expense> expenses,
            YearMonth currentMonth,
            YearMonth previousMonth
    ) {
        List<SpendingInsight> insights = new ArrayList<>();
        Map<String, BigDecimal> currentCategories = categoryTotalsForMonth(expenses, currentMonth);
        Map<String, BigDecimal> previousCategories = categoryTotalsForMonth(expenses, previousMonth);

        for (String category : DISPLAY_CATEGORIES) {
            BigDecimal current = currentCategories.getOrDefault(category, BigDecimal.ZERO);
            BigDecimal previous = previousCategories.getOrDefault(category, BigDecimal.ZERO);
            if (previous.compareTo(BigDecimal.ZERO) > 0 && current.compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal change = current.subtract(previous);
                BigDecimal percent = change
                        .multiply(BigDecimal.valueOf(100))
                        .divide(previous, 0, RoundingMode.HALF_UP);
                if (percent.abs().compareTo(BigDecimal.valueOf(5)) >= 0) {
                    String direction = change.compareTo(BigDecimal.ZERO) >= 0 ? "more" : "less";
                    insights.add(new SpendingInsight(
                            String.format(
                                    "You spent %s%% %s on %s compared to last month.",
                                    percent.abs(),
                                    direction,
                                    category
                            ),
                            category
                    ));
                }
            } else if (current.compareTo(BigDecimal.ZERO) > 0 && previous.compareTo(BigDecimal.ZERO) == 0) {
                insights.add(new SpendingInsight(
                        String.format("You spent ₹%s on %s this month.", formatAmount(current), category),
                        category
                ));
            }
        }

        BigDecimal sharedChange = sumForMonthAndType(expenses, currentMonth, ExpenseType.SHARED_LIVING)
                .subtract(sumForMonthAndType(expenses, previousMonth, ExpenseType.SHARED_LIVING));
        if (sharedChange.abs().compareTo(BigDecimal.valueOf(100)) >= 0) {
            String direction = sharedChange.compareTo(BigDecimal.ZERO) >= 0 ? "increased" : "decreased";
            insights.add(new SpendingInsight(
                    String.format("Shared Living %s by ₹%s.", direction, formatAmount(sharedChange.abs())),
                    "Shared Living"
            ));
        }

        BigDecimal familyCurrent = sumForMonthAndType(expenses, currentMonth, ExpenseType.FAMILY);
        BigDecimal familyPrevious = sumForMonthAndType(expenses, previousMonth, ExpenseType.FAMILY);
        if (familyCurrent.compareTo(BigDecimal.ZERO) > 0
                && familyPrevious.compareTo(BigDecimal.ZERO) > 0
                && familyCurrent.subtract(familyPrevious).abs().compareTo(BigDecimal.valueOf(200)) <= 0) {
            insights.add(new SpendingInsight("Family Support is consistent.", "Family Support"));
        }

        if (insights.isEmpty()) {
            insights.add(new SpendingInsight("Keep tracking your expenses to unlock richer insights.", "General"));
        }

        boolean hasFoodInsight = insights.stream().anyMatch(item -> "Food".equals(item.category()));
        if (!hasFoodInsight) {
            BigDecimal foodTotal = currentCategories.getOrDefault("Food", BigDecimal.ZERO);
            if (foodTotal.compareTo(BigDecimal.ZERO) > 0) {
                insights.add(new SpendingInsight(
                        String.format("You spent ₹%s on Outside Food.", formatAmount(foodTotal)),
                        "Food"
                ));
            }
        }

        return insights.stream().limit(6).collect(Collectors.toList());
    }

    private Map<String, BigDecimal> categoryTotalsForMonth(List<Expense> expenses, YearMonth month) {
        Map<String, BigDecimal> totals = new LinkedHashMap<>();
        for (Expense expense : expenses) {
            if (!isInMonth(expense.getExpenseDate(), month)) {
                continue;
            }
            String normalized = normalizeCategory(expense.getCategory());
            totals.merge(normalized, expense.getAmount(), BigDecimal::add);
        }
        return totals;
    }

    private ComparisonMetric compare(BigDecimal current, BigDecimal previous) {
        BigDecimal change = current.subtract(previous).setScale(2, RoundingMode.HALF_UP);
        Double percent = null;
        if (previous.compareTo(BigDecimal.ZERO) > 0) {
            percent = change.multiply(BigDecimal.valueOf(100))
                    .divide(previous, 1, RoundingMode.HALF_UP)
                    .doubleValue();
        } else if (current.compareTo(BigDecimal.ZERO) > 0) {
            percent = 100.0;
        } else {
            percent = 0.0;
        }
        return new ComparisonMetric(
                current.setScale(2, RoundingMode.HALF_UP),
                previous.setScale(2, RoundingMode.HALF_UP),
                change,
                percent
        );
    }

    private BigDecimal sumForMonth(List<Expense> expenses, YearMonth month) {
        return expenses.stream()
                .filter(expense -> isInMonth(expense.getExpenseDate(), month))
                .map(Expense::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal sumForMonthAndType(List<Expense> expenses, YearMonth month, ExpenseType type) {
        return expenses.stream()
                .filter(expense -> expense.getExpenseType() == type)
                .filter(expense -> isInMonth(expense.getExpenseDate(), month))
                .map(Expense::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);
    }

    private boolean isInMonth(LocalDate date, YearMonth month) {
        return YearMonth.from(date).equals(month);
    }

    String normalizeCategory(String category) {
        if (category == null || category.isBlank()) {
            return "Other";
        }
        String normalized = category.trim().toLowerCase(Locale.ENGLISH);
        if (normalized.contains("groc")) {
            return "Groceries";
        }
        if (normalized.contains("food") || normalized.contains("dining") || normalized.contains("restaurant")) {
            return "Food";
        }
        if (normalized.contains("fit") || normalized.contains("gym") || normalized.contains("sport")) {
            return "Fitness";
        }
        if (normalized.contains("entertain") || normalized.contains("movie") || normalized.contains("game")) {
            return "Entertainment";
        }
        if (normalized.contains("shop")) {
            return "Shopping";
        }
        if (normalized.contains("med") || normalized.contains("health") || normalized.contains("doctor")) {
            return "Medical";
        }
        if (normalized.contains("travel") || normalized.contains("trip")) {
            return "Travel";
        }
        if (normalized.contains("parent") || normalized.contains("family")) {
            return "Parents";
        }

        for (String displayCategory : DISPLAY_CATEGORIES) {
            if (displayCategory.equalsIgnoreCase(category.trim())) {
                return displayCategory;
            }
        }
        return "Other";
    }

    private String formatAmount(BigDecimal amount) {
        return amount.setScale(0, RoundingMode.HALF_UP).toPlainString();
    }
}
