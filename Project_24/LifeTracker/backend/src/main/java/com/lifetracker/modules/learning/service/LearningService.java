package com.lifetracker.modules.learning.service;

import com.lifetracker.modules.learning.dto.CompleteLearningRequest;
import com.lifetracker.modules.learning.dto.CreateLearningRequest;
import com.lifetracker.modules.learning.dto.LearningResponse;
import com.lifetracker.modules.learning.dto.UpdateLearningRequest;

import java.util.List;

public interface LearningService {
    List<LearningResponse> getAllSessions();

    LearningResponse getSessionById(Long id);

    LearningResponse createSession(CreateLearningRequest request);

    LearningResponse updateSession(Long id, UpdateLearningRequest request);

    void deleteSession(Long id);

    LearningResponse startSession(Long id);

    LearningResponse completeSession(Long id, CompleteLearningRequest request);
}
