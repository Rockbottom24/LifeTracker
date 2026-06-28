package com.lifetracker.shared.infrastructure.dto.openfoodfacts;

public record OpenFoodFactsResponse(

        String code,

        ProductDto product

) {}