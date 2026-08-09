package com.lifetracker.modules.workouts.dto;

import java.util.List;
import java.util.UUID;

public record WorkoutTemplateDTO(
        Long id,
        UUID uuid,
        String name,
        String category,
        String description,
        boolean isPreset,
        List<WorkoutTemplateExerciseDTO> exercises
) {}
