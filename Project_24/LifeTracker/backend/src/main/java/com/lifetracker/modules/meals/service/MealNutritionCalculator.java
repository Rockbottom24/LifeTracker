package com.lifetracker.modules.meals.service;

import com.lifetracker.modules.foods.enums.ServingUnit;
import com.lifetracker.modules.foods.model.FoodConversionContext;
import com.lifetracker.modules.meals.exception.NutritionCalculationException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Objects;

/**
 * Authoritative nutrition scaling for meal logging.
 *
 * <p>Every nutrient uses one scale factor derived from the food's nutrition basis
 * and optional piece/household conversion metadata.
 */
public final class MealNutritionCalculator {
    static final int CALCULATION_SCALE = 10;
    static final int OUTPUT_SCALE = 2;
    private static final BigDecimal THOUSAND = new BigDecimal("1000");
    private static final BigDecimal THREE = new BigDecimal("3");
    private static final RoundingMode ROUNDING = RoundingMode.HALF_UP;

    private MealNutritionCalculator() {
    }

    public static BigDecimal calculate(
            BigDecimal nutrientPerReferenceServing,
            BigDecimal quantity,
            ServingUnit unit,
            FoodConversionContext context
    ) {
        if (nutrientPerReferenceServing == null) {
            return BigDecimal.ZERO.setScale(OUTPUT_SCALE, ROUNDING);
        }
        BigDecimal factor = resolveScaleFactor(quantity, unit, context);
        return nutrientPerReferenceServing.multiply(factor).setScale(OUTPUT_SCALE, ROUNDING);
    }

    /** Backward-compatible overload without household/piece metadata. */
    public static BigDecimal calculate(
            BigDecimal nutrientPerReferenceServing,
            BigDecimal quantity,
            ServingUnit unit,
            ServingUnit referenceUnit,
            BigDecimal referenceQuantity,
            BigDecimal referenceWeight
    ) {
        return calculate(
                nutrientPerReferenceServing,
                quantity,
                unit,
                FoodConversionContext.of(referenceUnit, referenceQuantity, referenceWeight, null, null, null, null)
        );
    }

    public static NutritionValues calculateAll(
            NutritionValues perReferenceServing,
            BigDecimal quantity,
            ServingUnit unit,
            FoodConversionContext context
    ) {
        BigDecimal factor = resolveScaleFactor(quantity, unit, context);
        return new NutritionValues(
                scale(perReferenceServing.calories(), factor),
                scale(perReferenceServing.protein(), factor),
                scale(perReferenceServing.carbs(), factor),
                scale(perReferenceServing.fat(), factor),
                scale(perReferenceServing.fiber(), factor)
        );
    }

    public static NutritionValues calculateAll(
            NutritionValues perReferenceServing,
            BigDecimal quantity,
            ServingUnit unit,
            ServingUnit referenceUnit,
            BigDecimal referenceQuantity,
            BigDecimal referenceWeight
    ) {
        return calculateAll(
                perReferenceServing,
                quantity,
                unit,
                FoodConversionContext.of(referenceUnit, referenceQuantity, referenceWeight, null, null, null, null)
        );
    }

