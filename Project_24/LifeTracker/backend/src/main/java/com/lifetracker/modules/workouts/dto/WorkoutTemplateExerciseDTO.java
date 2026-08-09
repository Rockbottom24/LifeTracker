package com.lifetracker.modules.workouts.dto;

import java.util.UUID;

public record WorkoutTemplateExerciseDTO(
        Long id,
        UUID uuid,
        String exerciseName,
        int sets,
        String reps,
        int restSeconds,
        int sequenceOrder
) {}
