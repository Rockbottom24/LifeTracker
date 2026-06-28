package com.lifetracker.modules.habits.service;

import com.lifetracker.modules.habits.dto.HabitCategoryResponse;

import java.util.List;

public interface HabitCategoryService {
    List<HabitCategoryResponse> getAllCategories();
}
