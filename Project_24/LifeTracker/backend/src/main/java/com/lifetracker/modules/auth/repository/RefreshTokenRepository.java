package com.lifetracker.modules.auth.repository;

import com.lifetracker.modules.auth.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
    Optional<RefreshToken> findByTokenHash(String tokenHash);

    @Modifying
    @Query("update RefreshToken t set t.revokedAt = CURRENT_TIMESTAMP where t.user.id = :userId and t.revokedAt is null")
    int revokeAllActiveForUser(@Param("userId") Long userId);
}
