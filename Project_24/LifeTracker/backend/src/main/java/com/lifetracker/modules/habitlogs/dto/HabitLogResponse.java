package com.lifetracker.modules.habitlogs.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record HabitLogResponse(
        Long habitId,
        UUID habitUuid,
        String habitName,
        Long habitCategoryId,
        int displayOrder,
        boolean habitActive,
        Long habitLogId,
        UUID habitLogUuid,
        LocalDate logDate,
        LocalDateTime loggedAt,
        String completionStatus,
        boolean completed,
        BigDecimal value,
        String notes
) {
}
