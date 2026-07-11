package com.lifetracker.modules.foods.model;

import com.lifetracker.modules.foods.enums.ServingUnit;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Conversion metadata used by nutrition scaling and supported-unit resolution.
 */
public record FoodConversionContext(
        ServingUnit servingUnit,
        BigDecimal referenceQuantity,
        BigDecimal referenceWeight,
        BigDecimal gramsPerPiece,
        ServingUnit householdUnit,
        BigDecimal householdQuantity,
        BigDecimal householdGrams
) {
    public static FoodConversionContext of(
            ServingUnit servingUnit,
            BigDecimal referenceQuantity,
            BigDecimal referenceWeight,
            BigDecimal gramsPerPiece,
            ServingUnit householdUnit,
            BigDecimal householdQuantity,
            BigDecimal householdGrams
    ) {
        return new FoodConversionContext(
                servingUnit,
                referenceQuantity,
                referenceWeight,
                gramsPerPiece,
                householdUnit,
                householdQuantity,
                householdGrams
        );
    }

    public boolean hasPieceConversion() {
        if (gramsPerPiece != null && gramsPerPiece.signum() > 0) {
            return true;
        }
        return servingUnit == ServingUnit.PIECE
                && referenceQuantity != null
                && referenceQuantity.signum() > 0
                && referenceWeight != null
                && referenceWeight.signum() > 0;
    }

    public BigDecimal resolvedGramsPerPiece() {
        if (gramsPerPiece != null && gramsPerPiece.signum() > 0) {
            return gramsPerPiece;
        }
        if (servingUnit == ServingUnit.PIECE
                && referenceQuantity != null
                && referenceQuantity.signum() > 0
                && referenceWeight != null
                && referenceWeight.signum() > 0) {
            return referenceWeight.divide(referenceQuantity, 10, java.math.RoundingMode.HALF_UP);
        }
        return null;
    }

    public boolean hasHouseholdConversion() {
        return householdUnit != null
                && householdQuantity != null
                && householdQuantity.signum() > 0
                && householdGrams != null
                && householdGrams.signum() > 0;
    }

    public List<ServingUnit> supportedUnits() {
        Set<ServingUnit> units = new LinkedHashSet<>();
        if (servingUnit != null) {
            units.add(servingUnit);
        }
        if (MealUnitFamilies.isMass(servingUnit) || referenceWeight != null) {
            units.add(ServingUnit.GRAM);
            units.add(ServingUnit.KILOGRAM);
        }
        if (MealUnitFamilies.isVolume(servingUnit)) {
            units.add(ServingUnit.ML);
            units.add(ServingUnit.LITER);
        }
        if (hasPieceConversion()) {
            units.add(ServingUnit.PIECE);
        }
        if (hasHouseholdConversion()) {
            units.add(householdUnit);
            units.add(ServingUnit.SERVING);
            if (householdUnit == ServingUnit.TABLESPOON) {
                units.add(ServingUnit.TEASPOON);
            } else if (householdUnit == ServingUnit.TEASPOON) {
                units.add(ServingUnit.TABLESPOON);
            }
        }
        if (servingUnit == ServingUnit.TABLESPOON) {
            units.add(ServingUnit.TEASPOON);
        } else if (servingUnit == ServingUnit.TEASPOON) {
            units.add(ServingUnit.TABLESPOON);
        }
        if (servingUnit == ServingUnit.SERVING || hasHouseholdConversion()) {
            units.add(ServingUnit.SERVING);
        }
        return new ArrayList<>(units);
    }
}
