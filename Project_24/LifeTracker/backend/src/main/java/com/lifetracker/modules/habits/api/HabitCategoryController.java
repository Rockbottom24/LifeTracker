package com.lifetracker.modules.habits.api;

import com.lifetracker.modules.habits.dto.HabitCategoryResponse;
import com.lifetracker.modules.habits.service.HabitCategoryService;
import com.lifetracker.shared.application.dto.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/habit-categories")
public class HabitCategoryController {
    private final HabitCategoryService habitCategoryService;

    public HabitCategoryController(HabitCategoryService habitCategoryService) {
        this.habitCategoryService = habitCategoryService;
    }

    @GetMapping
    public ApiResponse<List<HabitCategoryResponse>> getCategories() {
        return ApiResponse.success("Habit categories retrieved successfully", habitCategoryService.getAllCategories());
    }
}
