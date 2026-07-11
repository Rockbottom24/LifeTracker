package com.lifetracker.modules.auth.api;

import com.lifetracker.modules.auth.dto.AuthResponse;
import com.lifetracker.modules.auth.dto.LoginRequest;
import com.lifetracker.modules.auth.dto.RefreshTokenRequest;
import com.lifetracker.modules.auth.dto.RegisterRequest;
import com.lifetracker.modules.auth.dto.UserResponse;
import com.lifetracker.modules.auth.service.AuthService;
import com.lifetracker.shared.application.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@Validated
@Tag(name = "Authentication")
public class AuthController {
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @Operation(summary = "Register a new user")
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Registration successful", authService.register(request)));
    }

    @Operation(summary = "Login with email and password")
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Login successful", authService.login(request)));
    }

    @Operation(summary = "Refresh access token using a refresh token")
    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Token refreshed", authService.refresh(request.refreshToken())));
    }

    @Operation(summary = "Logout and revoke the current refresh token")
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestBody(required = false) RefreshTokenRequest request) {
        if (request != null) {
            authService.logout(request.refreshToken());
        }
        return ResponseEntity.ok(ApiResponse.success("Logout successful", null));
    }

    @Operation(summary = "Get the current authenticated user")
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> me() {
        return ResponseEntity.ok(ApiResponse.success("Current user retrieved", authService.getCurrentUser()));
    }
}
