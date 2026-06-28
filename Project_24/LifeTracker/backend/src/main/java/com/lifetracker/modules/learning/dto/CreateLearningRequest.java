package com.lifetracker.modules.learning.dto;

import com.lifetracker.modules.learning.enums.LearningPriority;
import com.lifetracker.modules.learning.enums.LearningStatus;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.time.LocalTime;

public record CreateLearningRequest(
        @NotBlank String title,
        String description,
        String topic,
        String resourceType,
        String resourceUrl,
        @NotNull @Min(1) Integer plannedMinutes,
        @NotNull LearningStatus status,
        @NotNull LearningPriority priority,
        LocalDate scheduledDate,
        LocalTime reminderTime,
        @NotNull Boolean notificationsEnabled,
        String colorHex,
        String iconName
) {
}
