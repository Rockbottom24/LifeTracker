package com.lifetracker.modules.auth.service;

import com.lifetracker.modules.auth.dto.AuthResponse;
import com.lifetracker.modules.auth.dto.LoginRequest;
import com.lifetracker.modules.auth.dto.RegisterRequest;
import com.lifetracker.modules.auth.dto.UserResponse;
import com.lifetracker.modules.auth.entity.AppUser;
import com.lifetracker.modules.auth.repository.AppUserRepository;
import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.auth.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Locale;
import java.util.UUID;

@Service
public class AuthServiceImpl implements AuthService {
    private final AppUserRepository appUserRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final CurrentUserService currentUserService;

    public AuthServiceImpl(
            AppUserRepository appUserRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            CurrentUserService currentUserService
    ) {
        this.appUserRepository = appUserRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.currentUserService = currentUserService;
    }

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        if (appUserRepository.existsByEmailIgnoreCase(email)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email is already registered");
        }

        LocalDateTime now = LocalDateTime.now();
        AppUser user = new AppUser();
        user.setUuid(UUID.randomUUID());
        user.setEmail(email);
        user.setFirstName(normalizeFirstName(request.firstName(), email));
        user.setDisplayName(user.getFirstName());
        user.setHouseKey(normalizeHouseKey(request.houseKey()));
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setCreatedAt(now);
        user.setUpdatedAt(now);
        user.setActive(true);

        AppUser saved = appUserRepository.save(user);
        return buildAuthResponse(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String email = normalizeEmail(request.email());
        AppUser user = appUserRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password"));

        if (!user.isActive()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Account is inactive");
        }
        if (user.getPasswordHash() == null || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password");
        }

        return buildAuthResponse(user);
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getCurrentUser() {
        AppUser user = currentUserService.getCurrentUser();
        return toUserResponse(user);
    }

    private AuthResponse buildAuthResponse(AppUser user) {
        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return new AuthResponse(
                token,
                "Bearer",
                user.getId(),
                user.getUuid(),
                user.getEmail(),
                user.getFirstName(),
                user.getHouseKey()
        );
    }

    private UserResponse toUserResponse(AppUser user) {
        return new UserResponse(
                user.getId(),
                user.getUuid(),
                user.getEmail(),
                user.getFirstName(),
                user.getHouseKey()
        );
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ENGLISH);
    }

    private String normalizeFirstName(String firstName, String email) {
        if (firstName != null && !firstName.isBlank()) {
            return firstName.trim();
        }
        int atIndex = email.indexOf('@');
        return atIndex > 0 ? email.substring(0, atIndex) : email;
    }

    private String normalizeHouseKey(String houseKey) {
        if (houseKey == null || houseKey.isBlank()) {
            return "stark";
        }
        return houseKey.trim().toLowerCase(Locale.ENGLISH);
    }
}
