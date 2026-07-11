package com.lifetracker.modules.profile.api;

import com.lifetracker.modules.profile.dto.DailyPerformanceResponse;
import com.lifetracker.modules.profile.dto.ProfileResponse;
import com.lifetracker.modules.profile.service.ProfileService;
import com.lifetracker.shared.application.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/profile")
@Tag(name = "Profile")
public class ProfileController {
    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @Operation(summary = "Get the current user's profile and recent performance chronicle")
    @GetMapping
    public ResponseEntity<ApiResponse<ProfileResponse>> getProfile() {
        return ResponseEntity.ok(ApiResponse.success("Profile retrieved", profileService.getProfile()));
    }

    @Operation(summary = "Get historical performance for a specific date")
    @GetMapping("/performance/{date}")
    public ResponseEntity<ApiResponse<DailyPerformanceResponse>> getDailyPerformance(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                "Daily performance retrieved",
                profileService.getDailyPerformance(date)
        ));
    }
}
