package com.lifetracker.modules.meals.mapper;

import com.lifetracker.modules.foods.entity.FoodItem;
import com.lifetracker.modules.meals.dto.CreateMealRequest;
import com.lifetracker.modules.meals.dto.MealItemRequest;
import com.lifetracker.modules.meals.dto.MealItemResponse;
import com.lifetracker.modules.meals.dto.MealResponse;
import com.lifetracker.modules.meals.dto.UpdateMealRequest;
import com.lifetracker.modules.meals.entity.MealLog;
import com.lifetracker.modules.meals.entity.MealLogItem;
import com.lifetracker.modules.meals.service.MealNutritionCalculator;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class MealMapper {

    public MealLog toEntity(CreateMealRequest request, Long ownerUserId) {
        MealLog meal = new MealLog();
        meal.setUuid(UUID.randomUUID());
        meal.setOwnerUserId(ownerUserId);
        meal.setMealType(request.mealType());
        meal.setMealDate(request.mealDate());
        meal.setNotes(normalizeNotes(request.notes()));
        meal.setCreatedAt(LocalDateTime.now());
        meal.setUpdatedAt(LocalDateTime.now());
        return meal;
    }

    public void updateEntity(MealLog meal, UpdateMealRequest request) {
        meal.setMealType(request.mealType());
        meal.setMealDate(request.mealDate());
        meal.setNotes(normalizeNotes(request.notes()));
        meal.setUpdatedAt(LocalDateTime.now());
    }

    public List<MealLogItem> toItems(Long mealLogId, List<MealItemRequest> requests, Map<Long, FoodItem> foodsById) {
        List<MealLogItem> items = new ArrayList<>();
        for (int index = 0; index < requests.size(); index++) {
            MealItemRequest request = requests.get(index);
            FoodItem food = foodsById.get(request.foodItemId());
            if (food == null) {
                continue;
            }
            MealLogItem item = new MealLogItem();
            item.setMealLogId(mealLogId);
            item.setFoodItemId(food.getId());
            item.setQuantity(request.quantity());
            item.setUnit(request.unit());
            item.setCalories(MealNutritionCalculator.calculate(food.getCalories(), request.quantity(), request.unit(), food.getServingUnit(), food.getReferenceQuantity(), food.getReferenceWeight()));
            item.setProtein(MealNutritionCalculator.calculate(food.getProtein(), request.quantity(), request.unit(), food.getServingUnit(), food.getReferenceQuantity(), food.getReferenceWeight()));
            item.setCarbs(MealNutritionCalculator.calculate(food.getCarbs(), request.quantity(), request.unit(), food.getServingUnit(), food.getReferenceQuantity(), food.getReferenceWeight()));
            item.setFat(MealNutritionCalculator.calculate(food.getFat(), request.quantity(), request.unit(), food.getServingUnit(), food.getReferenceQuantity(), food.getReferenceWeight()));
            item.setFiber(MealNutritionCalculator.calculate(food.getFiber(), request.quantity(), request.unit(), food.getServingUnit(), food.getReferenceQuantity(), food.getReferenceWeight()));
            item.setDisplayOrder(index);
            items.add(item);
        }
        return items;
    }

    public MealResponse toResponse(MealLog meal, List<MealLogItem> items, Map<Long, FoodItem> foodsById) {
        List<MealItemResponse> itemResponses = items.stream()
                .map(item -> toItemResponse(item, foodsById.get(item.getFoodItemId())))
                .toList();

        return new MealResponse(
                meal.getId(),
                meal.getUuid(),
                meal.getMealType(),
                meal.getMealDate(),
                meal.getNotes(),
                itemResponses,
                sumField(items, MealLogItem::getCalories),
                sumField(items, MealLogItem::getProtein),
                sumField(items, MealLogItem::getCarbs),
                sumField(items, MealLogItem::getFat),
                sumField(items, MealLogItem::getFiber)
        );
    }

    public List<MealResponse> toResponseList(List<MealLog> meals, Map<Long, List<MealLogItem>> itemsByMealId, Map<Long, FoodItem> foodsById) {
        return meals.stream()
                .map(meal -> toResponse(meal, itemsByMealId.getOrDefault(meal.getId(), List.of()), foodsById))
                .toList();
    }

    private MealItemResponse toItemResponse(MealLogItem item, FoodItem food) {
        String foodName = food != null ? food.getName() : "Unknown food";
        return new MealItemResponse(
                item.getId(),
                item.getFoodItemId(),
                foodName,
                item.getQuantity(),
                item.getUnit(),
                item.getCalories(),
                item.getProtein(),
                item.getCarbs(),
                item.getFat(),
                item.getFiber(),
                item.getDisplayOrder()
        );
    }

    private BigDecimal sumField(List<MealLogItem> items, java.util.function.Function<MealLogItem, BigDecimal> extractor) {
        return items.stream()
                .map(extractor)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private String normalizeNotes(String notes) {
        if (notes == null) {
            return null;
        }
        String trimmed = notes.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
