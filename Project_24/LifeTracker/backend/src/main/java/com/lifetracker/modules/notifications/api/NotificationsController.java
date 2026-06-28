package com.lifetracker.modules.notifications.api;

import com.lifetracker.shared.application.dto.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationsController {
    @GetMapping
    public ApiResponse<String> getNotifications() {
        return ApiResponse.success("Notifications module ready");
    }
}
