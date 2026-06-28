package com.lifetracker.modules.habits.repository;

import com.lifetracker.modules.habits.entity.HabitCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface HabitCategoryRepository extends JpaRepository<HabitCategory, Long> {
    List<HabitCategory> findAllByActiveTrueOrderByDisplayOrderAscNameAsc();
}
