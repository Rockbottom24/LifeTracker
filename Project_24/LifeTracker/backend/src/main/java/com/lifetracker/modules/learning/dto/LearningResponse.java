package com.lifetracker.modules.learning.dto;

import com.lifetracker.modules.learning.enums.LearningPriority;
import com.lifetracker.modules.learning.enums.LearningStatus;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

public record LearningResponse(
        Long id,
        UUID uuid,
        String title,
        String description,
        String topic,
        String resourceType,
        String resourceUrl,
        Integer plannedMinutes,
        Integer completedMinutes,
        LearningStatus status,
        LearningPriority priority,
        LocalDate scheduledDate,
        LocalDate completedDate,
        LocalTime reminderTime,
        Boolean notificationsEnabled,
        String colorHex,
        String iconName,
        Integer displayOrder
) {
}