    public static BigDecimal resolveScaleFactor(
            BigDecimal quantity,
            ServingUnit unit,
            FoodConversionContext context
    ) {
        Objects.requireNonNull(unit, "quantity unit is required");
        Objects.requireNonNull(context, "food conversion context is required");
        validateFoodConfiguration(context);

        if (quantity == null || quantity.signum() <= 0) {
            throw new NutritionCalculationException("Quantity must be greater than zero");
        }

        ServingUnit referenceUnit = context.servingUnit();
        BigDecimal referenceQuantity = context.referenceQuantity();
        BigDecimal referenceWeight = context.referenceWeight();

        if (unit == referenceUnit) {
            return quantity.divide(referenceQuantity, CALCULATION_SCALE, ROUNDING);
        }

        if (isMassUnit(unit)) {
            return toGrams(quantity, unit).divide(referenceWeight, CALCULATION_SCALE, ROUNDING);
        }

        if (isVolumeUnit(unit) && isVolumeUnit(referenceUnit)) {
            BigDecimal consumedMl = toMilliliters(quantity, unit);
            BigDecimal referenceMl = toMilliliters(referenceQuantity, referenceUnit);
            return consumedMl.divide(referenceMl, CALCULATION_SCALE, ROUNDING);
        }

        // Piece/count via grams-per-piece against mass nutrition basis.
        if (unit == ServingUnit.PIECE && context.hasPieceConversion()) {
            BigDecimal gramsPerPiece = context.resolvedGramsPerPiece();
            BigDecimal consumedGrams = quantity.multiply(gramsPerPiece);
            return consumedGrams.divide(referenceWeight, CALCULATION_SCALE, ROUNDING);
        }

        // Household label conversions (e.g. 2 tbsp = 32 g).
        BigDecimal householdGrams = resolveHouseholdGrams(quantity, unit, context);
        if (householdGrams != null) {
            return householdGrams.divide(referenceWeight, CALCULATION_SCALE, ROUNDING);
        }

        // tbsp <-> tsp when food reference itself is tbsp/tsp.
        if (isTbspTspPair(unit, referenceUnit)) {
            BigDecimal asReferenceUnit = convertTbspTsp(quantity, unit, referenceUnit);
            return asReferenceUnit.divide(referenceQuantity, CALCULATION_SCALE, ROUNDING);
        }

        if (isVolumeUnit(unit) && isMassUnit(referenceUnit)) {
            throw new NutritionCalculationException(
                    "Cannot convert volume unit " + unit + " to mass-based nutrition without density metadata"
            );
        }

        if (unit == ServingUnit.PIECE) {
            throw new NutritionCalculationException(
                    "This food does not have enough serving information to calculate pieces. "
                            + "Use grams or define grams per piece."
            );
        }

        if (unit == ServingUnit.TABLESPOON || unit == ServingUnit.TEASPOON || unit == ServingUnit.SERVING) {
            throw new NutritionCalculationException(
                    "This food does not have enough serving information to calculate "
                            + unit.name().toLowerCase()
                            + ". Use grams or define a serving conversion."
            );
        }

        throw new NutritionCalculationException(
                "Incompatible quantity unit " + unit + " for food serving unit " + referenceUnit
        );
    }

    public static BigDecimal resolveScaleFactor(
            BigDecimal quantity,
            ServingUnit unit,
            ServingUnit referenceUnit,
            BigDecimal referenceQuantity,
            BigDecimal referenceWeight
    ) {
        return resolveScaleFactor(
                quantity,
                unit,
                FoodConversionContext.of(referenceUnit, referenceQuantity, referenceWeight, null, null, null, null)
        );
    }

    public static void validateFoodConfiguration(FoodConversionContext context) {
        if (context.servingUnit() == null) {
            throw new NutritionCalculationException("Food serving unit is required");
        }
        if (context.referenceQuantity() == null || context.referenceQuantity().signum() <= 0) {
            throw new NutritionCalculationException("Food reference quantity must be greater than zero");
        }
        if (context.referenceWeight() == null || context.referenceWeight().signum() <= 0) {
            throw new NutritionCalculationException(
                    "Food reference weight (grams per reference serving) must be greater than zero"
            );
        }
        if (context.gramsPerPiece() != null && context.gramsPerPiece().signum() <= 0) {
            throw new NutritionCalculationException("Grams per piece must be greater than zero when provided");
        }
        if (context.householdUnit() != null
                || context.householdQuantity() != null
                || context.householdGrams() != null) {
            if (!context.hasHouseholdConversion()) {
                throw new NutritionCalculationException(
                        "Household serving conversion requires unit, positive quantity, and positive grams"
                );
            }
        }
    }

    public static void validateFoodConfiguration(
            ServingUnit referenceUnit,
            BigDecimal referenceQuantity,
            BigDecimal referenceWeight
    ) {
        validateFoodConfiguration(
                FoodConversionContext.of(referenceUnit, referenceQuantity, referenceWeight, null, null, null, null)
        );
    }

