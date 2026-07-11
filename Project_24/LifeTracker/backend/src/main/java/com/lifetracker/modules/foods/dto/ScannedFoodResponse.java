package com.lifetracker.modules.foods.dto;

import com.lifetracker.modules.foods.enums.ServingUnit;

import java.util.List;

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
        Double fiber,
        String servingSizeText,
        ServingUnit servingUnit,
        Double referenceQuantity,
        Double referenceWeight,
        Double gramsPerPiece,
        ServingUnit householdUnit,
        Double householdQuantity,
        Double householdGrams,
        List<ServingUnit> supportedUnits
) {
}
