package com.lifetracker.modules.learning.repository;

import com.lifetracker.modules.learning.entity.LearningSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface LearningSessionRepository extends JpaRepository<LearningSession, Long> {
    List<LearningSession> findByUserId(Long userId);

    Optional<LearningSession> findByIdAndUserId(Long id, Long userId);
}
