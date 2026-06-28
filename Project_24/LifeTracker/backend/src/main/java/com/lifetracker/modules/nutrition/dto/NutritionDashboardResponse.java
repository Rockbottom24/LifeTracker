package com.lifetracker.modules.nutrition.dto;

import com.lifetracker.modules.meals.dto.MealResponse;

import java.time.LocalDate;
import java.util.List;

public record NutritionDashboardResponse(
        LocalDate date,
        NutritionGoalsResponse goals,
        List<MacroProgressItem> progress,
        List<String> insights,
        List<MealResponse> meals
) {
}
