package com.lifetracker.modules.habits.dto;

public record HabitCategoryResponse(
        Long id,
        String code,
        String name,
        String description,
        Integer displayOrder,
        Boolean isActive
) {
}
