package com.lifetracker.modules.workouts.api;

import com.lifetracker.shared.application.dto.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/workouts")
public class WorkoutsController {
    @GetMapping
    public ApiResponse<String> getWorkouts() {
        return ApiResponse.success("Workouts module ready");
    }
}
