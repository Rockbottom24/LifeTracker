package com.lifetracker.modules.settings.mapper;

import com.lifetracker.modules.settings.dto.SettingsResponse;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2026-06-29T20:05:51+0530",
    comments = "version: 1.5.5.Final, compiler: javac, environment: Java 21.0.11 (Red Hat, Inc.)"
)
@Component
public class SettingsMapperImpl implements SettingsMapper {

    @Override
    public SettingsResponse toResponse(String message) {
        if ( message == null ) {
            return null;
        }

        String message1 = null;

        message1 = message;

        SettingsResponse settingsResponse = new SettingsResponse( message1 );

        return settingsResponse;
    }
}
