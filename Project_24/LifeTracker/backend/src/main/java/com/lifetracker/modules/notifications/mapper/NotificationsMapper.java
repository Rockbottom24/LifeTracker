package com.lifetracker.modules.notifications.mapper;

import com.lifetracker.modules.notifications.dto.NotificationsResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface NotificationsMapper {
    NotificationsResponse toResponse(String message);
}
