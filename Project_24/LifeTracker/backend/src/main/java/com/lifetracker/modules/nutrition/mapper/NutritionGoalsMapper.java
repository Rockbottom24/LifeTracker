package com.lifetracker.modules.nutrition.mapper;

import com.lifetracker.modules.nutrition.dto.NutritionGoalsResponse;
import com.lifetracker.modules.nutrition.dto.UpdateNutritionGoalsRequest;
import com.lifetracker.modules.nutrition.entity.NutritionGoals;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.UUID;

@Component
public class NutritionGoalsMapper {

    public NutritionGoals createDefault(Long ownerUserId) {
        NutritionGoals goals = new NutritionGoals();
        goals.setUuid(UUID.randomUUID());
        goals.setOwnerUserId(ownerUserId);
        goals.setCalorieGoal(NutritionGoals.DEFAULT_CALORIE_GOAL);
        goals.setProteinGoal(NutritionGoals.DEFAULT_PROTEIN_GOAL);
        goals.setCarbsGoal(NutritionGoals.DEFAULT_CARBS_GOAL);
        goals.setFatGoal(NutritionGoals.DEFAULT_FAT_GOAL);
        goals.setFiberGoal(NutritionGoals.DEFAULT_FIBER_GOAL);
        goals.setCreatedAt(LocalDateTime.now());
        goals.setUpdatedAt(LocalDateTime.now());
        return goals;
    }

    public NutritionGoalsResponse toResponse(NutritionGoals goals) {
        return new NutritionGoalsResponse(
                goals.getCalorieGoal(),
                goals.getProteinGoal(),
                goals.getCarbsGoal(),
                goals.getFatGoal(),
                goals.getFiberGoal()
        );
    }

    public void updateEntity(NutritionGoals goals, UpdateNutritionGoalsRequest request) {
        goals.setCalorieGoal(request.calorieGoal());
        goals.setProteinGoal(request.proteinGoal());
        goals.setCarbsGoal(request.carbsGoal());
        goals.setFatGoal(request.fatGoal());
        goals.setFiberGoal(request.fiberGoal());
        goals.setUpdatedAt(LocalDateTime.now());
    }
}
