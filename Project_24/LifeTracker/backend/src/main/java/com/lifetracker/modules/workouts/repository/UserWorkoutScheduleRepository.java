package com.lifetracker.modules.workouts.repository;

import com.lifetracker.modules.workouts.entity.UserWorkoutScheduleEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserWorkoutScheduleRepository extends JpaRepository<UserWorkoutScheduleEntity, Long> {
    Optional<UserWorkoutScheduleEntity> findByUuid(UUID uuid);

    Optional<UserWorkoutScheduleEntity> findByUserIdAndScheduledDate(Long userId, LocalDate scheduledDate);

    List<UserWorkoutScheduleEntity> findByUserIdAndScheduledDateBetweenOrderByScheduledDateAsc(
            Long userId, LocalDate startDate, LocalDate endDate);

    List<UserWorkoutScheduleEntity> findByUserIdAndScheduledDateGreaterThanEqualOrderByScheduledDateAsc(
            Long userId, LocalDate startDate);
}
