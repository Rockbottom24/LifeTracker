package com.lifetracker.modules.meals.dto;

import com.lifetracker.modules.meals.enums.MealType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.List;

public record UpdateMealRequest(
        @NotNull MealType mealType,
        @NotNull LocalDate mealDate,
        String notes,
        @NotEmpty @Valid List<MealItemRequest> items
) {
}
