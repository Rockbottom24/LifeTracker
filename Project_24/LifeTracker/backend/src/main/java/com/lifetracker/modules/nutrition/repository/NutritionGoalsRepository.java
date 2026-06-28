package com.lifetracker.modules.nutrition.repository;

import com.lifetracker.modules.nutrition.entity.NutritionGoals;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface NutritionGoalsRepository extends JpaRepository<NutritionGoals, Long> {
    Optional<NutritionGoals> findByOwnerUserId(Long ownerUserId);
}
