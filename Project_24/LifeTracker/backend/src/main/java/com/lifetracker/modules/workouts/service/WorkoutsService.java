package com.lifetracker.modules.workouts.service;

import com.lifetracker.modules.workouts.dto.ApplyTemplateRequest;
import com.lifetracker.modules.workouts.dto.CreateTemplateRequest;
import com.lifetracker.modules.workouts.dto.UserWorkoutScheduleDTO;
import com.lifetracker.modules.workouts.dto.WorkoutTemplateDTO;
import com.lifetracker.modules.workouts.dto.WorkoutTemplateExerciseDTO;
import com.lifetracker.modules.workouts.entity.UserWorkoutScheduleEntity;
import com.lifetracker.modules.workouts.entity.WorkoutTemplateEntity;
import com.lifetracker.modules.workouts.entity.WorkoutTemplateExerciseEntity;
import com.lifetracker.modules.workouts.repository.UserWorkoutScheduleRepository;
import com.lifetracker.modules.workouts.repository.WorkoutTemplateRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class WorkoutsService {

    private final WorkoutTemplateRepository templateRepository;
    private final UserWorkoutScheduleRepository scheduleRepository;

    public WorkoutsService(WorkoutTemplateRepository templateRepository,
                           UserWorkoutScheduleRepository scheduleRepository) {
        this.templateRepository = templateRepository;
        this.scheduleRepository = scheduleRepository;
    }

    @Transactional(readOnly = true)
    public List<WorkoutTemplateDTO> getAvailableTemplates(Long userId) {
        List<WorkoutTemplateEntity> templates = templateRepository.findAllAvailableForUser(userId);
        return templates.stream().map(this::mapTemplateToDTO).toList();
    }

    @Transactional
    public WorkoutTemplateDTO createTemplate(Long userId, CreateTemplateRequest request) {
        WorkoutTemplateEntity entity = new WorkoutTemplateEntity();
        entity.setUserId(userId);
        entity.setName(request.name());
        entity.setCategory(request.category());
        entity.setDescription(request.description());
        entity.setPreset(false);
        entity.setActive(true);

        if (request.exercises() != null) {
            int order = 1;
            for (CreateTemplateRequest.ExerciseInput ex : request.exercises()) {
                WorkoutTemplateExerciseEntity exEntity = new WorkoutTemplateExerciseEntity();
                exEntity.setExerciseName(ex.exerciseName());
                exEntity.setSets(ex.sets() > 0 ? ex.sets() : 3);
                exEntity.setReps(ex.reps() != null && !ex.reps().isBlank() ? ex.reps() : "12-15");
                exEntity.setRestSeconds(ex.restSeconds() > 0 ? ex.restSeconds() : 45);
                exEntity.setSequenceOrder(ex.sequenceOrder() > 0 ? ex.sequenceOrder() : order++);
                entity.addExercise(exEntity);
            }
        }

        WorkoutTemplateEntity saved = templateRepository.save(entity);
        return mapTemplateToDTO(saved);
    }

    @Transactional
    public WorkoutTemplateDTO updateTemplate(Long userId, Long templateId, CreateTemplateRequest request) {
        WorkoutTemplateEntity entity = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found with ID: " + templateId));

        if (entity.isPreset() || (entity.getUserId() != null && !entity.getUserId().equals(userId))) {
            throw new IllegalArgumentException("Cannot modify preset or unauthorized template.");
        }

        entity.setName(request.name());
        entity.setCategory(request.category());
        entity.setDescription(request.description());
        entity.getExercises().clear();

        if (request.exercises() != null) {
            int order = 1;
            for (CreateTemplateRequest.ExerciseInput ex : request.exercises()) {
                WorkoutTemplateExerciseEntity exEntity = new WorkoutTemplateExerciseEntity();
                exEntity.setExerciseName(ex.exerciseName());
                exEntity.setSets(ex.sets() > 0 ? ex.sets() : 3);
                exEntity.setReps(ex.reps() != null && !ex.reps().isBlank() ? ex.reps() : "12-15");
                exEntity.setRestSeconds(ex.restSeconds() > 0 ? ex.restSeconds() : 45);
                exEntity.setSequenceOrder(ex.sequenceOrder() > 0 ? ex.sequenceOrder() : order++);
                entity.addExercise(exEntity);
            }
        }

        WorkoutTemplateEntity updated = templateRepository.save(entity);
        return mapTemplateToDTO(updated);
    }

    @Transactional
    public void deleteTemplate(Long userId, Long templateId) {
        WorkoutTemplateEntity entity = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found"));
        if (entity.isPreset() || (entity.getUserId() != null && !entity.getUserId().equals(userId))) {
            throw new IllegalArgumentException("Cannot delete preset or unauthorized template.");
        }
        entity.setActive(false);
        templateRepository.save(entity);
    }

    @Transactional
    public List<UserWorkoutScheduleDTO> getWeeklySchedule(Long userId, LocalDate date) {
        LocalDate startDate = date != null ? date.with(DayOfWeek.MONDAY) : LocalDate.now().with(DayOfWeek.MONDAY);
        LocalDate endDate = startDate.plusDays(6);

        List<UserWorkoutScheduleEntity> existing = scheduleRepository
                .findByUserIdAndScheduledDateBetweenOrderByScheduledDateAsc(userId, startDate, endDate);

        if (existing.isEmpty()) {
            existing = initializeDefaultWeeklySchedule(userId, startDate);
        }

        return existing.stream().map(this::mapScheduleToDTO).toList();
    }

    @Transactional
    public List<UserWorkoutScheduleDTO> missedToday(Long userId, LocalDate date) {
        LocalDate targetDate = date != null ? date : LocalDate.now();

        List<UserWorkoutScheduleEntity> futureSchedules = scheduleRepository
                .findByUserIdAndScheduledDateGreaterThanEqualOrderByScheduledDateAsc(userId, targetDate);

        if (futureSchedules.isEmpty()) {
            getWeeklySchedule(userId, targetDate);
            futureSchedules = scheduleRepository
                    .findByUserIdAndScheduledDateGreaterThanEqualOrderByScheduledDateAsc(userId, targetDate);
        }

        UserWorkoutScheduleEntity todaySchedule = futureSchedules.stream()
                .filter(s -> s.getScheduledDate().equals(targetDate))
                .findFirst()
                .orElse(null);

        if (todaySchedule != null) {
            todaySchedule.setStatus("MISSED");
            scheduleRepository.save(todaySchedule);
        }

        // Shift future workout assignments forward by 1 day
        for (int i = 0; i < futureSchedules.size() - 1; i++) {
            UserWorkoutScheduleEntity current = futureSchedules.get(i);
            UserWorkoutScheduleEntity next = futureSchedules.get(i + 1);
            next.setTemplate(current.getTemplate());
            next.setCustomTitle(current.getCustomTitle());
        }

        // Generate next day schedule item if needed
        LocalDate lastDate = futureSchedules.get(futureSchedules.size() - 1).getScheduledDate();
        UserWorkoutScheduleEntity newTail = new UserWorkoutScheduleEntity();
        newTail.setUserId(userId);
        newTail.setScheduledDate(lastDate.plusDays(1));
        newTail.setStatus("PLANNED");
        scheduleRepository.save(newTail);

        LocalDate monday = targetDate.with(DayOfWeek.MONDAY);
        return getWeeklySchedule(userId, monday);
    }

    @Transactional
    public UserWorkoutScheduleDTO completeWorkout(Long userId, Long scheduleId, String notes) {
        UserWorkoutScheduleEntity schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new IllegalArgumentException("Schedule not found with ID: " + scheduleId));

        if (!schedule.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized access to schedule item.");
        }

        schedule.setStatus("COMPLETED");
        schedule.setCompletedAt(LocalDateTime.now());
        if (notes != null && !notes.isBlank()) {
            schedule.setNotes(notes);
        }

        UserWorkoutScheduleEntity saved = scheduleRepository.save(schedule);
        return mapScheduleToDTO(saved);
    }

    @Transactional
    public List<UserWorkoutScheduleDTO> applyTemplateCycle(Long userId, ApplyTemplateRequest request) {
        LocalDate startDate = request.startDate() != null ? request.startDate().with(DayOfWeek.MONDAY) : LocalDate.now().with(DayOfWeek.MONDAY);
        List<Long> templateIds = request.templateIdsInOrder();

        if (templateIds == null || templateIds.isEmpty()) {
            throw new IllegalArgumentException("Template IDs list must not be empty.");
        }

        for (int i = 0; i < 7; i++) {
            LocalDate day = startDate.plusDays(i);
            Long templateId = templateIds.get(i % templateIds.size());
            WorkoutTemplateEntity template = templateId != null ? templateRepository.findById(templateId).orElse(null) : null;

            UserWorkoutScheduleEntity schedule = scheduleRepository.findByUserIdAndScheduledDate(userId, day)
                    .orElseGet(() -> {
                        UserWorkoutScheduleEntity s = new UserWorkoutScheduleEntity();
                        s.setUserId(userId);
                        s.setScheduledDate(day);
                        return s;
                    });

            if (template != null) {
                schedule.setTemplate(template);
                schedule.setCustomTitle(template.getName());
                schedule.setStatus("PLANNED");
            } else {
                schedule.setTemplate(null);
                schedule.setCustomTitle("Rest Day");
                schedule.setStatus("REST");
            }
            scheduleRepository.save(schedule);
        }

        return getWeeklySchedule(userId, startDate);
    }

    private List<UserWorkoutScheduleEntity> initializeDefaultWeeklySchedule(Long userId, LocalDate startDate) {
        List<WorkoutTemplateEntity> presets = templateRepository.findAllAvailableForUser(userId);
        WorkoutTemplateEntity push = presets.stream().filter(t -> "PUSH".equalsIgnoreCase(t.getCategory())).findFirst().orElse(null);
        WorkoutTemplateEntity pull = presets.stream().filter(t -> "PULL".equalsIgnoreCase(t.getCategory())).findFirst().orElse(null);
        WorkoutTemplateEntity legs = presets.stream().filter(t -> "LEGS".equalsIgnoreCase(t.getCategory())).findFirst().orElse(null);

        List<UserWorkoutScheduleEntity> result = new ArrayList<>();
        WorkoutTemplateEntity[] rotation = new WorkoutTemplateEntity[]{push, pull, null, legs, push, pull, null};

        for (int i = 0; i < 7; i++) {
            LocalDate day = startDate.plusDays(i);
            WorkoutTemplateEntity t = rotation[i];

            UserWorkoutScheduleEntity s = new UserWorkoutScheduleEntity();
            s.setUserId(userId);
            s.setScheduledDate(day);

            if (t != null) {
                s.setTemplate(t);
                s.setCustomTitle(t.getName());
                s.setStatus("PLANNED");
            } else {
                s.setTemplate(null);
                s.setCustomTitle("Rest Day");
                s.setStatus("REST");
            }

            result.add(scheduleRepository.save(s));
        }

        return result;
    }

    private WorkoutTemplateDTO mapTemplateToDTO(WorkoutTemplateEntity entity) {
        if (entity == null) return null;
        List<WorkoutTemplateExerciseDTO> exercises = entity.getExercises().stream()
                .map(e -> new WorkoutTemplateExerciseDTO(
                        e.getId(),
                        e.getUuid(),
                        e.getExerciseName(),
                        e.getSets(),
                        e.getReps(),
                        e.getRestSeconds(),
                        e.getSequenceOrder()
                )).toList();

        return new WorkoutTemplateDTO(
                entity.getId(),
                entity.getUuid(),
                entity.getName(),
                entity.getCategory(),
                entity.getDescription(),
                entity.isPreset(),
                exercises
        );
    }

    private UserWorkoutScheduleDTO mapScheduleToDTO(UserWorkoutScheduleEntity entity) {
        return new UserWorkoutScheduleDTO(
                entity.getId(),
                entity.getUuid(),
                entity.getScheduledDate(),
                mapTemplateToDTO(entity.getTemplate()),
                entity.getCustomTitle() != null ? entity.getCustomTitle() : (entity.getTemplate() != null ? entity.getTemplate().getName() : "Rest Day"),
                entity.getStatus(),
                entity.getCompletedAt(),
                entity.getNotes()
        );
    }
}
