package com.lifetracker.modules.auth.dto;

import java.util.UUID;

public record AuthResponse(
        String accessToken,
        String tokenType,
        Long userId,
        UUID uuid,
        String email,
        String firstName,
        String houseKey
) {
}
