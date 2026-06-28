package com.lifetracker.modules.meals.dto;

import com.lifetracker.modules.foods.enums.ServingUnit;

import java.math.BigDecimal;

public record MealItemResponse(
        Long id,
        Long foodItemId,
        String foodName,
        BigDecimal quantity,
        ServingUnit unit,
        BigDecimal calories,
        BigDecimal protein,
        BigDecimal carbs,
        BigDecimal fat,
        BigDecimal fiber,
        int displayOrder
) {
}
