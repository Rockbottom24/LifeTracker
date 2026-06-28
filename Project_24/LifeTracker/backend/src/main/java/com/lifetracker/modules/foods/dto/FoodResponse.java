package com.lifetracker.modules.foods.dto;

import com.lifetracker.modules.foods.enums.FoodCategory;
import com.lifetracker.modules.foods.enums.ServingUnit;

import java.math.BigDecimal;
import java.util.UUID;

public record FoodResponse(
        Long id,
        UUID uuid,
        String name,
        FoodCategory category,
        ServingUnit servingUnit,
        BigDecimal referenceQuantity,
        BigDecimal referenceWeight,
        BigDecimal calories,
        BigDecimal protein,
        BigDecimal carbs,
        BigDecimal fat,
        BigDecimal fiber,
        boolean system,
        String barcode,
        String brand,
        String imageUrl,
        String source
) {
}
