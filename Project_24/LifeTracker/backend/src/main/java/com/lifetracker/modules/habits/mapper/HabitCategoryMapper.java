package com.lifetracker.modules.habits.mapper;

import com.lifetracker.modules.habits.dto.HabitCategoryResponse;
import com.lifetracker.modules.habits.entity.HabitCategory;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class HabitCategoryMapper {
    public HabitCategoryResponse toResponse(HabitCategory category) {
        return new HabitCategoryResponse(
                category.getId(),
                category.getCode(),
                category.getName(),
                category.getDescription(),
                category.getDisplayOrder(),
                category.isActive()
        );
    }

    public List<HabitCategoryResponse> toResponseList(List<HabitCategory> categories) {
        return categories.stream().map(this::toResponse).toList();
    }
}
