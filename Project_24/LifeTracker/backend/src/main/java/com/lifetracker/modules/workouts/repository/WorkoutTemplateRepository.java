package com.lifetracker.modules.workouts.repository;

import com.lifetracker.modules.workouts.entity.WorkoutTemplateEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface WorkoutTemplateRepository extends JpaRepository<WorkoutTemplateEntity, Long> {
    Optional<WorkoutTemplateEntity> findByUuid(java.util.UUID uuid);

    @Query("SELECT t FROM WorkoutTemplateEntity t WHERE (t.preset = true OR t.userId = :userId) AND t.active = true ORDER BY t.preset DESC, t.name ASC")
    List<WorkoutTemplateEntity> findAllAvailableForUser(Long userId);

    List<WorkoutTemplateEntity> findByUserIdAndActiveTrue(Long userId);
}
