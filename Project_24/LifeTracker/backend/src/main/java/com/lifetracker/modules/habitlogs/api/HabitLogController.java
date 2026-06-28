package com.lifetracker.modules.habitlogs.api;

import com.lifetracker.modules.habitlogs.dto.CompleteHabitRequest;
import com.lifetracker.modules.habitlogs.dto.HabitLogResponse;
import com.lifetracker.modules.habitlogs.service.HabitLogService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Validated
@RestController
@RequestMapping("/api/v1/habit-logs")
public class HabitLogController {
    private final HabitLogService habitLogService;

    public HabitLogController(HabitLogService habitLogService) {
        this.habitLogService = habitLogService;
    }

    @GetMapping("/today")
    public ResponseEntity<List<HabitLogResponse>> getTodayHabitStatuses() {
        return ResponseEntity.ok(habitLogService.getTodayHabitStatuses());
    }

    @PostMapping("/complete")
    public ResponseEntity<HabitLogResponse> completeHabit(@Valid @RequestBody CompleteHabitRequest request) {
        return ResponseEntity.ok(habitLogService.completeHabit(request));
    }

    @DeleteMapping("/{habitId}/today")
    public ResponseEntity<HabitLogResponse> markTodayIncomplete(@PathVariable @Positive Long habitId) {
        return ResponseEntity.ok(habitLogService.markTodayIncomplete(habitId));
    }
}
