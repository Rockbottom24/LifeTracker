package com.lifetracker.modules.workouts.api;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.workouts.dto.ApplyTemplateRequest;
import com.lifetracker.modules.workouts.dto.CreateTemplateRequest;
import com.lifetracker.modules.workouts.dto.UserWorkoutScheduleDTO;
import com.lifetracker.modules.workouts.dto.WorkoutTemplateDTO;
import com.lifetracker.modules.workouts.service.WorkoutsService;
import com.lifetracker.shared.application.dto.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/workouts")
public class WorkoutsController {

    private final WorkoutsService workoutsService;
    private final CurrentUserService currentUserService;

    public WorkoutsController(WorkoutsService workoutsService, CurrentUserService currentUserService) {
        this.workoutsService = workoutsService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/templates")
    public ApiResponse<List<WorkoutTemplateDTO>> getTemplates() {
        Long userId = currentUserService.getCurrentUserId();
        return ApiResponse.success("Templates retrieved successfully", workoutsService.getAvailableTemplates(userId));
    }

    @PostMapping("/templates")
    public ApiResponse<WorkoutTemplateDTO> createTemplate(@Valid @RequestBody CreateTemplateRequest request) {
        Long userId = currentUserService.getCurrentUserId();
        return ApiResponse.success("Template created successfully", workoutsService.createTemplate(userId, request));
    }

    @PutMapping("/templates/{id}")
    public ApiResponse<WorkoutTemplateDTO> updateTemplate(@PathVariable Long id,
                                                           @Valid @RequestBody CreateTemplateRequest request) {
        Long userId = currentUserService.getCurrentUserId();
        return ApiResponse.success("Template updated successfully", workoutsService.updateTemplate(userId, id, request));
    }

    @DeleteMapping("/templates/{id}")
    public ApiResponse<Void> deleteTemplate(@PathVariable Long id) {
        Long userId = currentUserService.getCurrentUserId();
        workoutsService.deleteTemplate(userId, id);
        return ApiResponse.success("Template deleted successfully", null);
    }

    @GetMapping("/schedule")
    public ApiResponse<List<UserWorkoutScheduleDTO>> getWeeklySchedule(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        Long userId = currentUserService.getCurrentUserId();
        return ApiResponse.success("Weekly schedule retrieved successfully", workoutsService.getWeeklySchedule(userId, date));
    }

    @PostMapping("/schedule/missed-today")
    public ApiResponse<List<UserWorkoutScheduleDTO>> missedToday(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        Long userId = currentUserService.getCurrentUserId();
        return ApiResponse.success("Workout auto-shifted to tomorrow", workoutsService.missedToday(userId, date));
    }

    @PostMapping("/schedule/{id}/complete")
    public ApiResponse<UserWorkoutScheduleDTO> completeWorkout(
            @PathVariable Long id,
            @RequestParam(required = false) String notes) {
        Long userId = currentUserService.getCurrentUserId();
        return ApiResponse.success("Workout marked as completed", workoutsService.completeWorkout(userId, id, notes));
    }

    @PostMapping("/schedule/apply-cycle")
    public ApiResponse<List<UserWorkoutScheduleDTO>> applyCycle(@RequestBody ApplyTemplateRequest request) {
        Long userId = currentUserService.getCurrentUserId();
        return ApiResponse.success("Cycle template applied to schedule", workoutsService.applyTemplateCycle(userId, request));
    }
}
