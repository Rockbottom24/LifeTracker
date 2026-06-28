package com.lifetracker.modules.settings.mapper;

import com.lifetracker.modules.settings.dto.SettingsResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface SettingsMapper {
    SettingsResponse toResponse(String message);
}
