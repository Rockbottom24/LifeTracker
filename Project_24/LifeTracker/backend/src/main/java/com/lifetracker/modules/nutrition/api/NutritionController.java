package com.lifetracker.modules.nutrition.api;

import com.lifetracker.modules.nutrition.dto.NutritionDashboardResponse;
import com.lifetracker.modules.nutrition.dto.NutritionGoalsResponse;
import com.lifetracker.modules.nutrition.dto.UpdateNutritionGoalsRequest;
import com.lifetracker.modules.nutrition.service.NutritionService;
import com.lifetracker.shared.application.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

@Tag(name = "Nutrition", description = "Daily nutrition dashboard and goals APIs")
@Validated
@RestController
@RequestMapping("/api/v1/nutrition")
public class NutritionController {
    private final NutritionService nutritionService;

    public NutritionController(NutritionService nutritionService) {
        this.nutritionService = nutritionService;
    }

    @Operation(summary = "Get daily nutrition dashboard")
    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<NutritionDashboardResponse>> getDashboard(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        return ResponseEntity.ok(
                ApiResponse.success("Nutrition dashboard retrieved successfully", nutritionService.getDashboard(date))
        );
    }

    @Operation(summary = "Get nutrition goals")
    @GetMapping("/goals")
    public ResponseEntity<ApiResponse<NutritionGoalsResponse>> getGoals() {
        return ResponseEntity.ok(
                ApiResponse.success("Nutrition goals retrieved successfully", nutritionService.getGoals())
        );
    }

    @Operation(summary = "Update nutrition goals")
    @PutMapping("/goals")
    public ResponseEntity<ApiResponse<NutritionGoalsResponse>> updateGoals(
            @Valid @RequestBody UpdateNutritionGoalsRequest request
    ) {
        return ResponseEntity.ok(
                ApiResponse.success("Nutrition goals updated successfully", nutritionService.updateGoals(request))
        );
    }
}
