package com.lifetracker.modules.habits.dto;

import com.lifetracker.modules.habits.enums.HabitFrequency;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.time.LocalTime;

public record CreateHabitRequest(
        @NotNull Long habitCategoryId,
        @NotBlank String name,
        String description,
        @NotNull LocalDate startDate,
        LocalDate endDate,
        @NotNull HabitFrequency frequency,
        @NotNull LocalTime reminderTime,
        @NotNull Boolean notificationsEnabled,
        String iconName,
        String colorHex
) {
}
