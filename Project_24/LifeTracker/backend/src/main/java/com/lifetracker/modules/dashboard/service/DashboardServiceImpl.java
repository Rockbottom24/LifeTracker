package com.lifetracker.modules.dashboard.service;

import com.lifetracker.modules.auth.entity.AppUser;
import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.dashboard.dto.DashboardResponse;
import com.lifetracker.modules.dashboard.mapper.DashboardMapper;
import com.lifetracker.modules.habitlogs.entity.HabitLog;
import com.lifetracker.modules.habitlogs.repository.HabitLogRepository;
import com.lifetracker.modules.habits.entity.Habit;
import com.lifetracker.modules.habits.repository.HabitRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class DashboardServiceImpl implements DashboardService {
    private static final BigDecimal PERCENT_SCALE = BigDecimal.valueOf(100);

    private final HabitRepository habitRepository;
    private final HabitLogRepository habitLogRepository;
    private final DashboardMapper dashboardMapper;
    private final CurrentUserService currentUserService;

    public DashboardServiceImpl(
            HabitRepository habitRepository,
            HabitLogRepository habitLogRepository,
            DashboardMapper dashboardMapper,
            CurrentUserService currentUserService
    ) {
        this.habitRepository = habitRepository;
        this.habitLogRepository = habitLogRepository;
        this.dashboardMapper = dashboardMapper;
        this.currentUserService = currentUserService;
    }

    @Override
    public DashboardResponse getDashboard() {
        LocalDate currentDate = currentDate();
        LocalDateTime startOfDay = currentDate.atStartOfDay();
        LocalDateTime startOfNextDay = currentDate.plusDays(1).atStartOfDay();

        List<Habit> activeHabits = habitRepository.findAllByUserIdAndActiveTrue(currentUserService.getCurrentUserId());
        activeHabits.sort(habitComparator());

        List<Long> activeHabitIds = activeHabits.stream()
                .map(Habit::getId)
                .toList();

        List<HabitLog> todayLogs = activeHabitIds.isEmpty()
                ? List.of()
                : habitLogRepository.findByHabitIdInAndLoggedAtBetweenOrderByLoggedAtDescIdDesc(activeHabitIds, startOfDay, startOfNextDay);

        Map<Long, HabitLog> latestTodayLogs = latestLogsByHabit(todayLogs);
        List<DashboardResponse.TodayHabit> todayHabits = activeHabits.stream()
                .map(habit -> dashboardMapper.toTodayHabit(habit, latestTodayLogs.get(habit.getId())))
                .toList();

        int totalHabits = activeHabits.size();
        int completedHabits = (int) todayHabits.stream().filter(DashboardResponse.TodayHabit::completed).count();
        int pendingHabits = Math.max(totalHabits - completedHabits, 0);
        BigDecimal completionPercentage = calculateCompletionPercentage(totalHabits, completedHabits);

        List<HabitLog> historyLogs = activeHabitIds.isEmpty()
                ? List.of()
                : habitLogRepository.findByHabitIdInAndLoggedAtBeforeOrderByLoggedAtDescIdDesc(activeHabitIds, startOfNextDay);
        Map<LocalDate, Set<Long>> completedHabitIdsByDate = completedHabitIdsByDate(historyLogs);
        int currentStreak = calculateCurrentStreak(currentDate, totalHabits, completedHabitIdsByDate);
        int longestStreak = calculateLongestStreak(currentDate, totalHabits, completedHabitIdsByDate);

        DashboardResponse.Summary summary = dashboardMapper.toSummary(
                totalHabits,
                completedHabits,
                pendingHabits,
                completionPercentage,
                currentStreak,
                longestStreak
        );

        return dashboardMapper.toResponse(
                currentDate,
                resolveGreeting(),
                resolveUserName(),
                summary,
                todayHabits
        );
    }

    private Map<Long, HabitLog> latestLogsByHabit(List<HabitLog> habitLogs) {
        Map<Long, HabitLog> latestLogs = new LinkedHashMap<>();
        for (HabitLog habitLog : habitLogs) {
            latestLogs.putIfAbsent(habitLog.getHabitId(), habitLog);
        }
        return latestLogs;
    }

    private Map<LocalDate, Set<Long>> completedHabitIdsByDate(List<HabitLog> habitLogs) {
        Map<LocalDate, Map<Long, HabitLog>> latestLogsByDate = new LinkedHashMap<>();
        for (HabitLog habitLog : habitLogs) {
            LocalDate logDate = habitLog.getLoggedAt().toLocalDate();
            latestLogsByDate.computeIfAbsent(logDate, date -> new LinkedHashMap<>())
                    .putIfAbsent(habitLog.getHabitId(), habitLog);
        }

        return latestLogsByDate.entrySet().stream()
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        entry -> entry.getValue().values().stream()
                                .filter(log -> "completed".equalsIgnoreCase(log.getCompletionStatus()))
                                .map(HabitLog::getHabitId)
                                .collect(Collectors.toSet()),
                        (left, right) -> left,
                        LinkedHashMap::new
                ));
    }

    private int calculateCurrentStreak(
            LocalDate currentDate,
            int totalHabits,
            Map<LocalDate, Set<Long>> completedHabitIdsByDate
    ) {
        if (totalHabits == 0) {
            return 0;
        }

        int streak = 0;
        LocalDate cursor = currentDate;
        while (isFullyCompletedDay(cursor, totalHabits, completedHabitIdsByDate)) {
            streak++;
            cursor = cursor.minusDays(1);
        }
        return streak;
    }

    private int calculateLongestStreak(
            LocalDate currentDate,
            int totalHabits,
            Map<LocalDate, Set<Long>> completedHabitIdsByDate
    ) {
        if (totalHabits == 0 || completedHabitIdsByDate.isEmpty()) {
            return 0;
        }

        LocalDate earliestDate = completedHabitIdsByDate.keySet().stream().min(LocalDate::compareTo).orElse(currentDate);
        int longest = 0;
        int current = 0;

        for (LocalDate cursor = earliestDate; !cursor.isAfter(currentDate); cursor = cursor.plusDays(1)) {
            if (isFullyCompletedDay(cursor, totalHabits, completedHabitIdsByDate)) {
                current++;
                longest = Math.max(longest, current);
            } else {
                current = 0;
            }
        }
        return longest;
    }

    private boolean isFullyCompletedDay(
            LocalDate date,
            int totalHabits,
            Map<LocalDate, Set<Long>> completedHabitIdsByDate
    ) {
        if (totalHabits == 0) {
            return false;
        }
        Set<Long> completedHabitIds = completedHabitIdsByDate.get(date);
        return completedHabitIds != null && completedHabitIds.size() >= totalHabits;
    }

    private BigDecimal calculateCompletionPercentage(int totalHabits, int completedHabits) {
        if (totalHabits == 0) {
            return BigDecimal.ZERO;
        }
        return BigDecimal.valueOf(completedHabits)
                .multiply(PERCENT_SCALE)
                .divide(BigDecimal.valueOf(totalHabits), 2, RoundingMode.HALF_UP);
    }

    private String resolveUserName() {
        AppUser user = currentUserService.getCurrentUser();
        if (user.getDisplayName() != null && !user.getDisplayName().isBlank()) {
            return user.getDisplayName().trim();
        }

        String email = user.getEmail();
        if (email != null) {
            int atIndex = email.indexOf('@');
            if (atIndex > 0) {
                return email.substring(0, atIndex);
            }
            return email;
        }

        return "User";
    }

    private String resolveGreeting() {
        int hour = LocalTime.now(ZoneId.systemDefault()).getHour();
        if (hour < 12) {
            return "Good Morning";
        }
        if (hour < 18) {
            return "Good Afternoon";
        }
        return "Good Evening";
    }

    private LocalDate currentDate() {
        return LocalDate.now(ZoneId.systemDefault());
    }

    private Comparator<Habit> habitComparator() {
        return Comparator
                .comparingInt(Habit::getDisplayOrder)
                .thenComparing(Habit::getName, String.CASE_INSENSITIVE_ORDER)
                .thenComparing(Habit::getId);
    }
}
