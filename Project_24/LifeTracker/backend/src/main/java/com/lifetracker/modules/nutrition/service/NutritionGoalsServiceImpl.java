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
@Transactional
public class NutritionGoalsServiceImpl implements NutritionGoalsService {
    private final NutritionGoalsRepository nutritionGoalsRepository;
    private final NutritionGoalsMapper nutritionGoalsMapper;
    private final CurrentUserService currentUserService;

    public NutritionGoalsServiceImpl(
            NutritionGoalsRepository nutritionGoalsRepository,
            NutritionGoalsMapper nutritionGoalsMapper,
            CurrentUserService currentUserService
    ) {
        this.nutritionGoalsRepository = nutritionGoalsRepository;
        this.nutritionGoalsMapper = nutritionGoalsMapper;
        this.currentUserService = currentUserService;
    }

    @Override
    @Transactional(readOnly = true)
    public NutritionGoalsResponse getGoals() {
        return nutritionGoalsMapper.toResponse(findOrCreateGoals());
    }

    @Override
    public NutritionGoalsResponse updateGoals(UpdateNutritionGoalsRequest request) {
        NutritionGoals goals = findOrCreateGoals();
        nutritionGoalsMapper.updateEntity(goals, request);
        return nutritionGoalsMapper.toResponse(nutritionGoalsRepository.save(goals));
    }

    NutritionGoals findOrCreateGoals() {
        Long userId = currentUserService.getCurrentUserId();
        return nutritionGoalsRepository.findByOwnerUserId(userId)
                .orElseGet(() -> nutritionGoalsRepository.save(nutritionGoalsMapper.createDefault(userId)));
    }
}
