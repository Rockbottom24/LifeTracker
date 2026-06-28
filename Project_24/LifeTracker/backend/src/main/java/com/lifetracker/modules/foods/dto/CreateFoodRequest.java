package com.lifetracker.modules.foods.dto;

import com.lifetracker.modules.foods.enums.FoodCategory;
import com.lifetracker.modules.foods.enums.ServingUnit;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record CreateFoodRequest(
        @NotBlank String name,
        @NotNull FoodCategory category,
        @NotNull ServingUnit servingUnit,
        @NotNull @DecimalMin("0") BigDecimal referenceQuantity,
        @NotNull @DecimalMin("0") BigDecimal referenceWeight,
        @NotNull @DecimalMin("0") BigDecimal calories,
        @NotNull @DecimalMin("0") BigDecimal protein,
        @NotNull @DecimalMin("0") BigDecimal carbs,
        @NotNull @DecimalMin("0") BigDecimal fat,
        @NotNull @DecimalMin("0") BigDecimal fiber,
        String barcode,
        String brand,
        String imageUrl,
        String source
) {
}
