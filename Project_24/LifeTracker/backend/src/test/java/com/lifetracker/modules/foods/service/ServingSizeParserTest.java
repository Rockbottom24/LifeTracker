package com.lifetracker.modules.foods.service;

import com.lifetracker.modules.foods.enums.ServingUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ServingSizeParserTest {

    @ParameterizedTest
    @CsvSource({
            "'2 tbsp (32 g)', TABLESPOON, 2, 32",
            "'1 tbsp (16g)', TABLESPOON, 1, 16",
            "'1 tsp (5 g)', TEASPOON, 1, 5",
            "'1 piece (50 g)', PIECE, 1, 50",
            "'2 pieces (40 g)', PIECE, 2, 40",
            "'1 serving (30 g)', SERVING, 1, 30",
            "'1 scoop (25 g)', SCOOP, 1, 25"
    })
    void parsesHouseholdWithGrams(String raw, ServingUnit unit, String quantity, String grams) {
        var parsed = ServingSizeParser.parse(raw);
        assertTrue(parsed.isPresent());
        assertEquals(unit, parsed.get().unit());
        assertEquals(0, new BigDecimal(quantity).compareTo(parsed.get().quantity()));
        assertEquals(0, new BigDecimal(grams).compareTo(parsed.get().grams()));
    }

    @Test
    void parsesPlainGrams() {
        var parsed = ServingSizeParser.parse("30 g");
        assertTrue(parsed.isPresent());
        assertEquals(ServingUnit.GRAM, parsed.get().unit());
        assertEquals(0, new BigDecimal("30").compareTo(parsed.get().quantity()));
    }

    @Test
    void rejectsAmbiguousText() {
        assertTrue(ServingSizeParser.parse("about a handful").isEmpty());
    }

    @Test
    void mergesHouseholdTextWithNumericServingGrams() {
        var parsed = ServingSizeParser.parse("2 tbsp", 32.0, "g");
        assertTrue(parsed.isPresent());
        assertEquals(ServingUnit.TABLESPOON, parsed.get().unit());
        assertEquals(0, new BigDecimal("2").compareTo(parsed.get().quantity()));
        assertEquals(0, new BigDecimal("32").compareTo(parsed.get().grams()));
    }

    @Test
    void householdWithoutGramsIsRejected() {
        assertTrue(ServingSizeParser.parse("2 tbsp").isEmpty());
    }
}
