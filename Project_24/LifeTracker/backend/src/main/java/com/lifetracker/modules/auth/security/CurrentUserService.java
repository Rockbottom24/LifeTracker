package com.lifetracker.modules.auth.security;

import com.lifetracker.modules.auth.entity.AppUser;
import com.lifetracker.modules.auth.repository.AppUserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class CurrentUserService {
    private final AppUserRepository appUserRepository;

    public CurrentUserService(AppUserRepository appUserRepository) {
        this.appUserRepository = appUserRepository;
    }

    public Long getCurrentUserId() {
        return getAuthenticatedUser().getId();
    }

    public AppUser getCurrentUser() {
        return appUserRepository.findById(getCurrentUserId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
    }

    public AuthenticatedUser getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof AuthenticatedUser user)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Unauthorized");
        }
        return user;
    }
}
