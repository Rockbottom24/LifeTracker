package com.lifetracker.modules.habitlogs.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;

public record CompleteHabitRequest(
        @NotNull @Positive Long habitId,
        @DecimalMin(value = "0", inclusive = true) BigDecimal value,
        String notes
) {
}
