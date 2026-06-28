package com.lifetracker.modules.meals.api;

import com.lifetracker.modules.meals.dto.CreateMealRequest;
import com.lifetracker.modules.meals.dto.MealResponse;
import com.lifetracker.modules.meals.dto.UpdateMealRequest;
import com.lifetracker.modules.meals.enums.MealType;
import com.lifetracker.modules.meals.service.MealService;
import com.lifetracker.shared.application.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@Tag(name = "Meals", description = "Meal logging APIs for the Nutrition module")
@Validated
@RestController
@RequestMapping("/api/v1/meals")
public class MealController {
    private final MealService mealService;

    public MealController(MealService mealService) {
        this.mealService = mealService;
    }

    @Operation(summary = "Create a meal log")
    @PostMapping
    public ResponseEntity<ApiResponse<MealResponse>> createMeal(@Valid @RequestBody CreateMealRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Meal created successfully", mealService.createMeal(request)));
    }

    @Operation(summary = "Get today's meal logs")
    @GetMapping("/today")
    public ResponseEntity<ApiResponse<List<MealResponse>>> getTodayMeals() {
        return ResponseEntity.ok(
                ApiResponse.success("Today's meals retrieved successfully", mealService.getMealsForToday())
        );
    }

    @Operation(summary = "Get meal logs for a date")
    @GetMapping("/date/{date}")
    public ResponseEntity<ApiResponse<List<MealResponse>>> getMealsForDate(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        return ResponseEntity.ok(
                ApiResponse.success("Meals retrieved successfully", mealService.getMealsForDate(date))
        );
    }

    @Operation(summary = "Duplicate yesterday's meals for a meal type")
    @PostMapping("/duplicate-yesterday")
    public ResponseEntity<ApiResponse<List<MealResponse>>> duplicateYesterday(
            @RequestParam MealType mealType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        LocalDate targetDate = date != null ? date : LocalDate.now();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(
                        "Meals duplicated successfully",
                        mealService.duplicateYesterday(mealType, targetDate)
                ));
    }

    @Operation(summary = "Clear all meals for a meal type on a date")
    @DeleteMapping("/clear")
    public ResponseEntity<Void> clearMealsForType(
            @RequestParam MealType mealType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        LocalDate targetDate = date != null ? date : LocalDate.now();
        mealService.clearMealsForType(mealType, targetDate);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Get a meal log by id")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MealResponse>> getMealById(@PathVariable @Positive Long id) {
        return ResponseEntity.ok(
                ApiResponse.success("Meal retrieved successfully", mealService.getMealById(id))
        );
    }

    @Operation(summary = "Update a meal log")
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<MealResponse>> updateMeal(
            @PathVariable @Positive Long id,
            @Valid @RequestBody UpdateMealRequest request
    ) {
        return ResponseEntity.ok(
                ApiResponse.success("Meal updated successfully", mealService.updateMeal(id, request))
        );
    }

    @Operation(summary = "Delete a meal log")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMeal(@PathVariable @Positive Long id) {
        mealService.deleteMeal(id);
        return ResponseEntity.noContent().build();
    }
}
