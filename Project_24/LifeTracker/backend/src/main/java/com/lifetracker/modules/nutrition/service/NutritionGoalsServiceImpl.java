package com.lifetracker.modules.nutrition.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.nutrition.dto.NutritionGoalsResponse;
import com.lifetracker.modules.nutrition.dto.UpdateNutritionGoalsRequest;
import com.lifetracker.modules.nutrition.entity.NutritionGoals;
import com.lifetracker.modules.nutrition.mapper.NutritionGoalsMapper;
import com.lifetracker.modules.nutrition.repository.NutritionGoalsRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NutritionGoalsServiceImpl implements NutritionGoalsService {
    private final NutritionGoalsRepository nutritionGoalsRepository;
    private final NutritionGoalsMapper nutritionGoalsMapper;
    private final CurrentUserService currentUserService;
    private final NutritionGoalsProvisioningService nutritionGoalsProvisioningService;

    public NutritionGoalsServiceImpl(
            NutritionGoalsRepository nutritionGoalsRepository,
            NutritionGoalsMapper nutritionGoalsMapper,
            CurrentUserService currentUserService,
            NutritionGoalsProvisioningService nutritionGoalsProvisioningService
    ) {
        this.nutritionGoalsRepository = nutritionGoalsRepository;
        this.nutritionGoalsMapper = nutritionGoalsMapper;
        this.currentUserService = currentUserService;
        this.nutritionGoalsProvisioningService = nutritionGoalsProvisioningService;
    }

    @Override
    @Transactional(readOnly = true)
    public NutritionGoalsResponse getGoals() {
        Long userId = currentUserService.getCurrentUserId();
        // Keep the public lookup read-only. If defaults are missing, create them in a separate
        // write transaction so the INSERT does not inherit this read-only boundary.
        NutritionGoals goals = nutritionGoalsProvisioningService.findByOwnerUserId(userId)
                .orElseGet(() -> nutritionGoalsProvisioningService.createDefaultGoals(userId));
        return nutritionGoalsMapper.toResponse(goals);
    }

    @Override
    @Transactional
    public NutritionGoalsResponse updateGoals(UpdateNutritionGoalsRequest request) {
        Long userId = currentUserService.getCurrentUserId();
        NutritionGoals goals = nutritionGoalsProvisioningService.findByOwnerUserId(userId)
                .orElseGet(() -> nutritionGoalsProvisioningService.createDefaultGoals(userId));
        nutritionGoalsMapper.updateEntity(goals, request);
        return nutritionGoalsMapper.toResponse(nutritionGoalsRepository.save(goals));
    }
}
