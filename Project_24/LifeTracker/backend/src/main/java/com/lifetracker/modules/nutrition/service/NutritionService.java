package com.lifetracker.modules.nutrition.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.nutrition.dto.NutritionDashboardResponse;
import com.lifetracker.modules.nutrition.dto.NutritionGoalsResponse;
import com.lifetracker.modules.nutrition.dto.UpdateNutritionGoalsRequest;

import java.time.LocalDate;

public interface NutritionService {
    NutritionDashboardResponse getDashboard(LocalDate date);

    NutritionGoalsResponse getGoals();

    NutritionGoalsResponse updateGoals(UpdateNutritionGoalsRequest request);
}
