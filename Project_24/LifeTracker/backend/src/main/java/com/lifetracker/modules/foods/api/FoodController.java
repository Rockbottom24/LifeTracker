package com.lifetracker.modules.foods.api;

import com.lifetracker.modules.foods.dto.CreateFoodRequest;
import com.lifetracker.modules.foods.dto.FoodResponse;
import com.lifetracker.modules.foods.dto.UpdateFoodRequest;
import com.lifetracker.modules.foods.service.FoodService;
import com.lifetracker.shared.application.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
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
import com.lifetracker.modules.foods.dto.BarcodeLookupResponse;
import java.util.List;

@Tag(name = "Foods", description = "Food library APIs for the Nutrition module")
@Validated
@RestController
@RequestMapping("/api/v1/foods")
public class FoodController {
    private final FoodService foodService;

    public FoodController(FoodService foodService) {
        this.foodService = foodService;
    }

    @Operation(summary = "List all visible foods")
    @GetMapping
    public ResponseEntity<ApiResponse<List<FoodResponse>>> getFoods() {
        return ResponseEntity.ok(
                ApiResponse.success("Foods retrieved successfully", foodService.getAllFoods())
        );
    }

    @Operation(summary = "Search foods by name")
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<FoodResponse>>> searchFoods(
            @RequestParam @NotBlank String query
    ) {
        return ResponseEntity.ok(
                ApiResponse.success("Food search completed", foodService.searchFoods(query))
        );
    }

    @Operation(summary = "Get a food by id")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<FoodResponse>> getFoodById(@PathVariable @Positive Long id) {
        return ResponseEntity.ok(
                ApiResponse.success("Food retrieved successfully", foodService.getFoodById(id))
        );
    }

    @Operation(summary = "Create a custom food")
    @PostMapping
    public ResponseEntity<ApiResponse<FoodResponse>> createFood(@Valid @RequestBody CreateFoodRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Food created successfully", foodService.createFood(request)));
    }

    @Operation(summary = "Update a custom food")
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<FoodResponse>> updateFood(
            @PathVariable @Positive Long id,
            @Valid @RequestBody UpdateFoodRequest request
    ) {
        return ResponseEntity.ok(
                ApiResponse.success("Food updated successfully", foodService.updateFood(id, request))
        );
    }

    @Operation(summary = "Soft delete a custom food")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFood(@PathVariable @Positive Long id) {
        foodService.deleteFood(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/barcode/{barcode}")
    public ResponseEntity<ApiResponse<BarcodeLookupResponse>> lookupBarcode(
            @PathVariable String barcode
    ) {
        return ResponseEntity.ok(
                ApiResponse.success(
                        "Barcode lookup successful",
                        foodService.lookupBarcode(barcode)
                )
        );
    }


    

}
