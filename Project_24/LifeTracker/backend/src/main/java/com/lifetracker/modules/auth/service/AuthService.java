package com.lifetracker.modules.auth.service;

import com.lifetracker.modules.auth.dto.AuthResponse;
import com.lifetracker.modules.auth.dto.LoginRequest;
import com.lifetracker.modules.auth.dto.RegisterRequest;
import com.lifetracker.modules.auth.dto.UserResponse;

public interface AuthService {
    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    UserResponse getCurrentUser();
}
