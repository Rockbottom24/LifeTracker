package com.lifetracker.modules.nutrition.service;

import com.lifetracker.modules.nutrition.entity.NutritionGoals;
import com.lifetracker.modules.nutrition.mapper.NutritionGoalsMapper;
import com.lifetracker.modules.nutrition.repository.NutritionGoalsRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class NutritionGoalsProvisioningService {
    private final NutritionGoalsRepository nutritionGoalsRepository;
    private final NutritionGoalsMapper nutritionGoalsMapper;

    public NutritionGoalsProvisioningService(
            NutritionGoalsRepository nutritionGoalsRepository,
            NutritionGoalsMapper nutritionGoalsMapper
    ) {
        this.nutritionGoalsRepository = nutritionGoalsRepository;
        this.nutritionGoalsMapper = nutritionGoalsMapper;
    }

    @Transactional(readOnly = true)
    public Optional<NutritionGoals> findByOwnerUserId(Long ownerUserId) {
        return nutritionGoalsRepository.findByOwnerUserId(ownerUserId);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public NutritionGoals createDefaultGoals(Long ownerUserId) {
        // Default goal creation must run in its own write transaction.
        // The caller may be read-only, so we isolate the INSERT from that transaction boundary.
        NutritionGoals goals = nutritionGoalsMapper.createDefault(ownerUserId);
        return nutritionGoalsRepository.save(goals);
    }
}
