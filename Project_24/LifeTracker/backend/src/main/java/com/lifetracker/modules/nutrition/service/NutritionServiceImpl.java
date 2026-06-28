package com.lifetracker.modules.nutrition.service;

import com.lifetracker.modules.meals.dto.MealResponse;
import com.lifetracker.modules.meals.service.MealService;
import com.lifetracker.modules.nutrition.dto.NutritionDashboardResponse;
import com.lifetracker.modules.nutrition.dto.NutritionGoalsResponse;
import com.lifetracker.modules.nutrition.dto.UpdateNutritionGoalsRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@Transactional
public class NutritionServiceImpl implements NutritionService {
    private final MealService mealService;
    private final NutritionGoalsService nutritionGoalsService;
    private final NutritionDashboardBuilder nutritionDashboardBuilder;

    public NutritionServiceImpl(
            MealService mealService,
            NutritionGoalsService nutritionGoalsService,
            NutritionDashboardBuilder nutritionDashboardBuilder
    ) {
        this.mealService = mealService;
        this.nutritionGoalsService = nutritionGoalsService;
        this.nutritionDashboardBuilder = nutritionDashboardBuilder;
    }

    @Override
    @Transactional(readOnly = true)
    public NutritionDashboardResponse getDashboard(LocalDate date) {
        LocalDate targetDate = date != null ? date : LocalDate.now();
        NutritionGoalsResponse goals = nutritionGoalsService.getGoals();
        List<MealResponse> meals = mealService.getMealsForDate(targetDate);
        return nutritionDashboardBuilder.build(targetDate, goals, meals);
    }

    @Override
    @Transactional(readOnly = true)
    public NutritionGoalsResponse getGoals() {
        return nutritionGoalsService.getGoals();
    }

    @Override
    public NutritionGoalsResponse updateGoals(UpdateNutritionGoalsRequest request) {
        return nutritionGoalsService.updateGoals(request);
    }
}
