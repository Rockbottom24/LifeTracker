package com.lifetracker.modules.habits.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.habits.dto.CreateHabitRequest;
import com.lifetracker.modules.habits.dto.HabitResponse;
import com.lifetracker.modules.habits.dto.UpdateHabitRequest;
import com.lifetracker.modules.habits.entity.Habit;
import com.lifetracker.modules.habits.mapper.HabitMapper;
import com.lifetracker.modules.habits.repository.HabitRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

@Service
@Transactional
public class HabitServiceImpl implements HabitService {
    private final HabitRepository habitRepository;
    private final HabitMapper habitMapper;
    private final CurrentUserService currentUserService;

    public HabitServiceImpl(
            HabitRepository habitRepository,
            HabitMapper habitMapper,
            CurrentUserService currentUserService
    ) {
        this.habitRepository = habitRepository;
        this.habitMapper = habitMapper;
        this.currentUserService = currentUserService;
    }

    @Override
    @Transactional(readOnly = true)
    public List<HabitResponse> getAllHabits() {
        List<Habit> habits = habitRepository.findAllByUserId(currentUserService.getCurrentUserId());
        habits.sort((left, right) -> {
            int comparison = Integer.compare(left.getDisplayOrder(), right.getDisplayOrder());
            if (comparison != 0) {
                return comparison;
            }
            comparison = left.getName().compareToIgnoreCase(right.getName());
            if (comparison != 0) {
                return comparison;
            }
            return Long.compare(left.getId(), right.getId());
        });
        return habitMapper.toResponseList(habits);
    }

    @Override
    @Transactional(readOnly = true)
    public HabitResponse getHabitById(Long id) {
        Habit habit = findHabitOrThrow(id);
        return habitMapper.toResponse(habit);
    }

    @Override
    public HabitResponse createHabit(CreateHabitRequest request) {
        validateDateRange(request.startDate(), request.endDate());
        Habit habit = habitMapper.toEntity(request, currentUserService.getCurrentUserId());
        Habit savedHabit = habitRepository.save(habit);
        return habitMapper.toResponse(savedHabit);
    }

    @Override
    public HabitResponse updateHabit(Long id, UpdateHabitRequest request) {
        validateDateRange(request.startDate(), request.endDate());
        Habit habit = findHabitOrThrow(id);
        habitMapper.updateEntity(habit, request);

        try {
            Habit savedHabit = habitRepository.saveAndFlush(habit);
            return habitMapper.toResponse(savedHabit);
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unable to update habit. Check category and field constraints.", ex);
        }
    }

    @Override
    public void deleteHabit(Long id) {
        Habit habit = findHabitOrThrow(id);
        try {
            habitRepository.delete(habit);
            habitRepository.flush();
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Habit cannot be deleted because dependent records exist.", ex);
        }
    }

    private Habit findHabitOrThrow(Long id) {
        return habitRepository.findByIdAndUserId(id, currentUserService.getCurrentUserId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Habit not found"));
    }

    private void validateDateRange(LocalDate startDate, LocalDate endDate) {
        if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "endDate must be on or after startDate");
        }
    }
}
