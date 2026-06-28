package com.lifetracker.modules.auth.dto;

import java.util.UUID;

public record UserResponse(
        Long id,
        UUID uuid,
        String email,
        String firstName,
        String houseKey
) {
}
