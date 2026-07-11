package com.lifetracker.modules.auth.service;

import com.lifetracker.modules.auth.dto.AuthResponse;
import com.lifetracker.modules.auth.dto.LoginRequest;
import com.lifetracker.modules.auth.dto.RegisterRequest;
import com.lifetracker.modules.auth.dto.UserResponse;
import com.lifetracker.modules.auth.entity.AppUser;
import com.lifetracker.modules.auth.entity.RefreshToken;
import com.lifetracker.modules.auth.repository.AppUserRepository;
import com.lifetracker.modules.auth.repository.RefreshTokenRepository;
import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.auth.security.JwtService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.Locale;
import java.util.UUID;

@Service
public class AuthServiceImpl implements AuthService {
    private final AppUserRepository appUserRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final CurrentUserService currentUserService;
    private final long accessExpirationMs;
    private final long refreshExpirationMs;
    private final SecureRandom secureRandom = new SecureRandom();

    public AuthServiceImpl(
            AppUserRepository appUserRepository,
            RefreshTokenRepository refreshTokenRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            CurrentUserService currentUserService,
            @Value("${lifetracker.jwt.expiration-ms:900000}") long accessExpirationMs,
            @Value("${lifetracker.jwt.refresh-expiration-ms:7776000000}") long refreshExpirationMs
    ) {
        this.appUserRepository = appUserRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.currentUserService = currentUserService;
        this.accessExpirationMs = accessExpirationMs;
        this.refreshExpirationMs = refreshExpirationMs;
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
    @Transactional
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
    @Transactional
    public AuthResponse refresh(String refreshTokenValue) {
        if (refreshTokenValue == null || refreshTokenValue.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token is required");
        }

        RefreshToken existing = refreshTokenRepository.findByTokenHash(hashToken(refreshTokenValue.trim()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token"));

        if (!existing.isActive()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token is expired or revoked");
        }

        AppUser user = existing.getUser();
        if (!user.isActive()) {
            existing.setRevokedAt(LocalDateTime.now());
            refreshTokenRepository.save(existing);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Account is inactive");
        }

        String nextRawToken = generateRawRefreshToken();
        RefreshToken replacement = createRefreshTokenEntity(user, nextRawToken);
        RefreshToken savedReplacement = refreshTokenRepository.save(replacement);

        existing.setRevokedAt(LocalDateTime.now());
        existing.setReplacedByTokenId(savedReplacement.getId());
        refreshTokenRepository.save(existing);

        return toAuthResponse(user, jwtService.generateToken(user.getId(), user.getEmail()), nextRawToken);
    }

    @Override
    @Transactional
    public void logout(String refreshTokenValue) {
        if (refreshTokenValue == null || refreshTokenValue.isBlank()) {
            return;
        }
        refreshTokenRepository.findByTokenHash(hashToken(refreshTokenValue.trim())).ifPresent(token -> {
            if (token.getRevokedAt() == null) {
                token.setRevokedAt(LocalDateTime.now());
                refreshTokenRepository.save(token);
            }
        });
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponse getCurrentUser() {
        AppUser user = currentUserService.getCurrentUser();
        return toUserResponse(user);
    }

    private AuthResponse buildAuthResponse(AppUser user) {
        String accessToken = jwtService.generateToken(user.getId(), user.getEmail());
        String refreshToken = generateRawRefreshToken();
        refreshTokenRepository.save(createRefreshTokenEntity(user, refreshToken));
        return toAuthResponse(user, accessToken, refreshToken);
    }

    private AuthResponse toAuthResponse(AppUser user, String accessToken, String refreshToken) {
        return new AuthResponse(
                accessToken,
                refreshToken,
                "Bearer",
                accessExpirationMs / 1000,
                user.getId(),
                user.getUuid(),
                user.getEmail(),
                user.getFirstName(),
                user.getHouseKey()
        );
    }

    private RefreshToken createRefreshTokenEntity(AppUser user, String rawToken) {
        LocalDateTime now = LocalDateTime.now();
        RefreshToken token = new RefreshToken();
        token.setUuid(UUID.randomUUID());
        token.setUser(user);
        token.setTokenHash(hashToken(rawToken));
        token.setExpiresAt(now.plusSeconds(Math.max(1, refreshExpirationMs / 1000)));
        token.setCreatedAt(now);
        return token;
    }

    private String generateRawRefreshToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    private String hashToken(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hashed);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 is required for refresh token hashing", ex);
        }
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
