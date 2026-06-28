package com.lifetracker.modules.habitlogs.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.habitlogs.dto.CompleteHabitRequest;
import com.lifetracker.modules.habitlogs.dto.HabitLogResponse;
import com.lifetracker.modules.habitlogs.entity.HabitLog;
import com.lifetracker.modules.habitlogs.repository.HabitLogRepository;
import com.lifetracker.modules.habits.entity.Habit;
import com.lifetracker.modules.habits.repository.HabitRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Transactional
public class HabitLogServiceImpl implements HabitLogService {
    private static final Logger log = LoggerFactory.getLogger(HabitLogServiceImpl.class);
    private static final String COMPLETED = "completed";
    private static final String SKIPPED = "skipped";
    private static final BigDecimal DEFAULT_COMPLETED_VALUE = BigDecimal.ONE;

    private final HabitRepository habitRepository;
    private final HabitLogRepository habitLogRepository;
    private final CurrentUserService currentUserService;

    public HabitLogServiceImpl(
            HabitRepository habitRepository,
            HabitLogRepository habitLogRepository,
            CurrentUserService currentUserService
    ) {
        this.habitRepository = habitRepository;
        this.habitLogRepository = habitLogRepository;
        this.currentUserService = currentUserService;
    }

    @Override
    @Transactional(readOnly = true)
    public List<HabitLogResponse> getTodayHabitStatuses() {
        LocalDate today = currentDate();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();

        List<Habit> activeHabits = habitRepository.findAllByUserIdAndActiveTrue(currentUserService.getCurrentUserId());
        activeHabits.sort(habitComparator());

        Map<Long, HabitLog> latestLogsByHabitId = habitLogRepository
                .findByLoggedAtBetweenOrderByLoggedAtDescIdDesc(startOfDay, endOfDay)
                .stream()
                .collect(Collectors.toMap(
                        HabitLog::getHabitId,
                        Function.identity(),
                        (left, right) -> left
                ));

        return activeHabits.stream()
                .map(habit -> toResponse(habit, latestLogsByHabitId.get(habit.getId()), today))
                .toList();
    }

    @Override
    public HabitLogResponse completeHabit(CompleteHabitRequest request) {
        log.debug("Complete habit request received for habitId={}", request.habitId());

        Habit habit = findHabitOrThrow(request.habitId());
        LocalDate today = currentDate();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();
        HabitLog latestLog = habitLogRepository
                .findTopByHabitIdAndLoggedAtBetweenOrderByLoggedAtDescIdDesc(habit.getId(), startOfDay, endOfDay)
                .orElse(null);

        if (latestLog != null && COMPLETED.equalsIgnoreCase(latestLog.getCompletionStatus())) {
            log.debug("HabitId={} already completed today; returning existing logId={}", habit.getId(), latestLog.getId());
            return toResponse(habit, latestLog, today);
        }

        HabitLog habitLog = createLog(habit.getId(), COMPLETED, request.value(), request.notes());
        HabitLog savedLog = habitLogRepository.saveAndFlush(habitLog);
        log.debug("Habit completion log inserted for habitId={} logId={}", habit.getId(), savedLog.getId());
        return toResponse(habit, savedLog, today);
    }

    @Override
    public HabitLogResponse markTodayIncomplete(Long habitId) {
        log.debug("Mark habit incomplete request received for habitId={}", habitId);

        Habit habit = findHabitOrThrow(habitId);
        LocalDate today = currentDate();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();
        HabitLog latestLog = habitLogRepository
                .findTopByHabitIdAndLoggedAtBetweenOrderByLoggedAtDescIdDesc(habit.getId(), startOfDay, endOfDay)
                .orElse(null);

        if (latestLog != null && SKIPPED.equalsIgnoreCase(latestLog.getCompletionStatus())) {
            return toResponse(habit, latestLog, today);
        }

        HabitLog habitLog = createLog(habit.getId(), SKIPPED, BigDecimal.ZERO, "Marked incomplete for today");
        HabitLog savedLog = habitLogRepository.saveAndFlush(habitLog);
        log.debug("Habit incomplete log inserted for habitId={} logId={}", habit.getId(), savedLog.getId());
        return toResponse(habit, savedLog, today);
    }

    private Habit findHabitOrThrow(Long habitId) {
        log.info("Complete/undo habit lookup: incoming habitId={}", habitId);

        return habitRepository.findByIdAndUserId(habitId, currentUserService.getCurrentUserId())
                .map(habit -> {
                    log.info(
                            "Habit found: id={} uuid={} name={} is_active={} user_id={} category_id={}",
                            habit.getId(),
                            habit.getUuid(),
                            habit.getName(),
                            habit.isActive(),
                            habit.getUserId(),
                            habit.getHabitCategoryId()
                    );
                    return habit;
                })
                .orElseThrow(() -> {
                    log.warn("Habit lookup by id={} returned no row", habitId);
                    return new ResponseStatusException(HttpStatus.NOT_FOUND, "Habit not found");
                });
    }

    private HabitLog createLog(Long habitId, String status, BigDecimal requestedValue, String notes) {
        LocalDateTime now = LocalDateTime.now();
        HabitLog habitLog = new HabitLog();
        habitLog.setUuid(UUID.randomUUID());
        habitLog.setHabitId(habitId);
        habitLog.setLoggedAt(now);
        habitLog.setCompletionStatus(status.toLowerCase());
        habitLog.setValue(COMPLETED.equalsIgnoreCase(status) ? defaultCompletedValue(requestedValue) : BigDecimal.ZERO);
        habitLog.setNotes(normalizeNullableText(notes));
        habitLog.setCreatedAt(now);
        habitLog.setUpdatedAt(now);
        habitLog.setActive(true);
        return habitLog;
    }

    private BigDecimal defaultCompletedValue(BigDecimal requestedValue) {
        return requestedValue == null ? DEFAULT_COMPLETED_VALUE : requestedValue;
    }

    private HabitLogResponse toResponse(Habit habit, HabitLog habitLog, LocalDate logDate) {
        if (habitLog == null) {
            return new HabitLogResponse(
                    habit.getId(),
                    habit.getUuid(),
                    habit.getName(),
                    habit.getHabitCategoryId(),
                    habit.getDisplayOrder(),
                    habit.isActive(),
                    null,
                    null,
                    logDate,
                    null,
                    "NOT_LOGGED",
                    false,
                    null,
                    null
            );
        }

        boolean completed = COMPLETED.equalsIgnoreCase(habitLog.getCompletionStatus());
        return new HabitLogResponse(
                habit.getId(),
                habit.getUuid(),
                habit.getName(),
                habit.getHabitCategoryId(),
                habit.getDisplayOrder(),
                habit.isActive(),
                habitLog.getId(),
                habitLog.getUuid(),
                habitLog.getLoggedAt().toLocalDate(),
                habitLog.getLoggedAt(),
                habitLog.getCompletionStatus(),
                completed,
                habitLog.getValue(),
                habitLog.getNotes()
        );
    }

    private Comparator<Habit> habitComparator() {
        return Comparator
                .comparingInt(Habit::getDisplayOrder)
                .thenComparing(Habit::getName, String.CASE_INSENSITIVE_ORDER)
                .thenComparing(Habit::getId);
    }

    private LocalDate currentDate() {
        return LocalDate.now(ZoneId.systemDefault());
    }

    private String normalizeNullableText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
