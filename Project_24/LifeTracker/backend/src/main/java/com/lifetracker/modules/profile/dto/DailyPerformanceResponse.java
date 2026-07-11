package com.lifetracker.modules.profile.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record DailyPerformanceResponse(
        LocalDate date,
        int earnedPoints,
        int possiblePoints,
        BigDecimal completionPercentage,
        int completedHabits,
        int plannedHabits,
        List<HabitPerformanceItem> habits,
        NutritionPerformance nutrition
) {
    public record HabitPerformanceItem(
            Long habitId,
            String habitName,
            boolean completed,
            int configuredPoints,
            int pointsAwarded
    ) {
    }

    public record NutritionPerformance(
            BigDecimal calories,
            BigDecimal calorieGoal,
            BigDecimal protein,
            BigDecimal carbs,
            BigDecimal fat,
            BigDecimal fiber,
            List<MealPerformanceItem> meals
    ) {
    }

    public record MealPerformanceItem(
            Long mealId,
            String mealType,
            BigDecimal calories,
            BigDecimal protein,
            BigDecimal carbs,
            BigDecimal fat,
            BigDecimal fiber
    ) {
    }
}
