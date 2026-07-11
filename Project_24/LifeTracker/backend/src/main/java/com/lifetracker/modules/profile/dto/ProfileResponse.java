package com.lifetracker.modules.profile.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record ProfileResponse(
        Long userId,
        String email,
        String firstName,
        String houseKey,
        String houseDisplayName,
        String houseMotto,
        PerformanceSummary summary,
        List<DailyPerformanceSummary> recentDays
) {
    public record PerformanceSummary(
            int sevenDayHonor,
            BigDecimal sevenDayCompletionPercentage,
            int currentStreak,
            int longestStreak
    ) {
    }

    public record DailyPerformanceSummary(
            LocalDate date,
            int earnedPoints,
            int possiblePoints,
            BigDecimal completionPercentage,
            int completedHabits,
            int plannedHabits
    ) {
    }
}
