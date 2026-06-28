package com.lifetracker.modules.foods.dto;

public record ScannedFoodResponse(
    Long foodId,
    boolean local,
    String barcode,
    String productName,
    String brand,
    String imageUrl,

    Double calories,
    Double protein,
    Double carbs,
    Double fat,
    Double fiber
) {}
