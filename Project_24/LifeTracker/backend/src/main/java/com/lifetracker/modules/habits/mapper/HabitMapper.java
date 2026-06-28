package com.lifetracker.modules.habits.mapper;

import com.lifetracker.modules.habits.dto.CreateHabitRequest;
import com.lifetracker.modules.habits.dto.HabitResponse;
import com.lifetracker.modules.habits.dto.UpdateHabitRequest;
import com.lifetracker.modules.habits.entity.Habit;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Component
public class HabitMapper {

    public Habit toEntity(CreateHabitRequest request, Long userId) {
        Habit habit = new Habit();
        habit.setUuid(UUID.randomUUID());
        applyCreateRequest(habit, request, userId);
        habit.setCreatedAt(LocalDateTime.now());
        habit.setUpdatedAt(LocalDateTime.now());
        return habit;
    }

    public void updateEntity(Habit habit, UpdateHabitRequest request) {
        applyUpdateRequest(habit, request);
        habit.setUpdatedAt(LocalDateTime.now());
    }

    public HabitResponse toResponse(Habit habit) {
        return new HabitResponse(
                habit.getId(),
                habit.getUuid(),
                habit.getName(),
                habit.getDescription(),
                habit.getFrequency(),
                habit.getStartDate(),
                habit.getEndDate(),
                habit.getReminderTime(),
                habit.isNotificationsEnabled(),
                habit.getIconName(),
                habit.getColorHex(),
                habit.isActive()
        );
    }

    public List<HabitResponse> toResponseList(List<Habit> habits) {
        return habits.stream().map(this::toResponse).toList();
    }

    private void applyCreateRequest(Habit habit, CreateHabitRequest request, Long userId) {
        habit.setUserId(userId);
        habit.setHabitCategoryId(request.habitCategoryId());
        habit.setName(request.name().trim());
        habit.setDescription(normalizeNullableText(request.description()));
        habit.setFrequency(request.frequency());
        habit.setReminderTime(request.reminderTime());
        habit.setNotificationsEnabled(
                request.notificationsEnabled() == null
                        ? true
                        : request.notificationsEnabled());
        habit.setIconName(normalizeNullableText(request.iconName()));
        habit.setColorHex(normalizeNullableText(request.colorHex()));
        habit.setStartDate(
                request.startDate() == null
                        ? LocalDate.now()
                        : request.startDate());
        habit.setEndDate(request.endDate());
        habit.setDisplayOrder(0);
        habit.setActive(true);
    }

    private void applyUpdateRequest(Habit habit, UpdateHabitRequest request) {
        habit.setHabitCategoryId(request.habitCategoryId());
        habit.setName(request.name().trim());
        habit.setDescription(normalizeNullableText(request.description()));
        habit.setFrequency(request.frequency());
        habit.setReminderTime(request.reminderTime());
        habit.setNotificationsEnabled(request.notificationsEnabled());
        habit.setIconName(normalizeNullableText(request.iconName()));
        habit.setColorHex(normalizeNullableText(request.colorHex()));
        habit.setStartDate(request.startDate());
        habit.setEndDate(request.endDate());
    }

    private String normalizeNullableText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
