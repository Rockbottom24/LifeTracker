package com.lifetracker.modules.dashboard.api;

import com.lifetracker.modules.dashboard.dto.DashboardResponse;
import com.lifetracker.modules.dashboard.service.DashboardService;
import com.lifetracker.shared.application.dto.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/dashboard")
public class DashboardController {
    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping
    public ApiResponse<DashboardResponse> getDashboard() {
        return ApiResponse.success("Dashboard retrieved successfully", dashboardService.getDashboard());
    }
}
