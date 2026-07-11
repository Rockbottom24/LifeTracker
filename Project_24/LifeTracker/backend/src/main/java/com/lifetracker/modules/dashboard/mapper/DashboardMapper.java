package com.lifetracker.modules.dashboard.mapper;

import com.lifetracker.modules.dashboard.dto.DashboardResponse;
import com.lifetracker.modules.habitlogs.entity.HabitLog;
import com.lifetracker.modules.habits.entity.Habit;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Component
public class DashboardMapper {
    private static final String[] ICONS = {
            "check_circle",
            "repeat",
            "timer",
            "water_drop",
            "local_fire_department",
            "self_improvement",
            "menu_book",
            "fitness_center"
    };

    private static final String[] COLORS = {
            "#2563EB",
            "#16A34A",
            "#F97316",
            "#7C3AED",
            "#0F766E",
            "#DC2626",
            "#334155",
            "#DB2777"
    };

    public DashboardResponse toResponse(
            LocalDate currentDate,
            String greeting,
            String userName,
            String firstName,
            String houseKey,
            String houseDisplayName,
            String welcomeTitle,
            String welcomeSubtitle,
            String dayStatusMessage,
            DashboardResponse.Summary summary,
            List<DashboardResponse.TodayHabit> todayHabits
    ) {
        return new DashboardResponse(
                currentDate,
                greeting,
                userName,
                firstName,
                houseKey,
                houseDisplayName,
                welcomeTitle,
                welcomeSubtitle,
                dayStatusMessage,
                summary,
                todayHabits
        );
    }

    public DashboardResponse.Summary toSummary(
            int totalHabits,
            int completedHabits,
            int pendingHabits,
            BigDecimal completionPercentage,
            int currentStreak,
            int longestStreak,
            int earnedPoints,
            int possiblePoints
    ) {
        return new DashboardResponse.Summary(
                totalHabits,
                completedHabits,
                pendingHabits,
                normalizePercentage(completionPercentage),
                currentStreak,
                longestStreak,
                earnedPoints,
                possiblePoints
        );
    }

    public DashboardResponse.TodayHabit toTodayHabit(Habit habit, HabitLog habitLog) {
        boolean completed = habitLog != null && "completed".equalsIgnoreCase(habitLog.getCompletionStatus());
        int pointsAwarded = completed && habitLog != null ? habitLog.getPointsAwarded() : 0;
        return new DashboardResponse.TodayHabit(
                habit.getId(),
                habit.getName(),
                pickIcon(habit),
                pickColor(habit),
                completed,
                BigDecimal.ONE,
                habitLog == null || habitLog.getValue() == null ? BigDecimal.ZERO : habitLog.getValue(),
                habit.getPoints(),
                pointsAwarded
        );
    }

    private BigDecimal normalizePercentage(BigDecimal completionPercentage) {
        return completionPercentage == null ? BigDecimal.ZERO : completionPercentage;
    }

    private String pickIcon(Habit habit) {
        return ICONS[Math.floorMod(habit.getId().hashCode(), ICONS.length)];
    }

    private String pickColor(Habit habit) {
        return COLORS[Math.floorMod(habit.getId().hashCode(), COLORS.length)];
    }
}
