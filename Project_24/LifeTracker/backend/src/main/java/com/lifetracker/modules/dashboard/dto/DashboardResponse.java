package com.lifetracker.modules.dashboard.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record DashboardResponse(
        LocalDate currentDate,
        String greeting,
        String userName,
        Summary summary,
        List<TodayHabit> todayHabits
) {
    public record Summary(
            int totalHabits,
            int completedHabits,
            int pendingHabits,
            BigDecimal completionPercentage,
            int currentStreak,
            int longestStreak
    ) {
    }

    public record TodayHabit(
            Long habitId,
            String habitName,
            String icon,
            String color,
            boolean completed,
            BigDecimal targetValue,
            BigDecimal currentValue
    ) {
    }
}