    private static BigDecimal resolveHouseholdGrams(
            BigDecimal quantity,
            ServingUnit unit,
            FoodConversionContext context
    ) {
        if (!context.hasHouseholdConversion()) {
            // SERVING without household metadata but reference is discrete serving-like unit.
            if (unit == ServingUnit.SERVING && isDiscreteUnit(context.servingUnit())) {
                return quantity.multiply(
                        context.referenceWeight().divide(context.referenceQuantity(), CALCULATION_SCALE, ROUNDING)
                );
            }
            return null;
        }

        BigDecimal gramsPerHouseholdUnit = context.householdGrams()
                .divide(context.householdQuantity(), CALCULATION_SCALE, ROUNDING);

        if (unit == ServingUnit.SERVING) {
            // One serving equals the full household label amount.
            return quantity.multiply(context.householdGrams());
        }

        if (unit == context.householdUnit()) {
            return quantity.multiply(gramsPerHouseholdUnit);
        }

        if (isTbspTspPair(unit, context.householdUnit())) {
            BigDecimal asHouseholdUnit = convertTbspTsp(quantity, unit, context.householdUnit());
            return asHouseholdUnit.multiply(gramsPerHouseholdUnit);
        }

        return null;
    }

    private static boolean isTbspTspPair(ServingUnit a, ServingUnit b) {
        return (a == ServingUnit.TABLESPOON && b == ServingUnit.TEASPOON)
                || (a == ServingUnit.TEASPOON && b == ServingUnit.TABLESPOON);
    }

    private static BigDecimal convertTbspTsp(BigDecimal quantity, ServingUnit from, ServingUnit to) {
        if (from == to) {
            return quantity;
        }
        if (from == ServingUnit.TABLESPOON && to == ServingUnit.TEASPOON) {
            return quantity.multiply(THREE);
        }
        if (from == ServingUnit.TEASPOON && to == ServingUnit.TABLESPOON) {
            return quantity.divide(THREE, CALCULATION_SCALE, ROUNDING);
        }
        throw new NutritionCalculationException("Cannot convert " + from + " to " + to);
    }

    public static BigDecimal toGrams(BigDecimal quantity, ServingUnit unit) {
        return switch (unit) {
            case GRAM -> quantity;
            case KILOGRAM -> quantity.multiply(THOUSAND);
            default -> throw new NutritionCalculationException("Unit " + unit + " is not a mass unit");
        };
    }

    public static BigDecimal toMilliliters(BigDecimal quantity, ServingUnit unit) {
        return switch (unit) {
            case ML -> quantity;
            case LITER -> quantity.multiply(THOUSAND);
            default -> throw new NutritionCalculationException("Unit " + unit + " is not a volume unit");
        };
    }

    public static boolean isMassUnit(ServingUnit unit) {
        return unit == ServingUnit.GRAM || unit == ServingUnit.KILOGRAM;
    }

    public static boolean isVolumeUnit(ServingUnit unit) {
        return unit == ServingUnit.ML || unit == ServingUnit.LITER;
    }

    public static boolean isDiscreteUnit(ServingUnit unit) {
        return unit == ServingUnit.PIECE
                || unit == ServingUnit.SCOOP
                || unit == ServingUnit.TABLESPOON
                || unit == ServingUnit.TEASPOON
                || unit == ServingUnit.CUP
                || unit == ServingUnit.SERVING;
    }

    private static BigDecimal scale(BigDecimal nutrient, BigDecimal factor) {
        if (nutrient == null) {
            return BigDecimal.ZERO.setScale(OUTPUT_SCALE, ROUNDING);
        }
        return nutrient.multiply(factor).setScale(OUTPUT_SCALE, ROUNDING);
    }

    public record NutritionValues(
            BigDecimal calories,
            BigDecimal protein,
            BigDecimal carbs,
            BigDecimal fat,
            BigDecimal fiber
    ) {
        public static NutritionValues of(
                BigDecimal calories,
                BigDecimal protein,
                BigDecimal carbs,
                BigDecimal fat,
                BigDecimal fiber
        ) {
            return new NutritionValues(calories, protein, carbs, fat, fiber);
        }
    }
}
