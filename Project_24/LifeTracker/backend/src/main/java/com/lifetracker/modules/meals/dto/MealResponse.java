package com.lifetracker.modules.meals.dto;

import com.lifetracker.modules.meals.enums.MealType;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record MealResponse(
        Long id,
        UUID uuid,
        MealType mealType,
        LocalDate mealDate,
        String notes,
        List<MealItemResponse> items,
        BigDecimal totalCalories,
        BigDecimal totalProtein,
        BigDecimal totalCarbs,
        BigDecimal totalFat,
        BigDecimal totalFiber
) {
}
