package com.lifetracker.modules.meals.repository;

import com.lifetracker.modules.meals.entity.MealLogItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MealLogItemRepository extends JpaRepository<MealLogItem, Long> {
    List<MealLogItem> findByMealLogIdOrderByDisplayOrderAscIdAsc(Long mealLogId);

    void deleteByMealLogId(Long mealLogId);
}
