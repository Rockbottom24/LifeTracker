package com.lifetracker.modules.workouts.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record CreateTemplateRequest(
        @NotBlank(message = "Template name is required") String name,
        @NotBlank(message = "Category is required") String category,
        String description,
        List<ExerciseInput> exercises
) {
    public record ExerciseInput(
            @NotBlank(message = "Exercise name is required") String exerciseName,
            int sets,
            String reps,
            int restSeconds,
            int sequenceOrder
    ) {}
}
