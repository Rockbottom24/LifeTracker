package com.lifetracker.modules.habits.service;

import com.lifetracker.modules.habits.dto.CreateHabitRequest;
import com.lifetracker.modules.habits.dto.HabitResponse;
import com.lifetracker.modules.habits.dto.UpdateHabitRequest;

import java.util.List;

public interface HabitService {
    List<HabitResponse> getAllHabits();

    HabitResponse getHabitById(Long id);

    HabitResponse createHabit(CreateHabitRequest request);

    HabitResponse updateHabit(Long id, UpdateHabitRequest request);

    void deleteHabit(Long id);
}
