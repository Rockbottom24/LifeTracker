package com.lifetracker.modules.foods.service;

import com.lifetracker.modules.foods.enums.ServingUnit;

import java.math.BigDecimal;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Parses common Open Food Facts / label serving-size strings into structured conversions.
 *
 * <p>Examples accepted:
 * <ul>
 *   <li>2 tbsp (32 g)</li>
 *   <li>1 tbsp (16g)</li>
 *   <li>1 tsp (5 g)</li>
 *   <li>1 piece (50 g)</li>
 *   <li>2 pieces (40 g)</li>
 *   <li>1 serving (30 g)</li>
 *   <li>1 scoop (25 g)</li>
 *   <li>30 g</li>
 *   <li>100 ml</li>
 * </ul>
 */
public final class ServingSizeParser {
    private static final Pattern HOUSEHOLD_WITH_GRAMS = Pattern.compile(
            "^\\s*(\\d+(?:[.,]\\d+)?)\\s*([a-zA-Z]+)\\s*[\\(（]\\s*(\\d+(?:[.,]\\d+)?)\\s*(g|gram|grams)\\s*[\\)）]\\s*$",
            Pattern.CASE_INSENSITIVE
    );
    private static final Pattern PLAIN_MASS_OR_VOLUME = Pattern.compile(
            "^\\s*(\\d+(?:[.,]\\d+)?)\\s*(g|gram|grams|kg|kilogram|kilograms|ml|milliliter|milliliters|l|liter|liters)\\s*$",
            Pattern.CASE_INSENSITIVE
    );
    private static final Pattern HOUSEHOLD_ONLY = Pattern.compile(
            "^\\s*(\\d+(?:[.,]\\d+)?)\\s*([a-zA-Z]+)\\s*$",
            Pattern.CASE_INSENSITIVE
    );

    private ServingSizeParser() {
    }

    public static Optional<ParsedServingSize> parse(String raw) {
        return parse(raw, null, null);
    }

    /**
     * Parses serving text and optionally merges Open Food Facts numeric serving fields.
     * When text is "2 tbsp" and serving_quantity is 32 with unit g, returns 2 tbsp = 32 g.
     */
    public static Optional<ParsedServingSize> parse(
            String raw,
            Double servingQuantity,
            String servingQuantityUnit
    ) {
        if (raw == null || raw.isBlank()) {
            return fromNumericServing(servingQuantity, servingQuantityUnit, null);
        }
        String normalized = raw.trim().replace('\u00A0', ' ');

        Matcher household = HOUSEHOLD_WITH_GRAMS.matcher(normalized);
        if (household.matches()) {
            BigDecimal quantity = parseDecimal(household.group(1));
            ServingUnit unit = mapUnit(household.group(2));
            BigDecimal grams = parseDecimal(household.group(3));
            if (quantity == null || unit == null || grams == null || quantity.signum() <= 0 || grams.signum() <= 0) {
                return Optional.empty();
            }
            return Optional.of(new ParsedServingSize(unit, quantity, grams, raw.trim()));
        }

        Matcher plain = PLAIN_MASS_OR_VOLUME.matcher(normalized);
        if (plain.matches()) {
            BigDecimal quantity = parseDecimal(plain.group(1));
            ServingUnit unit = mapUnit(plain.group(2));
            if (quantity == null || unit == null || quantity.signum() <= 0) {
                return Optional.empty();
            }
            BigDecimal gramsEquivalent = switch (unit) {
                case GRAM -> quantity;
                case KILOGRAM -> quantity.multiply(new BigDecimal("1000"));
                case ML, LITER -> null; // volume-only; no invented density
                default -> null;
            };
            if (unit == ServingUnit.ML || unit == ServingUnit.LITER) {
                return Optional.of(new ParsedServingSize(unit, quantity, null, raw.trim()));
            }
            if (gramsEquivalent == null) {
                return Optional.empty();
            }
            return Optional.of(new ParsedServingSize(unit, quantity, gramsEquivalent, raw.trim()));
        }

        Matcher householdOnly = HOUSEHOLD_ONLY.matcher(normalized);
        if (householdOnly.matches()) {
            BigDecimal quantity = parseDecimal(householdOnly.group(1));
            ServingUnit unit = mapUnit(householdOnly.group(2));
            if (quantity == null || unit == null || quantity.signum() <= 0 || !isHousehold(unit)) {
                return Optional.empty();
            }
            Optional<ParsedServingSize> withGrams = fromNumericServing(servingQuantity, servingQuantityUnit, raw.trim());
            if (withGrams.isPresent() && withGrams.get().hasGramConversion()
                    && (withGrams.get().unit() == ServingUnit.GRAM || withGrams.get().unit() == ServingUnit.KILOGRAM)) {
                BigDecimal grams = withGrams.get().unit() == ServingUnit.KILOGRAM
                        ? withGrams.get().quantity().multiply(new BigDecimal("1000"))
                        : withGrams.get().grams() != null ? withGrams.get().grams() : withGrams.get().quantity();
                return Optional.of(new ParsedServingSize(unit, quantity, grams, raw.trim()));
            }
            // Household unit without grams — do not invent a conversion.
            return Optional.empty();
        }

        return Optional.empty();
    }

