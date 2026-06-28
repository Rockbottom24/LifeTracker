package com.lifetracker.modules.workouts.mapper;

import com.lifetracker.modules.workouts.dto.WorkoutsResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface WorkoutsMapper {
    WorkoutsResponse toResponse(String message);
}
