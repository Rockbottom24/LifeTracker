package com.lifetracker.modules.nutrition.dto;

import java.math.BigDecimal;

public record NutritionGoalsResponse(
        BigDecimal calorieGoal,
        BigDecimal proteinGoal,
        BigDecimal carbsGoal,
        BigDecimal fatGoal,
        BigDecimal fiberGoal
) {
}