    private static Optional<ParsedServingSize> fromNumericServing(
            Double servingQuantity,
            String servingQuantityUnit,
            String rawText
    ) {
        if (servingQuantity == null || servingQuantity <= 0 || servingQuantityUnit == null || servingQuantityUnit.isBlank()) {
            return Optional.empty();
        }
        ServingUnit unit = mapUnit(servingQuantityUnit);
        if (unit == null) {
            return Optional.empty();
        }
        BigDecimal quantity = BigDecimal.valueOf(servingQuantity);
        BigDecimal grams = switch (unit) {
            case GRAM -> quantity;
            case KILOGRAM -> quantity.multiply(new BigDecimal("1000"));
            default -> null;
        };
        if (unit == ServingUnit.GRAM || unit == ServingUnit.KILOGRAM) {
            return Optional.of(new ParsedServingSize(ServingUnit.GRAM, grams, grams, rawText));
        }
        if (isHousehold(unit) && grams == null) {
            return Optional.empty();
        }
        return Optional.of(new ParsedServingSize(unit, quantity, grams, rawText));
    }

    private static boolean isHousehold(ServingUnit unit) {
        return unit == ServingUnit.TABLESPOON
                || unit == ServingUnit.TEASPOON
                || unit == ServingUnit.PIECE
                || unit == ServingUnit.SERVING
                || unit == ServingUnit.SCOOP
                || unit == ServingUnit.CUP;
    }

    private static BigDecimal parseDecimal(String value) {
        if (value == null) {
            return null;
        }
        try {
            return new BigDecimal(value.trim().replace(',', '.'));
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private static ServingUnit mapUnit(String rawUnit) {
        if (rawUnit == null) {
            return null;
        }
        String key = rawUnit.trim().toLowerCase(Locale.ENGLISH);
        return switch (key) {
            case "g", "gram", "grams" -> ServingUnit.GRAM;
            case "kg", "kilogram", "kilograms" -> ServingUnit.KILOGRAM;
            case "ml", "milliliter", "milliliters", "millilitre", "millilitres" -> ServingUnit.ML;
            case "l", "liter", "liters", "litre", "litres" -> ServingUnit.LITER;
            case "tbsp", "tbs", "tablespoon", "tablespoons" -> ServingUnit.TABLESPOON;
            case "tsp", "teaspoon", "teaspoons" -> ServingUnit.TEASPOON;
            case "piece", "pieces", "count", "pc", "pcs" -> ServingUnit.PIECE;
            case "serving", "servings" -> ServingUnit.SERVING;
            case "scoop", "scoops" -> ServingUnit.SCOOP;
            case "cup", "cups" -> ServingUnit.CUP;
            default -> null;
        };
    }

    public record ParsedServingSize(
            ServingUnit unit,
            BigDecimal quantity,
            BigDecimal grams,
            String rawText
    ) {
        public boolean hasGramConversion() {
            return grams != null && grams.signum() > 0;
        }

        public boolean isHouseholdUnit() {
            return unit == ServingUnit.TABLESPOON
                    || unit == ServingUnit.TEASPOON
                    || unit == ServingUnit.PIECE
                    || unit == ServingUnit.SERVING
                    || unit == ServingUnit.SCOOP
                    || unit == ServingUnit.CUP;
        }
    }
}
