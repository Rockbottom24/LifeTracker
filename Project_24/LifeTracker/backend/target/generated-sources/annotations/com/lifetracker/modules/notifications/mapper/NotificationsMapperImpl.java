package com.lifetracker.modules.notifications.mapper;

import com.lifetracker.modules.notifications.dto.NotificationsResponse;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2026-06-28T21:42:28+0530",
    comments = "version: 1.5.5.Final, compiler: javac, environment: Java 21.0.11 (Red Hat, Inc.)"
)
@Component
public class NotificationsMapperImpl implements NotificationsMapper {

    @Override
    public NotificationsResponse toResponse(String message) {
        if ( message == null ) {
            return null;
        }

        String message1 = null;

        message1 = message;

        NotificationsResponse notificationsResponse = new NotificationsResponse( message1 );

        return notificationsResponse;
    }
}
