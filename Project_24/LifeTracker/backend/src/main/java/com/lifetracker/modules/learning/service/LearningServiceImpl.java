package com.lifetracker.modules.learning.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.learning.dto.CompleteLearningRequest;
import com.lifetracker.modules.learning.dto.CreateLearningRequest;
import com.lifetracker.modules.learning.dto.LearningResponse;
import com.lifetracker.modules.learning.dto.UpdateLearningRequest;
import com.lifetracker.modules.learning.entity.LearningSession;
import com.lifetracker.modules.learning.enums.LearningStatus;
import com.lifetracker.modules.learning.mapper.LearningMapper;
import com.lifetracker.modules.learning.repository.LearningSessionRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

@Service
@Transactional
public class LearningServiceImpl implements LearningService {
    private final LearningSessionRepository learningSessionRepository;
    private final LearningMapper learningMapper;
    private final CurrentUserService currentUserService;

    public LearningServiceImpl(
            LearningSessionRepository learningSessionRepository,
            LearningMapper learningMapper,
            CurrentUserService currentUserService
    ) {
        this.learningSessionRepository = learningSessionRepository;
        this.learningMapper = learningMapper;
        this.currentUserService = currentUserService;
    }

    @Override
    @Transactional(readOnly = true)
    public List<LearningResponse> getAllSessions() {
        List<LearningSession> sessions = learningSessionRepository.findByUserId(currentUserService.getCurrentUserId());
        sessions.sort(sessionComparator());
        return learningMapper.toResponseList(sessions);
    }

    @Override
    @Transactional(readOnly = true)
    public LearningResponse getSessionById(Long id) {
        return learningMapper.toResponse(findSessionOrThrow(id));
    }

    @Override
    public LearningResponse createSession(CreateLearningRequest request) {
        LearningSession session = learningMapper.toEntity(request, currentUserService.getCurrentUserId());
        LearningSession saved = learningSessionRepository.save(session);
        return learningMapper.toResponse(saved);
    }

    @Override
    public LearningResponse updateSession(Long id, UpdateLearningRequest request) {
        LearningSession session = findSessionOrThrow(id);
        learningMapper.updateEntity(session, request);

        try {
            LearningSession saved = learningSessionRepository.saveAndFlush(session);
            return learningMapper.toResponse(saved);
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unable to update learning session.", ex);
        }
    }

    @Override
    public void deleteSession(Long id) {
        LearningSession session = findSessionOrThrow(id);
        try {
            learningSessionRepository.delete(session);
            learningSessionRepository.flush();
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Learning session cannot be deleted.", ex);
        }
    }

    @Override
    public LearningResponse startSession(Long id) {
        LearningSession session = findSessionOrThrow(id);
        session.setStatus(LearningStatus.IN_PROGRESS);
        session.setUpdatedAt(LocalDateTime.now());
        return learningMapper.toResponse(learningSessionRepository.save(session));
    }

    @Override
    public LearningResponse completeSession(Long id, CompleteLearningRequest request) {
        LearningSession session = findSessionOrThrow(id);
        session.setStatus(LearningStatus.COMPLETED);
        session.setCompletedMinutes(request.completedMinutes());
        session.setCompletedDate(LocalDate.now());
        session.setUpdatedAt(LocalDateTime.now());
        return learningMapper.toResponse(learningSessionRepository.save(session));
    }

    private LearningSession findSessionOrThrow(Long id) {
        return learningSessionRepository.findByIdAndUserId(id, currentUserService.getCurrentUserId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Learning session not found"));
    }

    private Comparator<LearningSession> sessionComparator() {
        return Comparator
                .comparingInt(LearningSession::getDisplayOrder)
                .thenComparing(LearningSession::getTitle, String.CASE_INSENSITIVE_ORDER)
                .thenComparing(LearningSession::getId);
    }
}
