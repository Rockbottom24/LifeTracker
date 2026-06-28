package com.lifetracker.modules.nutrition.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record UpdateNutritionGoalsRequest(
        @NotNull @DecimalMin("1") BigDecimal calorieGoal,
        @NotNull @DecimalMin("0") BigDecimal proteinGoal,
        @NotNull @DecimalMin("0") BigDecimal carbsGoal,
        @NotNull @DecimalMin("0") BigDecimal fatGoal,
        @NotNull @DecimalMin("0") BigDecimal fiberGoal
) {
}
