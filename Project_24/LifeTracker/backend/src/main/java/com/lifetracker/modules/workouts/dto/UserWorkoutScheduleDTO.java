package com.lifetracker.modules.workouts.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record UserWorkoutScheduleDTO(
        Long id,
        UUID uuid,
        LocalDate scheduledDate,
        WorkoutTemplateDTO template,
        String customTitle,
        String status, // PLANNED, COMPLETED, MISSED, REST
        LocalDateTime completedAt,
        String notes
) {}
