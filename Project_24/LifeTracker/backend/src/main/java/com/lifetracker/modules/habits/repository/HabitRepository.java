package com.lifetracker.modules.habits.repository;

import com.lifetracker.modules.habits.entity.Habit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface HabitRepository extends JpaRepository<Habit, Long> {
    List<Habit> findAllByActiveTrue();

    List<Habit> findAllByUserIdAndActiveTrue(Long userId);

    List<Habit> findAllByUserId(Long userId);

    Optional<Habit> findByIdAndUserId(Long id, Long userId);
}
