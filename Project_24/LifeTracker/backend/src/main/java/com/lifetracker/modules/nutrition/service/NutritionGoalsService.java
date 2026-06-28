package com.lifetracker.modules.nutrition.service;

import com.lifetracker.modules.nutrition.dto.NutritionGoalsResponse;
import com.lifetracker.modules.nutrition.dto.UpdateNutritionGoalsRequest;

public interface NutritionGoalsService {
    NutritionGoalsResponse getGoals();

    NutritionGoalsResponse updateGoals(UpdateNutritionGoalsRequest request);
}
