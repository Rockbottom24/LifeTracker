package com.lifetracker.modules.foods.model;

import com.lifetracker.modules.foods.enums.ServingUnit;

final class MealUnitFamilies {
    private MealUnitFamilies() {
    }

    static boolean isMass(ServingUnit unit) {
        return unit == ServingUnit.GRAM || unit == ServingUnit.KILOGRAM;
    }

    static boolean isVolume(ServingUnit unit) {
        return unit == ServingUnit.ML || unit == ServingUnit.LITER;
    }
}
