package com.lifetracker.modules.habits.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

import com.lifetracker.modules.habits.enums.HabitFrequency;

public record HabitResponse(
        Long id,

        UUID uuid,

        String name,

        String description,

        HabitFrequency frequency,

        LocalDate startDate,

        LocalDate endDate,

        LocalTime reminderTime,

        Boolean notificationsEnabled,

        String iconName,

        String colorHex,

        Boolean isActive
) {
}
