package com.lifetracker.modules.learning.mapper;

import com.lifetracker.modules.learning.dto.CreateLearningRequest;
import com.lifetracker.modules.learning.dto.LearningResponse;
import com.lifetracker.modules.learning.dto.UpdateLearningRequest;
import com.lifetracker.modules.learning.entity.LearningSession;
import com.lifetracker.modules.learning.enums.LearningStatus;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Component
public class LearningMapper {

    public LearningSession toEntity(CreateLearningRequest request, Long userId) {
        LearningSession session = new LearningSession();
        session.setUuid(UUID.randomUUID());
        applyCreateRequest(session, request, userId);
        session.setCompletedMinutes(0);
        session.setCreatedAt(LocalDateTime.now());
        session.setUpdatedAt(LocalDateTime.now());
        session.setDisplayOrder(0);
        return session;
    }

    public void updateEntity(LearningSession session, UpdateLearningRequest request) {
        session.setTitle(request.title().trim());
        session.setDescription(normalizeNullableText(request.description()));
        session.setTopic(normalizeNullableText(request.topic()));
        session.setResourceType(normalizeNullableText(request.resourceType()));
        session.setResourceUrl(normalizeNullableText(request.resourceUrl()));
        session.setPlannedMinutes(request.plannedMinutes());
        session.setCompletedMinutes(request.completedMinutes());
        session.setStatus(request.status());
        session.setPriority(request.priority());
        session.setScheduledDate(request.scheduledDate());
        session.setCompletedDate(request.completedDate());
        session.setReminderTime(request.reminderTime());
        session.setNotificationsEnabled(request.notificationsEnabled() != null && request.notificationsEnabled());
        session.setIconName(normalizeNullableText(request.iconName()));
        session.setColorHex(normalizeNullableText(request.colorHex()));
        session.setUpdatedAt(LocalDateTime.now());
    }

    public LearningResponse toResponse(LearningSession session) {
        return new LearningResponse(
                session.getId(),
                session.getUuid(),
                session.getTitle(),
                session.getDescription(),
                session.getTopic(),
                session.getResourceType(),
                session.getResourceUrl(),
                session.getPlannedMinutes(),
                session.getCompletedMinutes(),
                session.getStatus(),
                session.getPriority(),
                session.getScheduledDate(),
                session.getCompletedDate(),
                session.getReminderTime(),
                session.isNotificationsEnabled(),
                session.getColorHex(),
                session.getIconName(),
                session.getDisplayOrder()
        );
    }

    public List<LearningResponse> toResponseList(List<LearningSession> sessions) {
        return sessions.stream().map(this::toResponse).toList();
    }

    private void applyCreateRequest(LearningSession session, CreateLearningRequest request, Long userId) {
        session.setUserId(userId);
        session.setTitle(request.title().trim());
        session.setDescription(normalizeNullableText(request.description()));
        session.setTopic(normalizeNullableText(request.topic()));
        session.setResourceType(normalizeNullableText(request.resourceType()));
        session.setResourceUrl(normalizeNullableText(request.resourceUrl()));
        session.setPlannedMinutes(request.plannedMinutes());
        session.setStatus(request.status() == null ? LearningStatus.PLANNED : request.status());
        session.setPriority(request.priority());
        session.setScheduledDate(request.scheduledDate());
        session.setReminderTime(request.reminderTime());
        session.setNotificationsEnabled(request.notificationsEnabled() != null && request.notificationsEnabled());
        session.setIconName(normalizeNullableText(request.iconName()));
        session.setColorHex(normalizeNullableText(request.colorHex()));
    }

    private String normalizeNullableText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
