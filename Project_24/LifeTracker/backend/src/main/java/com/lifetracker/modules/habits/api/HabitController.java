package com.lifetracker.modules.habits.api;

import com.lifetracker.modules.habits.dto.CreateHabitRequest;
import com.lifetracker.modules.habits.dto.HabitResponse;
import com.lifetracker.modules.habits.dto.UpdateHabitRequest;
import com.lifetracker.modules.habits.service.HabitService;
import com.lifetracker.shared.application.dto.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Validated
@RestController
@RequestMapping("/api/v1/habits")
public class HabitController {
    private final HabitService habitService;

    public HabitController(HabitService habitService) {
        this.habitService = habitService;
    }

    @GetMapping
    public ApiResponse<List<HabitResponse>> getHabits() {
        return ApiResponse.success("Habits retrieved successfully", habitService.getAllHabits());
    }

    @GetMapping("/{id}")
    public ApiResponse<HabitResponse> getHabit(@PathVariable @Positive Long id) {
        return ApiResponse.success("Habit retrieved successfully", habitService.getHabitById(id));
    }

    @PostMapping
    public ApiResponse<HabitResponse> createHabit(
            @Valid @RequestBody CreateHabitRequest request) {

        return ApiResponse.success(
                "Habit created successfully",
                habitService.createHabit(request));
    }

    @PutMapping("/{id}")
    public ApiResponse<HabitResponse> updateHabit(@PathVariable @Positive Long id, @Valid @RequestBody UpdateHabitRequest request) {
        return ApiResponse.success("Habit updated successfully", habitService.updateHabit(id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteHabit(@PathVariable @Positive Long id) {
        habitService.deleteHabit(id);
        return ApiResponse.<Void>success("Habit deleted successfully", null);
    }
}
