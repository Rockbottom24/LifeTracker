package com.lifetracker.modules.habitlogs.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.habitlogs.dto.CompleteHabitRequest;
import com.lifetracker.modules.habitlogs.entity.HabitLog;
import com.lifetracker.modules.habitlogs.repository.HabitLogRepository;
import com.lifetracker.modules.habits.entity.Habit;
import com.lifetracker.modules.habits.enums.HabitFrequency;
import com.lifetracker.modules.habits.repository.HabitRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HabitLogServiceImplTest {

    @Mock
    private HabitRepository habitRepository;

    @Mock
    private HabitLogRepository habitLogRepository;

    @Mock
    private CurrentUserService currentUserService;

    @InjectMocks
    private HabitLogServiceImpl habitLogService;

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        org.mockito.Mockito.when(currentUserService.getCurrentUserId()).thenReturn(1L);
    }

    @Test
    void completeHabit_usesNumericPrimaryKeyAndInsertsLog() {
        Habit habit = activeHabit(7L);
        CompleteHabitRequest request = new CompleteHabitRequest(7L, BigDecimal.ONE, null);

        when(habitRepository.findByIdAndUserId(7L, 1L)).thenReturn(Optional.of(habit));
        when(habitLogRepository.findTopByHabitIdAndLoggedAtBetweenOrderByLoggedAtDescIdDesc(
                eq(7L), any(), any())).thenReturn(Optional.empty());
        when(habitLogRepository.saveAndFlush(any(HabitLog.class))).thenAnswer(invocation -> {
            HabitLog log = invocation.getArgument(0);
            log.setId(99L);
            return log;
        });

        var response = habitLogService.completeHabit(request);

        assertEquals(7L, response.habitId());
        assertTrue(response.completed());

        ArgumentCaptor<HabitLog> captor = ArgumentCaptor.forClass(HabitLog.class);
        verify(habitLogRepository).saveAndFlush(captor.capture());
        assertEquals(7L, captor.getValue().getHabitId());
        assertEquals("completed", captor.getValue().getCompletionStatus());
    }

    @Test
    void completeHabit_returns404WhenHabitMissing() {
        when(habitRepository.findByIdAndUserId(404L, 1L)).thenReturn(Optional.empty());

        ResponseStatusException ex = assertThrows(
                ResponseStatusException.class,
                () -> habitLogService.completeHabit(new CompleteHabitRequest(404L, BigDecimal.ONE, null))
        );

        assertEquals(404, ex.getStatusCode().value());
        verify(habitLogRepository, never()).saveAndFlush(any());
    }

    @Test
    void completeHabit_succeedsEvenWhenHabitMarkedInactiveInDatabase() {
        Habit habit = activeHabit(8L);
        habit.setActive(false);
        when(habitRepository.findByIdAndUserId(8L, 1L)).thenReturn(Optional.of(habit));
        when(habitLogRepository.findTopByHabitIdAndLoggedAtBetweenOrderByLoggedAtDescIdDesc(
                eq(8L), any(), any())).thenReturn(Optional.empty());
        when(habitLogRepository.saveAndFlush(any(HabitLog.class))).thenAnswer(invocation -> {
            HabitLog log = invocation.getArgument(0);
            log.setId(100L);
            return log;
        });

        var response = habitLogService.completeHabit(new CompleteHabitRequest(8L, BigDecimal.ONE, null));

        assertEquals(8L, response.habitId());
        assertTrue(response.completed());
    }

    private Habit activeHabit(Long id) {
        Habit habit = new Habit();
        habit.setId(id);
        habit.setUuid(UUID.randomUUID());
        habit.setUserId(1L);
        habit.setHabitCategoryId(1L);
        habit.setName("Drink Water");
        habit.setStartDate(LocalDate.now());
        habit.setDisplayOrder(0);
        habit.setActive(true);
        habit.setFrequency(HabitFrequency.DAILY);
        habit.setCreatedAt(LocalDateTime.now());
        habit.setUpdatedAt(LocalDateTime.now());
        return habit;
    }
}
