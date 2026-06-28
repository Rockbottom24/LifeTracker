package com.lifetracker.modules.foods.service;

import com.lifetracker.modules.foods.dto.CreateFoodRequest;
import com.lifetracker.modules.foods.dto.FoodResponse;
import com.lifetracker.modules.foods.dto.UpdateFoodRequest;
import com.lifetracker.modules.foods.dto.BarcodeLookupResponse;

import java.util.List;

public interface FoodService {
    List<FoodResponse> getAllFoods();

    List<FoodResponse> searchFoods(String query);

    FoodResponse getFoodById(Long id);

    FoodResponse createFood(CreateFoodRequest request);

    FoodResponse updateFood(Long id, UpdateFoodRequest request);

    void deleteFood(Long id);

    BarcodeLookupResponse lookupBarcode(String barcode);

}
