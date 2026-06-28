package com.lifetracker.modules.learning.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record CompleteLearningRequest(
        @NotNull @Min(0) Integer completedMinutes
) {
}
