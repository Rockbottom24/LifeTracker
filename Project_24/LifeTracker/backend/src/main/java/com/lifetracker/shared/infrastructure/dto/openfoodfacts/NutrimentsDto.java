package com.lifetracker.shared.infrastructure.dto.openfoodfacts;

import com.fasterxml.jackson.annotation.JsonProperty;

public record NutrimentsDto(

        @JsonProperty("energy-kcal_100g")
        Double calories,

        @JsonProperty("proteins_100g")
        Double protein,

        @JsonProperty("carbohydrates_100g")
        Double carbs,

        @JsonProperty("fat_100g")
        Double fat,

        @JsonProperty("fiber_100g")
        Double fiber

) {}