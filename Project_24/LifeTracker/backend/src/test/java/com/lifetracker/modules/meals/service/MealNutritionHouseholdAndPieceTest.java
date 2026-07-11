package com.lifetracker.modules.meals.service;

import com.lifetracker.modules.foods.enums.ServingUnit;
import com.lifetracker.modules.foods.model.FoodConversionContext;
import com.lifetracker.modules.meals.exception.NutritionCalculationException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class MealNutritionHouseholdAndPieceTest {

    @Test
    void tenAlmondsUsingPieceQuantity() {
        FoodConversionContext almonds = FoodConversionContext.of(
                ServingUnit.GRAM, bd("100"), bd("100"), bd("1.2"), null, null, null
        );
        var result = MealNutritionCalculator.calculateAll(
                values("579", "21", "22", "50", "12"),
                bd("10"),
                ServingUnit.PIECE,
                almonds
        );
        // 12 g / 100 g = 0.12
        assertEquals(bd("69.48"), result.calories());
        assertEquals(bd("2.52"), result.protein());
    }

    @Test
    void fifteenCashewsUsingPieceQuantity() {
        FoodConversionContext cashews = FoodConversionContext.of(
                ServingUnit.GRAM, bd("100"), bd("100"), bd("1.6"), null, null, null
        );
        var result = MealNutritionCalculator.calculateAll(
                values("553", "18", "30", "44", "3.3"),
                bd("15"),
                ServingUnit.PIECE,
                cashews
        );
        // 24 g / 100 = 0.24
        assertEquals(bd("132.72"), result.calories());
        assertEquals(bd("4.32"), result.protein());
    }

    @Test
    void twoEggsUsingPieceQuantity() {
        FoodConversionContext egg = FoodConversionContext.of(
                ServingUnit.PIECE, bd("1"), bd("50"), bd("50"), null, null, null
        );
        var result = MealNutritionCalculator.calculateAll(
                values("72", "6.3", "0.4", "4.8", "0"),
                bd("2"),
                ServingUnit.PIECE,
                egg
        );
        assertEquals(bd("144.00"), result.calories());
        assertEquals(bd("12.60"), result.protein());
    }

    @Test
    void peanutButterTwoTbspServingMetadataOneTbsp() {
        FoodConversionContext pb = peanutButter();
        var one = MealNutritionCalculator.calculateAll(values("588", "25", "20", "50", "6"), bd("1"), ServingUnit.TABLESPOON, pb);
        // 16g / 100 = 0.16
        assertEquals(bd("94.08"), one.calories());
        assertEquals(bd("4.00"), one.protein());
    }

    @Test
    void peanutButterThreeTbsp() {
        FoodConversionContext pb = peanutButter();
        var three = MealNutritionCalculator.calculateAll(values("588", "25", "20", "50", "6"), bd("3"), ServingUnit.TABLESPOON, pb);
        // 48g / 100 = 0.48
        assertEquals(bd("282.24"), three.calories());
        assertEquals(bd("12.00"), three.protein());
    }

    @Test
    void peanutButterOneTeaspoonFromTbspMetadata() {
        FoodConversionContext pb = peanutButter();
        var tsp = MealNutritionCalculator.calculateAll(values("588", "25", "20", "50", "6"), bd("1"), ServingUnit.TEASPOON, pb);
        // 16/3 g / 100
        assertEquals(bd("31.36"), tsp.calories());
    }

    @Test
    void peanutButterOneServingEqualsTwoTbsp() {
        FoodConversionContext pb = peanutButter();
        var serving = MealNutritionCalculator.calculateAll(values("588", "25", "20", "50", "6"), bd("1"), ServingUnit.SERVING, pb);
        // 32g / 100
        assertEquals(bd("188.16"), serving.calories());
    }

    @Test
    void unsupportedTablespoonReturnsValidationErrorNotZero() {
        FoodConversionContext massOnly = FoodConversionContext.of(
                ServingUnit.GRAM, bd("100"), bd("100"), null, null, null, null
        );
        NutritionCalculationException ex = assertThrows(
                NutritionCalculationException.class,
                () -> MealNutritionCalculator.resolveScaleFactor(bd("1"), ServingUnit.TABLESPOON, massOnly)
        );
        assertTrue(ex.getMessage().toLowerCase().contains("tablespoon")
                || ex.getMessage().toLowerCase().contains("serving information"));
    }

    @Test
    void supportedUnitsIncludePieceWhenGramsPerPiecePresent() {
        FoodConversionContext almonds = FoodConversionContext.of(
                ServingUnit.GRAM, bd("100"), bd("100"), bd("1.2"), null, null, null
        );
        assertTrue(almonds.supportedUnits().contains(ServingUnit.PIECE));
        assertTrue(almonds.supportedUnits().contains(ServingUnit.GRAM));
    }

    @Test
    void supportedUnitsIncludeTbspWhenHouseholdPresent() {
        assertTrue(peanutButter().supportedUnits().contains(ServingUnit.TABLESPOON));
        assertTrue(peanutButter().supportedUnits().contains(ServingUnit.TEASPOON));
        assertTrue(peanutButter().supportedUnits().contains(ServingUnit.SERVING));
    }

    private static FoodConversionContext peanutButter() {
        return FoodConversionContext.of(
                ServingUnit.GRAM,
                bd("100"),
                bd("100"),
                null,
                ServingUnit.TABLESPOON,
                bd("2"),
                bd("32")
        );
    }

    private static MealNutritionCalculator.NutritionValues values(
            String calories, String protein, String carbs, String fat, String fiber
    ) {
        return MealNutritionCalculator.NutritionValues.of(bd(calories), bd(protein), bd(carbs), bd(fat), bd(fiber));
    }

    private static BigDecimal bd(String value) {
        return new BigDecimal(value);
    }
}
