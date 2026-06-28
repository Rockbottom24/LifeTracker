package com.lifetracker.modules.learning.api;

import com.lifetracker.modules.learning.dto.CompleteLearningRequest;
import com.lifetracker.modules.learning.dto.CreateLearningRequest;
import com.lifetracker.modules.learning.dto.LearningResponse;
import com.lifetracker.modules.learning.dto.UpdateLearningRequest;
import com.lifetracker.modules.learning.service.LearningService;
import com.lifetracker.shared.application.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Learning", description = "Learning session planning and progress APIs")
@Validated
@RestController
@RequestMapping("/api/v1/learning")
public class LearningController {
    private final LearningService learningService;

    public LearningController(LearningService learningService) {
        this.learningService = learningService;
    }

    @Operation(summary = "List all learning sessions")
    @GetMapping
    public ApiResponse<List<LearningResponse>> getSessions() {
        return ApiResponse.success("Learning sessions retrieved successfully", learningService.getAllSessions());
    }

    @Operation(summary = "Get a learning session by id")
    @GetMapping("/{id}")
    public ApiResponse<LearningResponse> getSession(@PathVariable @Positive Long id) {
        return ApiResponse.success("Learning session retrieved successfully", learningService.getSessionById(id));
    }

    @Operation(summary = "Create a learning session")
    @PostMapping
    public ApiResponse<LearningResponse> createSession(@Valid @RequestBody CreateLearningRequest request) {
        return ApiResponse.success("Learning session created successfully", learningService.createSession(request));
    }

    @Operation(summary = "Update a learning session")
    @PutMapping("/{id}")
    public ApiResponse<LearningResponse> updateSession(
            @PathVariable @Positive Long id,
            @Valid @RequestBody UpdateLearningRequest request
    ) {
        return ApiResponse.success("Learning session updated successfully", learningService.updateSession(id, request));
    }

    @Operation(summary = "Delete a learning session")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteSession(@PathVariable @Positive Long id) {
        learningService.deleteSession(id);
        return ApiResponse.<Void>success("Learning session deleted successfully", null);
    }

    @Operation(summary = "Start a learning session")
    @PostMapping("/{id}/start")
    public ApiResponse<LearningResponse> startSession(@PathVariable @Positive Long id) {
        return ApiResponse.success("Learning session started successfully", learningService.startSession(id));
    }

    @Operation(summary = "Complete a learning session")
    @PostMapping("/{id}/complete")
    public ApiResponse<LearningResponse> completeSession(
            @PathVariable @Positive Long id,
            @Valid @RequestBody CompleteLearningRequest request
    ) {
        return ApiResponse.success("Learning session completed successfully", learningService.completeSession(id, request));
    }
}
