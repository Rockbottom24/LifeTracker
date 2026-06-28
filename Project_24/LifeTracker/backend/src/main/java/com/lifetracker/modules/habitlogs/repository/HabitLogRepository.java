package com.lifetracker.modules.habitlogs.repository;

import com.lifetracker.modules.habitlogs.entity.HabitLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface HabitLogRepository extends JpaRepository<HabitLog, Long> {
    List<HabitLog> findByLoggedAtBetweenOrderByLoggedAtDescIdDesc(LocalDateTime start, LocalDateTime end);

    Optional<HabitLog> findTopByHabitIdAndLoggedAtBetweenOrderByLoggedAtDescIdDesc(Long habitId, LocalDateTime start, LocalDateTime end);

    List<HabitLog> findByHabitIdInAndLoggedAtBetweenOrderByLoggedAtDescIdDesc(List<Long> habitIds, LocalDateTime start, LocalDateTime end);

    List<HabitLog> findByHabitIdInAndLoggedAtBeforeOrderByLoggedAtDescIdDesc(List<Long> habitIds, LocalDateTime endExclusive);
}
