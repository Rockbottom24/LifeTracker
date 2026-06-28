package com.lifetracker.modules.foods.dto;

public record BarcodeLookupResponse(
    String barcode,
    boolean found,
    Long foodId,
    boolean local,
    ScannedFoodResponse food
) {}
