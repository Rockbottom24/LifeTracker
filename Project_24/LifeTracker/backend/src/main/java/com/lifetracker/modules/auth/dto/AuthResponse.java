package com.lifetracker.modules.auth.dto;

import java.util.UUID;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        Long expiresIn,
        Long userId,
        UUID uuid,
        String email,
        String firstName,
        String houseKey
) {
}
