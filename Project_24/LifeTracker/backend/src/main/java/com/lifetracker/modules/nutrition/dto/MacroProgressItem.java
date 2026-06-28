package com.lifetracker.modules.nutrition.dto;

import java.math.BigDecimal;

public record MacroProgressItem(
        String key,
        String label,
        BigDecimal consumed,
        BigDecimal goal,
        BigDecimal remaining,
        double progressPercent
) {
}
