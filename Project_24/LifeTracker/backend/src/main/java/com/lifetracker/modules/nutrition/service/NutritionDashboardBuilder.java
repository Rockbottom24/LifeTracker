package com.lifetracker.modules.nutrition.service;

import com.lifetracker.modules.meals.dto.MealResponse;
import com.lifetracker.modules.nutrition.dto.MacroProgressItem;
import com.lifetracker.modules.nutrition.dto.NutritionDashboardResponse;
import com.lifetracker.modules.nutrition.dto.NutritionGoalsResponse;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Component
public class NutritionDashboardBuilder {
    private final NutritionInsightsBuilder insightsBuilder;

    public NutritionDashboardBuilder(NutritionInsightsBuilder insightsBuilder) {
        this.insightsBuilder = insightsBuilder;
    }

    public NutritionDashboardResponse build(
            LocalDate date,
            NutritionGoalsResponse goals,
            List<MealResponse> meals
    ) {
        BigDecimal calories = sum(meals, MealResponse::totalCalories);
        BigDecimal protein = sum(meals, MealResponse::totalProtein);
        BigDecimal carbs = sum(meals, MealResponse::totalCarbs);
        BigDecimal fat = sum(meals, MealResponse::totalFat);
        BigDecimal fiber = sum(meals, MealResponse::totalFiber);

        List<MacroProgressItem> progress = List.of(
                buildProgress("CALORIES", "Calories", calories, goals.calorieGoal(), "kcal"),
                buildProgress("PROTEIN", "Protein", protein, goals.proteinGoal(), "g"),
                buildProgress("CARBS", "Carbohydrates", carbs, goals.carbsGoal(), "g"),
                buildProgress("FAT", "Fat", fat, goals.fatGoal(), "g"),
                buildProgress("FIBER", "Fiber", fiber, goals.fiberGoal(), "g")
        );

        List<String> insights = insightsBuilder.build(goals, progress, meals);

        return new NutritionDashboardResponse(date, goals, progress, insights, meals);
    }

    private MacroProgressItem buildProgress(
            String key,
            String label,
            BigDecimal consumed,
            BigDecimal goal,
            String unitSuffix
    ) {
        BigDecimal safeGoal = goal.compareTo(BigDecimal.ZERO) <= 0 ? BigDecimal.ONE : goal;
        BigDecimal remaining = safeGoal.subtract(consumed).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
        double progressPercent = consumed
                .multiply(BigDecimal.valueOf(100))
                .divide(safeGoal, 2, RoundingMode.HALF_UP)
                .doubleValue();

        return new MacroProgressItem(
                key,
                label + (unitSuffix.equals("kcal") ? "" : ""),
                consumed.setScale(2, RoundingMode.HALF_UP),
                goal.setScale(2, RoundingMode.HALF_UP),
                remaining,
                progressPercent
        );
    }

    private BigDecimal sum(List<MealResponse> meals, java.util.function.Function<MealResponse, BigDecimal> extractor) {
        return meals.stream()
                .map(extractor)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);
    }
}
