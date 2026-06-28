package com.lifetracker.modules.foods.mapper;

import com.lifetracker.modules.foods.dto.CreateFoodRequest;
import com.lifetracker.modules.foods.dto.FoodResponse;
import com.lifetracker.modules.foods.dto.UpdateFoodRequest;
import com.lifetracker.modules.foods.entity.FoodItem;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Component
public class FoodMapper {

    public FoodItem toEntity(CreateFoodRequest request, Long ownerUserId) {
        FoodItem food = new FoodItem();
        food.setUuid(UUID.randomUUID());
        food.setOwnerUserId(ownerUserId);
        food.setSystem(false);
        food.setActive(true);
        food.setDisplayOrder(0);
        applyCreateRequest(food, request);
        food.setCreatedAt(LocalDateTime.now());
        food.setUpdatedAt(LocalDateTime.now());
        return food;
    }

    public void updateEntity(FoodItem food, UpdateFoodRequest request) {
        applyUpdateRequest(food, request);
        food.setUpdatedAt(LocalDateTime.now());
    }

    public FoodResponse toResponse(FoodItem food) {
        return new FoodResponse(
                food.getId(),
                food.getUuid(),
                food.getName(),
                food.getCategory(),
                food.getServingUnit(),
                food.getReferenceQuantity(),
                food.getReferenceWeight(),
                food.getCalories(),
                food.getProtein(),
                food.getCarbs(),
                food.getFat(),
                food.getFiber(),
                food.isSystem(),
                normalize(food.getBarcode()),
                normalize(food.getBrand()),
                normalize(food.getImageUrl()),
                normalize(food.getSource())
        );
    }

    public List<FoodResponse> toResponseList(List<FoodItem> foods) {
        return foods.stream().map(this::toResponse).toList();
    }

    private void applyCreateRequest(FoodItem food, CreateFoodRequest request) {
        food.setName(request.name().trim());
        food.setCategory(request.category());
        food.setServingUnit(request.servingUnit());
        food.setReferenceQuantity(request.referenceQuantity());
        food.setReferenceWeight(request.referenceWeight());
        food.setCalories(request.calories());
        food.setProtein(request.protein());
        food.setCarbs(request.carbs());
        food.setFat(request.fat());
        food.setFiber(request.fiber());
        food.setBarcode(normalizeNullable(request.barcode()));
        food.setBrand(normalizeNullable(request.brand()));
        food.setImageUrl(normalizeNullable(request.imageUrl()));
        food.setSource(normalizeNullable(request.source()));
    }

    private void applyUpdateRequest(FoodItem food, UpdateFoodRequest request) {
        food.setName(request.name().trim());
        food.setCategory(request.category());
        food.setServingUnit(request.servingUnit());
        food.setReferenceQuantity(request.referenceQuantity());
        food.setReferenceWeight(request.referenceWeight());
        food.setCalories(request.calories());
        food.setProtein(request.protein());
        food.setCarbs(request.carbs());
        food.setFat(request.fat());
        food.setFiber(request.fiber());
        if (request.barcode() != null) {
            food.setBarcode(normalizeNullable(request.barcode()));
        }
        if (request.brand() != null) {
            food.setBrand(normalizeNullable(request.brand()));
        }
        if (request.imageUrl() != null) {
            food.setImageUrl(normalizeNullable(request.imageUrl()));
        }
        if (request.source() != null) {
            food.setSource(normalizeNullable(request.source()));
        }
    }

    private String normalize(String value) {
        return value == null ? "" : value;
    }

    private String normalizeNullable(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
