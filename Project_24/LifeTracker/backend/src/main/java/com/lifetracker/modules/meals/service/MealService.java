package com.lifetracker.modules.meals.service;

import com.lifetracker.modules.meals.dto.CreateMealRequest;
import com.lifetracker.modules.meals.dto.MealResponse;
import com.lifetracker.modules.meals.dto.UpdateMealRequest;
import com.lifetracker.modules.meals.enums.MealType;

import java.time.LocalDate;
import java.util.List;

public interface MealService {
    List<MealResponse> getMealsForToday();

    List<MealResponse> getMealsForDate(LocalDate date);

    MealResponse getMealById(Long id);

    MealResponse createMeal(CreateMealRequest request);

    MealResponse updateMeal(Long id, UpdateMealRequest request);

    void deleteMeal(Long id);

    List<MealResponse> duplicateYesterday(MealType mealType, LocalDate targetDate);

    void clearMealsForType(MealType mealType, LocalDate date);
}
