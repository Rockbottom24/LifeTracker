package com.lifetracker.modules.habitlogs.service;

import com.lifetracker.modules.habitlogs.dto.CompleteHabitRequest;
import com.lifetracker.modules.habitlogs.dto.HabitLogResponse;

import java.util.List;

public interface HabitLogService {
    List<HabitLogResponse> getTodayHabitStatuses();

    HabitLogResponse completeHabit(CompleteHabitRequest request);

    HabitLogResponse markTodayIncomplete(Long habitId);
}
