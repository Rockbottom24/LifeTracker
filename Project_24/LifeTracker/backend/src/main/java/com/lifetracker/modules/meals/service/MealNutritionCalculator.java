package com.lifetracker.modules.meals.service;

import com.lifetracker.modules.foods.enums.ServingUnit;

import java.math.BigDecimal;
import java.math.RoundingMode;

public final class MealNutritionCalculator {
    private static final BigDecimal FIVE = new BigDecimal("5");
    private static final BigDecimal THIRTEEN_POINT_FIVE = new BigDecimal("13.5");
    private static final BigDecimal THIRTY = new BigDecimal("30");
    private static final BigDecimal FIFTY = new BigDecimal("50");
    private static final BigDecimal TWO_HUNDRED_FORTY = new BigDecimal("240");

    private MealNutritionCalculator() {
    }

    public static BigDecimal toGramEquivalent(BigDecimal quantity, ServingUnit unit) {
        return switch (unit) {
            case GRAM -> quantity;
            case ML -> quantity;
            case PIECE -> quantity.multiply(FIFTY);
            case SCOOP -> quantity.multiply(THIRTY);
            case TABLESPOON -> quantity.multiply(THIRTEEN_POINT_FIVE);
            case TEASPOON -> quantity.multiply(FIVE);
            case CUP -> quantity.multiply(TWO_HUNDRED_FORTY);
        };
    }

    public static BigDecimal calculate(
            BigDecimal macroPerReferenceServing,
            BigDecimal quantity,
            ServingUnit unit,
            ServingUnit referenceUnit,
            BigDecimal referenceQuantity,
            BigDecimal referenceWeight
    ) {
        if (macroPerReferenceServing == null || quantity == null || referenceWeight == null || referenceWeight.signum() <= 0) {
            return BigDecimal.ZERO;
        }
        BigDecimal gramEquivalent = toGramEquivalent(quantity, unit);
        BigDecimal servings = gramEquivalent.divide(referenceWeight, 6, RoundingMode.HALF_UP);
        return macroPerReferenceServing.multiply(servings).setScale(2, RoundingMode.HALF_UP);
    }
}
