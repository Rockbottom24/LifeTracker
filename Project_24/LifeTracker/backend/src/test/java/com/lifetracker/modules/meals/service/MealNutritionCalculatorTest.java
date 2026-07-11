package com.lifetracker.modules.meals.service;

import com.lifetracker.modules.foods.enums.ServingUnit;
import com.lifetracker.modules.meals.exception.NutritionCalculationException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;
import java.math.RoundingMode;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class MealNutritionCalculatorTest {

    private static final BigDecimal CHICKEN_CALORIES = bd("165");
    private static final BigDecimal CHICKEN_PROTEIN = bd("31");
    private static final BigDecimal CHICKEN_CARBS = bd("0");
    private static final BigDecimal CHICKEN_FAT = bd("3.6");
    private static final BigDecimal CHICKEN_FIBER = bd("0");

    @Test
    void per100gFoodConsumedAs100g() {
        MealNutritionCalculator.NutritionValues result = calculateChicken(bd("100"), ServingUnit.GRAM);
        assertNutrition(result, "165.00", "31.00", "0.00", "3.60", "0.00");
    }

    @Test
    void per100gFoodConsumedAs50g() {
        MealNutritionCalculator.NutritionValues result = calculateChicken(bd("50"), ServingUnit.GRAM);
        assertNutrition(result, "82.50", "15.50", "0.00", "1.80", "0.00");
    }

    @Test
    void per100gFoodConsumedAs250g() {
        MealNutritionCalculator.NutritionValues result = calculateChicken(bd("250"), ServingUnit.GRAM);
        assertNutrition(result, "412.50", "77.50", "0.00", "9.00", "0.00");
    }

    @Test
    void kilogramToGramConversion() {
        MealNutritionCalculator.NutritionValues result = calculateChicken(bd("0.5"), ServingUnit.KILOGRAM);
        assertNutrition(result, "825.00", "155.00", "0.00", "18.00", "0.00");
    }

    @Test
    void perPieceFoodWithKnownGramsPerPiece() {
        // Banana: 1 piece = 118 g, 105 kcal per piece
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("105", "1.3", "27", "0.4", "3.1"),
                bd("1"),
                ServingUnit.PIECE,
                ServingUnit.PIECE,
                bd("1"),
                bd("118")
        );
        assertNutrition(result, "105.00", "1.30", "27.00", "0.40", "3.10");
    }

    @Test
    void multiplePiecesScaleLinearly() {
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("105", "1.3", "27", "0.4", "3.1"),
                bd("3"),
                ServingUnit.PIECE,
                ServingUnit.PIECE,
                bd("1"),
                bd("118")
        );
        assertNutrition(result, "315.00", "3.90", "81.00", "1.20", "9.30");
    }

    @Test
    void decimalPieceQuantityIsSupported() {
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("72", "6.3", "0.4", "4.8", "0"),
                bd("0.5"),
                ServingUnit.PIECE,
                ServingUnit.PIECE,
                bd("1"),
                bd("50")
        );
        assertNutrition(result, "36.00", "3.15", "0.20", "2.40", "0.00");
    }

    @Test
    void pieceLoggedAsGramsUsesReferenceWeight() {
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("105", "1.3", "27", "0.4", "3.1"),
                bd("118"),
                ServingUnit.GRAM,
                ServingUnit.PIECE,
                bd("1"),
                bd("118")
        );
        assertNutrition(result, "105.00", "1.30", "27.00", "0.40", "3.10");
    }

    @Test
    void perServingNutrition() {
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("120", "24", "3", "1", "0"),
                bd("1"),
                ServingUnit.SCOOP,
                ServingUnit.SCOOP,
                bd("1"),
                bd("30")
        );
        assertNutrition(result, "120.00", "24.00", "3.00", "1.00", "0.00");
    }

    @Test
    void multipleServings() {
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("120", "24", "3", "1", "0"),
                bd("2"),
                ServingUnit.SCOOP,
                ServingUnit.SCOOP,
                bd("1"),
                bd("30")
        );
        assertNutrition(result, "240.00", "48.00", "6.00", "2.00", "0.00");
    }

    @Test
    void decimalServings() {
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("120", "24", "3", "1", "0"),
                bd("2.5"),
                ServingUnit.SCOOP,
                ServingUnit.SCOOP,
                bd("1"),
                bd("30")
        );
        assertNutrition(result, "300.00", "60.00", "7.50", "2.50", "0.00");
    }

    @Test
    void servingDefinedPer100gWithKnownServingGrams() {
        // Nutrition per 100 g; 1 serving = 40 g; consume 2.5 servings
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("165", "31", "0", "3.6", "0"),
                bd("2.5"),
                ServingUnit.SCOOP,
                ServingUnit.SCOOP,
                bd("1"),
                bd("40")
        );
        // factor = 2.5 / 1 = 2.5 when unit matches serving unit (macros are per scoop of 40g)
        assertNutrition(result, "412.50", "77.50", "0.00", "9.00", "0.00");
    }

    @Test
    void per100MlNutrition() {
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("42", "3.4", "5", "1", "0"),
                bd("100"),
                ServingUnit.ML,
                ServingUnit.ML,
                bd("100"),
                bd("100")
        );
        assertNutrition(result, "42.00", "3.40", "5.00", "1.00", "0.00");
    }

    @Test
    void literToMilliliterConversion() {
        MealNutritionCalculator.NutritionValues result = MealNutritionCalculator.calculateAll(
                values("149", "7.7", "12", "8", "0"),
                bd("1"),
                ServingUnit.LITER,
                ServingUnit.ML,
                bd("250"),
                bd("250")
        );
        // 1000 ml / 250 ml = 4
        assertNutrition(result, "596.00", "30.80", "48.00", "32.00", "0.00");
    }

    @Test
    void allMacrosUseSameFactor() {
        BigDecimal factor = MealNutritionCalculator.resolveScaleFactor(
                bd("150"), ServingUnit.GRAM, ServingUnit.GRAM, bd("100"), bd("100")
        );
        assertEquals(0, bd("1.5").compareTo(factor));

        MealNutritionCalculator.NutritionValues result = calculateChicken(bd("150"), ServingUnit.GRAM);
        assertEquals(0, CHICKEN_CALORIES.multiply(factor).setScale(2, RoundingMode.HALF_UP).compareTo(result.calories()));
        assertEquals(0, CHICKEN_PROTEIN.multiply(factor).setScale(2, RoundingMode.HALF_UP).compareTo(result.protein()));
        assertEquals(0, CHICKEN_CARBS.multiply(factor).setScale(2, RoundingMode.HALF_UP).compareTo(result.carbs()));
        assertEquals(0, CHICKEN_FAT.multiply(factor).setScale(2, RoundingMode.HALF_UP).compareTo(result.fat()));
        assertEquals(0, CHICKEN_FIBER.multiply(factor).setScale(2, RoundingMode.HALF_UP).compareTo(result.fiber()));
    }

    @Test
    void mealTotalEqualsSumOfItems() {
        MealNutritionCalculator.NutritionValues item1 = calculateChicken(bd("100"), ServingUnit.GRAM);
        MealNutritionCalculator.NutritionValues item2 = MealNutritionCalculator.calculateAll(
                values("105", "1.3", "27", "0.4", "3.1"),
                bd("1"),
                ServingUnit.PIECE,
                ServingUnit.PIECE,
                bd("1"),
                bd("118")
        );

        BigDecimal totalCalories = item1.calories().add(item2.calories());
        BigDecimal totalProtein = item1.protein().add(item2.protein());
        assertEquals(bd("270.00"), totalCalories);
        assertEquals(bd("32.30"), totalProtein);
    }

    @Test
    void updatingQuantityRecalculatesTotals() {
        MealNutritionCalculator.NutritionValues before = calculateChicken(bd("100"), ServingUnit.GRAM);
        MealNutritionCalculator.NutritionValues after = calculateChicken(bd("200"), ServingUnit.GRAM);
        assertEquals(bd("165.00"), before.calories());
        assertEquals(bd("330.00"), after.calories());
    }

    @Test
    void invalidPieceConfigurationIsRejected() {
        assertThrows(NutritionCalculationException.class, () ->
                MealNutritionCalculator.resolveScaleFactor(
                        bd("1"), ServingUnit.PIECE, ServingUnit.PIECE, bd("1"), bd("0")
                )
        );
    }

    @Test
    void invalidServingConfigurationIsRejected() {
        assertThrows(NutritionCalculationException.class, () ->
                MealNutritionCalculator.resolveScaleFactor(
                        bd("1"), ServingUnit.SCOOP, ServingUnit.SCOOP, bd("0"), bd("30")
                )
        );
    }

    @Test
    void pieceOnMassFoodWithoutConversionIsRejected() {
        assertThrows(NutritionCalculationException.class, () ->
                MealNutritionCalculator.resolveScaleFactor(
                        bd("1"), ServingUnit.PIECE, ServingUnit.GRAM, bd("100"), bd("100")
                )
        );
    }

    @Test
    void volumeOnMassFoodWithoutDensityIsRejected() {
        assertThrows(NutritionCalculationException.class, () ->
                MealNutritionCalculator.resolveScaleFactor(
                        bd("100"), ServingUnit.ML, ServingUnit.GRAM, bd("100"), bd("100")
                )
        );
    }

    @Test
    void noIntegerTruncationForFractionalMacros() {
        BigDecimal result = MealNutritionCalculator.calculate(
                bd("31"),
                bd("33"),
                ServingUnit.GRAM,
                ServingUnit.GRAM,
                bd("100"),
                bd("100")
        );
        assertEquals(bd("10.23"), result);
    }

    @Test
    void roundingUsesHalfUpAtOutputOnly() {
        BigDecimal result = MealNutritionCalculator.calculate(
                bd("1"),
                bd("1"),
                ServingUnit.GRAM,
                ServingUnit.GRAM,
                bd("3"),
                bd("3")
        );
        assertEquals(bd("0.33"), result);
    }

    @ParameterizedTest
    @CsvSource({
            "100, GRAM, 165.00",
            "50, GRAM, 82.50",
            "250, GRAM, 412.50",
            "0.1, KILOGRAM, 165.00"
    })
    void parameterizedChickenScaling(String quantity, ServingUnit unit, String expectedCalories) {
        MealNutritionCalculator.NutritionValues result = calculateChicken(bd(quantity), unit);
        assertEquals(bd(expectedCalories), result.calories());
    }

    private static MealNutritionCalculator.NutritionValues calculateChicken(BigDecimal quantity, ServingUnit unit) {
        return MealNutritionCalculator.calculateAll(
                new MealNutritionCalculator.NutritionValues(
                        CHICKEN_CALORIES, CHICKEN_PROTEIN, CHICKEN_CARBS, CHICKEN_FAT, CHICKEN_FIBER
                ),
                quantity,
                unit,
                ServingUnit.GRAM,
                bd("100"),
                bd("100")
        );
    }

    private static MealNutritionCalculator.NutritionValues values(
            String calories, String protein, String carbs, String fat, String fiber
    ) {
        return MealNutritionCalculator.NutritionValues.of(
                bd(calories), bd(protein), bd(carbs), bd(fat), bd(fiber)
        );
    }

    private static void assertNutrition(
            MealNutritionCalculator.NutritionValues actual,
            String calories,
            String protein,
            String carbs,
            String fat,
            String fiber
    ) {
        assertEquals(bd(calories), actual.calories());
        assertEquals(bd(protein), actual.protein());
        assertEquals(bd(carbs), actual.carbs());
        assertEquals(bd(fat), actual.fat());
        assertEquals(bd(fiber), actual.fiber());
    }

    private static BigDecimal bd(String value) {
        return new BigDecimal(value);
    }
}
