package com.lifetracker.modules.settings.api;

import com.lifetracker.shared.application.dto.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/settings")
public class SettingsController {
    @GetMapping
    public ApiResponse<String> getSettings() {
        return ApiResponse.success("Settings module ready");
    }
}
