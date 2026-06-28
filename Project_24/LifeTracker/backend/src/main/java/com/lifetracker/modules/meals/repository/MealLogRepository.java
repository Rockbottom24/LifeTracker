package com.lifetracker.modules.meals.repository;

import com.lifetracker.modules.meals.enums.MealType;
import com.lifetracker.modules.meals.entity.MealLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface MealLogRepository extends JpaRepository<MealLog, Long> {
    List<MealLog> findByOwnerUserIdAndMealDateOrderByMealTypeAscCreatedAtAsc(Long ownerUserId, LocalDate mealDate);

    List<MealLog> findByOwnerUserIdAndMealDateAndMealTypeOrderByCreatedAtAsc(
            Long ownerUserId,
            LocalDate mealDate,
            MealType mealType
    );

    Optional<MealLog> findByIdAndOwnerUserId(Long id, Long ownerUserId);

    void deleteByOwnerUserIdAndMealDateAndMealType(Long ownerUserId, LocalDate mealDate, MealType mealType);
}
