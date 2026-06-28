package com.lifetracker.modules.learning.dto;

import com.lifetracker.modules.learning.enums.LearningPriority;
import com.lifetracker.modules.learning.enums.LearningStatus;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.time.LocalTime;

public record UpdateLearningRequest(
        @NotBlank String title,
        String description,
        String topic,
        String resourceType,
        String resourceUrl,
        @NotNull @Min(0) Integer plannedMinutes,
        @NotNull @Min(0) Integer completedMinutes,
        @NotNull LearningStatus status,
        @NotNull LearningPriority priority,
        LocalDate scheduledDate,
        LocalDate completedDate,
        LocalTime reminderTime,
        @NotNull Boolean notificationsEnabled,
        String colorHex,
        String iconName
) {
}
